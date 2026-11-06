# Provisioning prompts: Change Order Management

Paste each prompt into Copilot in SharePoint on your site, in a fresh chat, in order. They create the lists, libraries and columns the three skills expect, with the same names, types and choices as the demo site, for three projects and four change orders. No PowerShell, no app registration.

The skills find lists by URL and columns by internal name, so the names matter. Lists are created under a one-word name first and renamed afterwards: a rename keeps the URL (`/Lists/RiversideCorporateOffice`), and that URL is what the skills' `site.md` holds. If a list, library or column already exists, Copilot should leave it as it is rather than add a second one.

Where a prompt says `YOUR-SITE-URL`, replace it with your site's address before pasting, for example `https://contoso.sharepoint.com/sites/ZavaBuilders`.

## Prompt A: lists, libraries and columns

> On this site, create the lists and document libraries below with exactly these columns, types and choices. Create each one under the short name given first, then rename it to the display name in brackets, so the URL keeps the short name. If a list, library or column with that name already exists, leave it as it is and do not create a duplicate. Do not add any other columns. When done, list each list and library with its URL, its columns and their types.
>
> **Three lists with identical columns**: `RiversideCorporateOffice` (rename to **Riverside Corporate Office**), `HarborLogisticsCenter` (rename to **Harbor Logistics Center**) and `ElmStreetClinic` (rename to **Elm Street Clinic**). Columns on each:
> - Row Kind: choice, one value, from: Original, Current, Change
> - Phase No: number, no decimals
> - Phase Name: single line of text
> - Depends On: number, no decimals
> - Vendor: choice, one value, from: Contoso Concrete, Northwind Structures, Tailspin Mechanical, Wingtip Interiors, Litware Workplace
> - Phase Manager: single line of text
> - Start: single line of text
> - End: single line of text
> - Cost: currency
> - Phase Status: choice, one value, from: Not Started, In Progress, Complete
> - Change Order No: single line of text
> - Description: multiple lines of plain text
> - Schedule Delta Days: number, no decimals
> - Cost Delta: currency
> - Kind: choice, one value, from: Direct, Shifted
> - Old Start: single line of text
> - New Start: single line of text
> - Old End: single line of text
> - New End: single line of text
> - New Cost: currency
> - Applied: choice, one value, from: No, Yes
> - Applied On: single line of text
> - Sort the default view by Row Kind, then Phase No, smallest first, and show every column.
>
> **List `Projects`** (keep the name **Projects**):
> - Project ID: single line of text
> - Project Name: single line of text
> - Site Address: single line of text
> - Project List: hyperlink
> - Project Manager: single line of text
> - Original Total: currency
> - Current Total: currency
> - Original Completion: single line of text
> - Current Completion: single line of text
> - Contract: hyperlink
>
> **List `ProjectTeam`** (rename to **Project Team**):
> - Company: single line of text
> - Role: single line of text
> - Email: single line of text
> - Cc On Every Notice: choice, one value, from: No, Yes
>
> **Document library `ChangeOrders`** (rename to **Change Orders**):
> - Change Order No: single line of text
> - Project ID: single line of text
> - Vendor: choice, one value, from: Contoso Concrete, Northwind Structures, Tailspin Mechanical, Wingtip Interiors, Litware Workplace
> - Accepted On: single line of text
> - Status: choice, one value, from: Accepted, Running, Assessed, Reviewed, Sent; default Accepted
> - Change Title: single line of text
> - Days Added: number, no decimals, negative values allowed
> - Cost Added: currency, negative values allowed
> - Notices Sent: single line of text
>
> **Document library `Contracts`** (keep the name **Contracts**):
> - Project ID: single line of text
> - Document Type: choice, one value, from: Contract, Addendum, Template
> - Change Order No: single line of text
>
> **Document library `EmailTemplates`** (rename to **Email Templates**): no extra columns.
>
> **Document library `Dashboards`** (keep the name **Dashboards**): no extra columns.

