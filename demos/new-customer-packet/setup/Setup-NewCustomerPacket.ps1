<#
.SYNOPSIS
  Sets up the New Customer Packet demo on an existing SharePoint site: five libraries with
  their columns and views, the sample files with their column values, the email template,
  and the three skills.

.DESCRIPTION
  Safe to rerun: libraries and columns are only created when missing, and files are
  overwritten in place. Re-uploading an application resets its row to New with the
  skill-filled columns blank, so a rerun also clears the site between demo runs.

  Libraries and columns come from libraries-and-columns.csv and file column values from
  document-columns.csv, the same files the Copilot prompts in prompts/ read.

  Columns are created with fixed internal names (BusinessName, DocumentType, TemplateState,
  PackageStatus, ...). The skills ask SharePoint for columns by these names, so the columns
  must be created this way, not by typing display names in the browser.

  The answer key is deliberately NOT uploaded: if it sat on the site, Copilot could read it
  and a test run would prove nothing.

  Needs PowerShell 7 and the PnP.PowerShell module (Install-Module PnP.PowerShell -Scope CurrentUser).
  Signs in with a device code: no app registration, no pop-up window.

.PARAMETER SiteUrl
  The site to set up, for example https://contoso.sharepoint.com/sites/Insurance.

.PARAMETER ClientId
  Optional. An Entra app registration to sign in with, if your tenant blocks the default
  SharePoint Online Management Shell client.

.PARAMETER ValidateOnly
  Check the local files and show the plan, without connecting to SharePoint.

.PARAMETER SkipApplications
  Set up everything except the 50 application PDFs, for example to upload them live on camera.

.PARAMETER SkipSkills
  Do not upload the skills to Agent Assets.

.PARAMETER NewSignIn
  Ignore the cached sign-in and ask for a new device code.

.EXAMPLE
  ./Setup-NewCustomerPacket.ps1 -SiteUrl https://contoso.sharepoint.com/sites/Insurance -ValidateOnly
  ./Setup-NewCustomerPacket.ps1 -SiteUrl https://contoso.sharepoint.com/sites/Insurance
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SiteUrl,
    [string]$ClientId,
    [switch]$ValidateOnly,
    [switch]$SkipApplications,
    [switch]$SkipSkills,
    [switch]$NewSignIn
)

$ErrorActionPreference = 'Stop'

$DemoDir     = Split-Path -Parent $PSScriptRoot
$Samples     = Join-Path $DemoDir 'sample-files'
$AppsDir     = Join-Path $Samples 'New Customers'
$TemplateDir = Join-Path $Samples 'Templates'
$LayoutDir   = Join-Path $Samples 'Template Layouts'
$SealDir     = Join-Path $LayoutDir 'Seals'
$EmailDir    = Join-Path $Samples 'Email templates'
$SkillsDir   = Join-Path $DemoDir 'skills'
$ColumnsCsv  = Join-Path $PSScriptRoot 'libraries-and-columns.csv'
$DocsCsv     = Join-Path $PSScriptRoot 'document-columns.csv'
$SiteUrl     = $SiteUrl.TrimEnd('/')

# The skills ship with this placeholder where the site address goes; it is replaced on upload.
$Placeholder = 'https://YOUR-TENANT.sharepoint.com/sites/YOUR-SITE'
$Skills = @('new-customer-packet', 'review-customer-packet', 'send-customer-packet')

# Libraries and columns come from libraries-and-columns.csv, the same file the Copilot prompt reads.
# InternalName is the name the skills use; DisplayName is what people see.
$Libraries = [ordered]@{}
foreach ($c in Import-Csv -Path $ColumnsCsv -Encoding UTF8) {
    if (-not $Libraries.Contains($c.Library)) { $Libraries[$c.Library] = @() }
    if (-not $c.InternalName) { continue }   # a library with no extra columns
    $Libraries[$c.Library] += @{
        Name = $c.InternalName; Display = $c.DisplayName; Type = $c.Type
        Choices = @(if ($c.Choices) { $c.Choices -split ';' }); Default = $c.Default; Formatter = $c.Formatter
    }
}
function Get-Choices($lib, $name) { ($Libraries[$lib] | Where-Object { $_.Name -eq $name }).Choices }

