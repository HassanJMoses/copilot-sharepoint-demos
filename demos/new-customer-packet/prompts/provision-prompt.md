# Provisioning prompts: New Customer Packet on a new site

Option B in setup.md: for a site where you can't run the setup script. The prompts read the same two CSV files the script uses, so both routes build the same site:

- `setup/libraries-and-columns.csv`: one row per column. Library, internal name, display name, type, choices (separated by semicolons), default, and notes.
- `setup/document-columns.csv`: one row per template and per layout, with its column values. The header row uses internal names.

Upload both CSV files to the root of the site's **Documents** library first. Then paste each prompt into Copilot in SharePoint, in order.

**The rule the prompts follow.** The skills find columns by their internal names (`BusinessName`, `DocumentType`, `TemplateState`, `PackageStatus` and so on). SharePoint fixes a column's internal name from the name the column is first created with, and never changes it. So every column is created under its internal name first, then renamed to its display name. A column created straight away as "Document type" gets a different internal name, and the build skill won't find it.

## Prompt A: libraries and columns

> Read libraries-and-columns.csv in the Documents library. For each Library in the file, create a document library with that name if it does not exist. For each row with an InternalName, add a column to that library:
> 1. Create the column with the name in InternalName, exactly, with no spaces. Then rename it to DisplayName. Never create it under the display name: the internal name must stay as InternalName.
> 2. Use the Type: Text is single line of text; Note is multiple lines of plain text; Choice is a choice column with one value; MultiChoice is a choice column with multiple values allowed; Number is a number with no decimals, minimum 0; Date is date only; URL is a hyperlink.
> 3. For Choice and MultiChoice, the choices are in Choices, separated by semicolons, in that order. Allow no fill-in values.
> 4. If Default has a value, set it as the column's default.
> 5. Follow any instruction in Notes.
> 6. If a column with that internal name already exists in the library, leave it as it is.
> Do not add any column that is not in the file. Then create a folder called "Seals" in Template Layouts, and a folder called "Email templates" in the Documents library. When done, list each library with each column's display name, internal name and type.

Check: 13 columns on New Customers, 7 on Templates, 3 on Template Layouts, none on Packages and 9 on Completed Packets, with the defaults New, Ready for approval and Packet Complete, and every internal name exactly as in the CSV. If an internal name differs (for example `Document_x0020_type` or `State`), delete that column and ask Copilot to create it again under the internal name.

Optional: the Packet status pill. Open the Packet status column's formatting (Column settings, Format this column, Advanced mode) and paste the contents of `setup/packet-status-formatter.json`.

## Prompt B: column values for the templates and layouts

Run after uploading the 32 Word templates to **Templates** and the 32 HTML layouts to **Template Layouts**.

> Read document-columns.csv in the Documents library. Its header row holds internal column names. For each row, find the file named FileName in the library named in Library, and set its columns from the row: Title, DocumentType, Scope, TemplateState, and for Templates also CoverageTrigger, BusinessTypeTrigger, PacketOrder and FormNumber. CoverageTrigger and BusinessTypeTrigger may hold several choices separated by semicolons; set all of them. Leave a column empty where the cell is empty. Tell me any row whose file you could not find, and any file in either library that has no row.

Check: 64 rows matched (32 per library), nothing reported missing. Spot-check one State template (State = TX, Scope = State), a Proof of Insurance Card (Coverage trigger = Commercial vehicles), and its layout (same Document type, Scope and State).

## Prompt C: check the skills are installed

Run after uploading the three skill folders to **Agent Assets › Skills**.

> List the skills available on this site with their descriptions, and list every file in each skill's folder in Agent Assets.

Check: new-customer-packet and review-customer-packet each with references/packet-manifest.md and references/template-fields.md; send-customer-packet with its SKILL.md.