Check: the URLs end in `/Lists/RiversideCorporateOffice`, `/Lists/HarborLogisticsCenter`, `/Lists/ElmStreetClinic`, `/Lists/Projects`, `/Lists/ProjectTeam`, `/ChangeOrders`, `/Contracts`, `/EmailTemplates` and `/Dashboards`.

## Prompt B: the phase rows, the projects and the contract labels

Run after uploading the four CSVs in `sample-files/Lists/` to the Documents library and the files in `sample-files/Contracts/` to Contracts.

> Read ZB-2026-014.csv, ZB-2026-017.csv and ZB-2026-021.csv in the Documents library. ZB-2026-014.csv holds the rows for the list Riverside Corporate Office, ZB-2026-017.csv for Harbor Logistics Center, ZB-2026-021.csv for Elm Street Clinic. For every row of each file, create one item in that list, setting Title, Row Kind, Phase No, Phase Name, Depends On, Vendor, Phase Manager, Start, End, Cost and Phase Status from the columns of the same name; leave a column empty where the cell is empty. Start and End are text, keep them exactly as written (2026-06-01). Expect 12 items on Riverside Corporate Office, 14 on Harbor Logistics Center and 10 on Elm Street Clinic, half Original and half Current. Then tell me how many items each list holds, grouped by Row Kind.
>
> Then read projects.csv in the Documents library and create one item in the Projects list per row: Title and Project ID from ProjectID; Project Name, Site Address, Project Manager, Original Total, Current Total, Original Completion and Current Completion from the columns of the same name; Project List as the hyperlink YOUR-SITE-URL/Lists/ followed by the project name with the spaces removed (for example YOUR-SITE-URL/Lists/RiversideCorporateOffice) with the project name as its description; Contract as the hyperlink YOUR-SITE-URL/Contracts/ followed by the ContractFile value, with the file name as its description. Expect 3 items.
>
> Then set the columns on the files in the Contracts library: on each file whose name starts with a project ID (ZB-2026-014, ZB-2026-017, ZB-2026-021) set Project ID to that ID and Document Type to Contract; on addendum-template.html set Document Type to Template and leave Project ID empty.

Check: each project list shows its Original rows then its Current rows, in phase order. The Projects rows' links open the list and the contract.

## Prompt C: the people who get mail

The addresses in `project-team.csv` are fictional and will not deliver. Change at least one Email to an inbox you can check before running the notify step, and add yourself with Cc On Every Notice = Yes to receive a copy of every notice.

> Read project-team.csv in the Documents library and create one item in the Project Team list per row, with Title, Company, Role, Email and Cc On Every Notice from the columns of the same name. Then list every item in Project Team with its Email and Cc On Every Notice.

## Prompt D: the change orders and the column check

Run after uploading the four PDFs in `sample-files/Change Orders/` to Change Orders and the two files in `sample-files/Email Templates/` to Email Templates.

> On the files in the Change Orders library, set these columns and leave Change Title, Days Added, Cost Added and Notices Sent empty:
> - "CO-1041 Riverside Corporate Office - Contoso Concrete.pdf": Change Order No CO-1041, Project ID ZB-2026-014, Vendor Contoso Concrete, Accepted On 2026-10-26, Status Accepted
> - "CO-2007 Harbor Logistics Center - Northwind Structures.pdf": Change Order No CO-2007, Project ID ZB-2026-017, Vendor Northwind Structures, Accepted On 2026-10-27, Status Accepted
> - "CO-3002 Elm Street Clinic - Litware Workplace.pdf": Change Order No CO-3002, Project ID ZB-2026-021, Vendor Litware Workplace, Accepted On 2026-10-28, Status Accepted
> - "CO-4015 Northgate Distribution Hub - Contoso Concrete.pdf": Change Order No CO-4015, Project ID ZB-2026-019, Vendor Contoso Concrete, Accepted On 2026-10-28, Status Accepted
>
> Then list the internal names of every column on the Riverside Corporate Office, Harbor Logistics Center, Elm Street Clinic, Projects and Project Team lists and on the Change Orders and Contracts libraries.