$ViewFields = @{
    'New Customers'     = @('DocIcon','LinkFilename','BusinessName','HomeState','OtherStates','TypeOfBusiness','Coverage',
                            'Employees','Vehicles','PackageStatus','PackageLink')
    'Templates'         = @('DocIcon','LinkFilename','Title','DocumentType','Scope','TemplateState','CoverageTrigger',
                            'BusinessTypeTrigger','PacketOrder','FormNumber')
    'Template Layouts'  = @('DocIcon','LinkFilename','Title','DocumentType','Scope','TemplateState')
    'Completed Packets' = @('DocIcon','LinkFilename','BusinessName','ContactName','ContactEmail','PolicyNumber',
                            'PolicyStartDate','HomeState','PacketStatus','Application')
}

function Write-Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }

function ConvertTo-XmlText([string]$s) { [System.Security.SecurityElement]::Escape($s) }

function New-FieldXml($f) {
    $name = $f.Name
    $display = ConvertTo-XmlText $f.Display
    $common = "Name=`"$name`" StaticName=`"$name`" DisplayName=`"$display`""
    switch ($f.Type) {
        'Text'   { return "<Field Type=`"Text`" $common MaxLength=`"255`" />" }
        'Note'   { return "<Field Type=`"Note`" $common NumLines=`"6`" RichText=`"FALSE`" />" }
        'Number' { return "<Field Type=`"Number`" $common Decimals=`"0`" Min=`"0`" />" }
        'Date'   { return "<Field Type=`"DateTime`" $common Format=`"DateOnly`" />" }
        'URL'    { return "<Field Type=`"URL`" $common Format=`"Hyperlink`" />" }
        { $_ -in 'Choice','MultiChoice' } {
            $choices = ($f.Choices | ForEach-Object { "<CHOICE>$(ConvertTo-XmlText $_)</CHOICE>" }) -join ''
            $default = ''
            if ($f.Default) { $default = "<Default>$(ConvertTo-XmlText $f.Default)</Default>" }
            $format = ''
            if ($f.Type -eq 'Choice') { $format = ' Format="Dropdown"' }
            return "<Field Type=`"$($f.Type)`" $common FillInChoice=`"FALSE`"$format>$default<CHOICES>$choices</CHOICES></Field>"
        }
    }
    throw "Unknown column type $($f.Type) for $name"
}

function Split-Multi([string]$value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return $null }
    return @($value -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

# ---------------------------------------------------------------------------
Write-Step 'Checking local files'

$problems = @()
if ($SiteUrl -notmatch '^https://[^/]+\.sharepoint\.com/sites/[^/]+$') {
    $problems += "SiteUrl should look like https://contoso.sharepoint.com/sites/Insurance, got $SiteUrl"
}
$apps      = @(Get-ChildItem -Path $AppsDir -Filter '*.pdf' -ErrorAction SilentlyContinue)
$templates = @(Get-ChildItem -Path $TemplateDir -Filter '*.docx' -ErrorAction SilentlyContinue)
$layouts   = @(Get-ChildItem -Path $LayoutDir -Filter '*.html' -ErrorAction SilentlyContinue)
$seals     = @(Get-ChildItem -Path $SealDir -Filter '*.png' -ErrorAction SilentlyContinue)
$emails    = @(Get-ChildItem -Path $EmailDir -Filter '*.md' -ErrorAction SilentlyContinue)
$docRows   = @(Import-Csv -Path $DocsCsv -Encoding UTF8)
$rows      = @($docRows | Where-Object Library -eq 'Templates')
$layoutRows = @($docRows | Where-Object Library -eq 'Template Layouts')

if ($apps.Count -ne 50)               { $problems += "Expected 50 application PDFs in $AppsDir, found $($apps.Count)." }
if ($templates.Count -ne $rows.Count) { $problems += "Expected $($rows.Count) templates (one per Templates row of document-columns.csv) in $TemplateDir, found $($templates.Count)." }
if ($layouts.Count -ne $layoutRows.Count) { $problems += "Expected $($layoutRows.Count) layouts (one per Template Layouts row of document-columns.csv) in $LayoutDir, found $($layouts.Count)." }
foreach ($s in 'tx_seal.png','fl_seal.png','la_seal.png') {
    if (-not (Test-Path (Join-Path $SealDir $s))) { $problems += "Missing seal $s in $SealDir" }
}
if (-not $emails.Count) { $problems += "No email template in $EmailDir" }
foreach ($sk in $Skills) {
    if (-not (Test-Path (Join-Path $SkillsDir "$sk/$sk/SKILL.md"))) { $problems += "Missing skills/$sk/$sk/SKILL.md" }
}

$templateNames = $templates | ForEach-Object { $_.Name }
$layoutNames   = $layouts | ForEach-Object { $_.Name }
foreach ($r in $docRows) {
    $names = if ($r.Library -eq 'Templates') { $templateNames } else { $layoutNames }
    if ($names -notcontains $r.FileName) { $problems += "$($r.Library) row has no matching file: $($r.FileName)" }
    if ((Get-Choices $r.Library 'DocumentType') -notcontains $r.DocumentType) { $problems += "Unknown document type '$($r.DocumentType)' for $($r.FileName)" }
    if ($r.TemplateState -and (Get-Choices $r.Library 'TemplateState') -notcontains $r.TemplateState) { $problems += "Unknown state '$($r.TemplateState)' for $($r.FileName)" }
    foreach ($c in (Split-Multi $r.CoverageTrigger)) { if ((Get-Choices 'Templates' 'CoverageTrigger') -notcontains $c) { $problems += "Unknown coverage '$c' for $($r.FileName)" } }
    foreach ($b in (Split-Multi $r.BusinessTypeTrigger)) { if ((Get-Choices 'Templates' 'BusinessTypeTrigger') -notcontains $b) { $problems += "Unknown business type '$b' for $($r.FileName)" } }
}
foreach ($lib in $Libraries.Keys) {
    foreach ($f in $Libraries[$lib]) { [xml](New-FieldXml $f) | Out-Null }
}

if ($problems.Count) {
    $problems | ForEach-Object { Write-Host "  PROBLEM: $_" -ForegroundColor Red }
    throw "$($problems.Count) problem(s). Nothing was changed."
}
Write-Host "  $($apps.Count) applications, $($templates.Count) templates, $($layouts.Count) layouts, $($seals.Count) seals, $($docRows.Count) document rows: all match."

Write-Step 'Plan'
Write-Host "  Site: $SiteUrl"
foreach ($lib in $Libraries.Keys) {
    $cols = ($Libraries[$lib] | ForEach-Object { "$($_.Display) ($($_.Name))" }) -join ', '
    if (-not $cols) { $cols = 'no extra columns' }
    Write-Host "  Library '$lib': $cols"
}
Write-Host '  Templates and Template Layouts: upload with columns set from document-columns.csv; seals into Template Layouts/Seals.'
if ($SkipApplications) { Write-Host '  Applications: skipped.' }
else                   { Write-Host '  Applications: upload 50 PDFs to New Customers, Package status = New.' }
Write-Host '  Email template: Documents/Email templates.'
if ($SkipSkills) { Write-Host '  Skills: skipped.' }
else             { Write-Host "  Skills: $($Skills -join ', ') into Agent Assets/Skills, with the site address set to $SiteUrl." }
Write-Host '  Not uploaded: answer-key.xlsx (stays on your computer so Copilot cannot read it).'

if ($ValidateOnly) { Write-Host "`nValidate only: nothing was changed." -ForegroundColor Green; return }

# ---------------------------------------------------------------------------
Write-Step "Connecting to $SiteUrl"
. (Join-Path $PSScriptRoot 'Connect-Site.ps1')
$web = Connect-Site -SiteUrl $SiteUrl -ClientId $ClientId -NewSignIn:$NewSignIn
Write-Host "  Connected: $($web.Title)"

function Get-LibraryFolder($title) {
    $l = Get-PnPList -Identity $title
    $root = (Get-PnPProperty -ClientObject $l -Property RootFolder).ServerRelativeUrl
    $webUrl = $web.ServerRelativeUrl.TrimEnd('/')
    return $root.Substring($webUrl.Length).TrimStart('/')
}

Write-Step 'Libraries and columns'
$Folders = @{}
foreach ($lib in $Libraries.Keys) {
    $list = Get-PnPList -Identity $lib -ErrorAction SilentlyContinue
    if (-not $list) {
        $list = New-PnPList -Title $lib -Url ($lib -replace ' ', '') -Template DocumentLibrary -OnQuickLaunch
        Write-Host "  Created library '$lib'"
    } else {
        Write-Host "  Library '$lib' already exists"
    }
    $existing = @(Get-PnPField -List $lib | ForEach-Object { $_.InternalName })
    foreach ($f in $Libraries[$lib]) {
        if ($existing -contains $f.Name) { Write-Host "    = $($f.Display)"; continue }
        Add-PnPFieldFromXml -List $lib -FieldXml (New-FieldXml $f) | Out-Null
        Write-Host "    + $($f.Display)"
        if ($f.Formatter) {
            $json = Get-Content (Join-Path $PSScriptRoot $f.Formatter) -Raw
            Set-PnPField -List $lib -Identity $f.Name -Values @{ CustomFormatter = $json } | Out-Null
        }
    }
    if ($ViewFields.Contains($lib)) {
        $view = Get-PnPView -List $lib | Where-Object { $_.DefaultView } | Select-Object -First 1
        # Keep the view as people arranged it (including any Quick Steps column); only append missing columns.
        $null = Get-PnPProperty -ClientObject $view -Property ViewFields
        $current = @($view.ViewFields | ForEach-Object { [string]$_ })
        $fields = @($current) + @($ViewFields[$lib] | Where-Object { $current -notcontains $_ })
        Set-PnPView -List $lib -Identity $view.Id -Fields $fields | Out-Null
        if ($lib -eq 'Templates') {
            Set-PnPView -List $lib -Identity $view.Id -Values @{ ViewQuery = '<OrderBy><FieldRef Name="PacketOrder" /></OrderBy>' } | Out-Null
        }
        Write-Host '    Default view updated'
    }
    $Folders[$lib] = Get-LibraryFolder $lib
}

# A file open in a browser or Word is locked; skip it, keep going, and report it at the end.
$Skipped = @()
function Send-File($path, $folder, $values) {
    try {
        if ($values -and $values.Count) { Add-PnPFile -Path $path -Folder $folder -Values $values -ErrorAction Stop | Out-Null }
        else                            { Add-PnPFile -Path $path -Folder $folder -ErrorAction Stop | Out-Null }
        Write-Host "  $(Split-Path $path -Leaf)"
    } catch {
        $script:Skipped += (Split-Path $path -Leaf)
        Write-Host "  SKIPPED (locked or failed): $(Split-Path $path -Leaf): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Step 'Templates and template layouts'
# Every column in document-columns.csv is an internal name; empty cells stay empty.
foreach ($r in $docRows) {
    $values = @{ Title = $r.Title; DocumentType = $r.DocumentType; Scope = $r.Scope }
    if ($r.TemplateState) { $values['TemplateState'] = $r.TemplateState }
    if ($r.Library -eq 'Templates') {
        $values['PacketOrder'] = [int]$r.PacketOrder
        $values['FormNumber']  = $r.FormNumber
        $cov = Split-Multi $r.CoverageTrigger
        if ($cov) { $values['CoverageTrigger'] = [string[]]$cov }
        $bt = Split-Multi $r.BusinessTypeTrigger
        if ($bt) { $values['BusinessTypeTrigger'] = [string[]]$bt }
        Send-File (Join-Path $TemplateDir $r.FileName) $Folders['Templates'] $values
    } else {
        Send-File (Join-Path $LayoutDir $r.FileName) $Folders['Template Layouts'] $values
    }
}

Write-Step 'Seals'
$sealFolder = "$($Folders['Template Layouts'])/Seals"
Resolve-PnPFolder -SiteRelativePath $sealFolder | Out-Null
foreach ($s in $seals) { Send-File $s.FullName $sealFolder $null }

if (-not $SkipApplications) {
    Write-Step 'Applications'
    # Uploading resets the row: Package status back to New and every column the skill fills cleared.
    $reset = @{ PackageStatus = 'New' }
    foreach ($f in $Libraries['New Customers']) { if ($f.Name -ne 'PackageStatus') { $reset[$f.Name] = $null } }
    foreach ($a in $apps) { Send-File $a.FullName $Folders['New Customers'] $reset }
}

Write-Step 'Email template'
$emailFolder = "$(Get-LibraryFolder 'Documents')/Email templates"
Resolve-PnPFolder -SiteRelativePath $emailFolder | Out-Null
foreach ($e in $emails) { Send-File $e.FullName $emailFolder $null }

if (-not $SkipSkills) {
    Write-Step 'Skills'
    $agentAssets = Get-PnPList -Identity 'Agent Assets' -ErrorAction SilentlyContinue
    if (-not $agentAssets) {
        Write-Host '  This site has no Agent Assets library yet. Open Copilot in SharePoint on the site and ask it to' -ForegroundColor Yellow
        Write-Host '  create a skill (any skill; it creates Agent Assets and its Skills folder), delete that skill,' -ForegroundColor Yellow
        Write-Host '  then rerun this script with -SkipApplications.' -ForegroundColor Yellow
    } else {
        $skillsFolder = "$(Get-LibraryFolder 'Agent Assets')/Skills"
        $staging = Join-Path ([IO.Path]::GetTempPath()) "new-customer-packet-skills-$([guid]::NewGuid().ToString('N'))"
        try {
            foreach ($sk in $Skills) {
                $src = Join-Path $SkillsDir "$sk/$sk"
                foreach ($file in Get-ChildItem -Path $src -Recurse -File) {
                    $rel = [IO.Path]::GetRelativePath($src, $file.FullName) -replace '\\', '/'
                    $dest = Join-Path $staging "$sk/$rel"
                    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
                    # The site address goes into the skills here, so nobody has to edit SKILL.md by hand.
                    (Get-Content $file.FullName -Raw).Replace($Placeholder, $SiteUrl) | Set-Content -Path $dest -NoNewline -Encoding utf8NoBOM
                    $folder = "$skillsFolder/$sk"
                    $sub = Split-Path $rel -Parent
                    if ($sub) { $folder = "$folder/$sub" }
                    Resolve-PnPFolder -SiteRelativePath $folder | Out-Null
                    Send-File $dest $folder $null
                }
            }
        } finally {
            Remove-Item -Recurse -Force $staging -ErrorAction SilentlyContinue
        }
    }
}

Write-Step 'Check'
$counts = [ordered]@{
    'New Customers'    = @(Get-PnPListItem -List 'New Customers' -PageSize 500 | Where-Object { $_.FileSystemObjectType -eq 'File' }).Count
    'Templates'        = @(Get-PnPListItem -List 'Templates' -PageSize 500 | Where-Object { $_['FileLeafRef'] -like '*.docx' }).Count
    'Template Layouts' = @(Get-PnPListItem -List 'Template Layouts' -PageSize 500 | Where-Object { $_['FileLeafRef'] -like '*.html' }).Count
    'Seals'            = @(Get-PnPFolderItem -FolderSiteRelativeUrl $sealFolder -ItemType File).Count
}
foreach ($k in $counts.Keys) { Write-Host "  ${k}: $($counts[$k])" }
if ($Skipped.Count) {
    Write-Host "  $($Skipped.Count) file(s) skipped. Close them in the browser or Word (or wait about 10 minutes for the lock to clear) and rerun." -ForegroundColor Yellow
}
Write-Host "`nDone. Next: setup.md, step 3 (check the skills appear in Copilot in SharePoint)." -ForegroundColor Green