Check: the internal names match the skills' `site.md` (`RowKind`, `PhaseNo`, `DependsOn`, `PhaseManager`, `PhaseStatus`, `ProjectID`, `ChangeOrderNo`, `ScheduleDeltaDays`, `CostDelta`, `OldStart`, `NewStart`, `OldEnd`, `NewEnd`, `NewCost`, `AppliedOn`, `ProjectName`, `ProjectList`, `OriginalTotal`, `CurrentTotal`, `OriginalCompletion`, `CurrentCompletion`, `CcOnEveryNotice`, `AcceptedOn`, `ChangeTitle`, `DaysAdded`, `CostAdded`, `NoticesSent`, `DocumentType`), with no `_x0020_`. If one differs, ask Copilot to recreate the column under the internal name and then set its display name.

## Quick Steps

After the skills are uploaded (setup step 5). First add the column by hand: Change Orders › Add column › Quick Steps, name it `Actions`. Then, in that column's Quick Steps pane, one prompt per button:

> Add a quick step called "Assess Change Order" that asks Copilot in SharePoint to run the assess-change-order skill on this file, with the prompt: "Use the assess-change-order skill for the selected Change Orders row." Show it only when Status is Accepted.

> Add a quick step called "Confirm Change Impact" that asks Copilot in SharePoint to run the confirm-change-impact skill on this file, with the prompt: "Use the confirm-change-impact skill for the selected Change Orders row." Show it only when Status is Assessed.

> Add a quick step called "Notify Project Team" that asks Copilot in SharePoint to run the notify-project-team skill on this file, with the prompt: "Use the notify-project-team skill for the selected Change Orders row." Show it only when Status is Reviewed.

## Prompt E: the project dashboard

Upload `prompts/project-dashboard-prompt.md` to the Documents library in a folder named `Skill Build` first. The brief is too long for the chat box, so the prompt points at the file.

> Read the file "Skill Build/project-dashboard-prompt.md" in the Documents library now, in full, and build the page exactly as it describes. Save it to the Dashboards library as "project-dashboard.html", as HTML, not converted. Change no list data. Show me the page when it is done.

If a detail is wrong, say so in the same chat. If Copilot cannot change the page in place, delete the page and paste this prompt again in a fresh chat.

## Prompt F: the Schedule view on a project list (optional)

Upload `sample-files/Dashboards/schedule-view-template.html` to the Dashboards library in a folder named `Templates`. Open a project list in the browser, start a fresh chat, and paste:

> Read the file "Templates/schedule-view-template.html" in the Dashboards library now, in full; do not reuse an earlier copy. It is the schedule view template. Create a view named "Schedule" on this list whose HTML is that file exactly as written, changing only one value in the CONFIG block at the top of its script: title, set to this list's name. Keep every other line, including both manifest blocks, exactly as in the file; do not rewrite, shorten or restyle any of the code, and change nothing else on the list. If a view named "Schedule" already exists on this list, delete it and create it again rather than editing it. When done, print the view link, the number of characters its HTML holds, and whether any part of the file could not be kept.

Fresh chat for every list: a second run in the same chat reuses Copilot's first read of the file.

## Prompt G: reset between runs

> I want to put the change order demo back to its starting state. First show me the plan and wait for me to reply "Confirm reset" before changing anything. The plan: on the Riverside Corporate Office, Harbor Logistics Center and Elm Street Clinic lists, delete every row whose Row Kind is Change, and on every row whose Row Kind is Current set Start, End and Cost to the values of the Original row with the same Phase No. On the Projects list, set Current Total to Original Total and Current Completion to Original Completion on every row. In the Contracts library, delete every file whose Document Type is Addendum and every file whose name contains "Addendum" or "Cover", keeping the files whose Document Type is Contract or Template. In the Change Orders library, set Status to Accepted and clear Change Title, Days Added, Cost Added and Notices Sent on every file. After I confirm, do it and read back each list's row count by Row Kind and each change order's Status.
