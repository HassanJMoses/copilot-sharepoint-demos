# Setup: New Customer Packet on your own site

About fifteen minutes with the setup script, or thirty with the Copilot prompts.

You need: a SharePoint site where Copilot in SharePoint is available, a Microsoft 365 Copilot licence, and site owner rights.

## 1. Libraries, columns and files

### Option A: the setup script (recommended)

The script creates the five libraries and their columns, uploads every sample file with its column values set, puts the seals and the email template where the skills look for them, and uploads the three skills with your site address already filled in. It is safe to rerun.

You need PowerShell 7 and the PnP PowerShell module:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

From the `setup` folder, check the files and see the plan first, then run it:

```powershell
./Setup-NewCustomerPacket.ps1 -SiteUrl https://contoso.sharepoint.com/sites/Insurance -ValidateOnly
./Setup-NewCustomerPacket.ps1 -SiteUrl https://contoso.sharepoint.com/sites/Insurance
```

It signs in with a device code: it prints a code, you enter it at https://microsoft.com/devicelogin with an account that owns the site. No app registration, no pop-up window. If your tenant blocks that sign-in, pass `-ClientId` with an app registration of your own.

If the site has no **Agent Assets** library yet, the script says so and skips the skills. Ask Copilot in SharePoint on the site to create a skill (any skill; that creates Agent Assets and its Skills folder), delete it, and rerun the script with `-SkipApplications`.

Then go to step 2.

### Option B: Copilot prompts and drag and drop

Use this if you can't run PowerShell. It takes longer, and the column step has to be followed exactly.

**Why the column names matter.** The skills ask SharePoint for columns by their internal names: `BusinessName`, `DocumentType`, `TemplateState`, `PackageStatus` and so on. SharePoint sets a column's internal name once, from the name it was first given, and never changes it. A column created as "Document type" gets a different internal name, and the build skill won't find it. So the prompts have Copilot create each column under its internal name first and then rename it to the display name people see.

The prompts work from two CSV files in `setup/`, the same ones the script uses:

| File | What it holds |
|---|---|
| `libraries-and-columns.csv` | One row per column: library, internal name, display name, type, choices, default |
| `document-columns.csv` | One row per template and per layout, with its column values, headed by internal names |

1. Upload both CSV files to the root of the site's Documents library.
2. Paste **Prompt A** from [`prompts/provision-prompt.md`](prompts/provision-prompt.md). It creates the libraries and columns from `libraries-and-columns.csv`. Check the list it returns: every column should show the internal name in the CSV.
3. Drag and drop the sample files:

   | From | To |
   |---|---|
   | `sample-files/New Customers/*.pdf` | New Customers |
   | `sample-files/Templates/*.docx` | Templates |
   | `sample-files/Template Layouts/*.html` | Template Layouts |
   | `sample-files/Template Layouts/Seals/*.png` | Template Layouts, in the `Seals` folder |
   | `sample-files/Email templates/customer-packet-email.md` | Documents, in the `Email templates` folder |

4. Paste **Prompt B**. It sets every template's and layout's columns from `document-columns.csv`. Check a few rows: a layout and its template should show the same values.
5. Point the skills at your site. Open `skills/new-customer-packet/new-customer-packet/SKILL.md` and `skills/review-customer-packet/review-customer-packet/SKILL.md` and replace every occurrence of `https://YOUR-TENANT.sharepoint.com/sites/YOUR-SITE` with your site's address. Nothing else in the skills is site-specific: the seal addresses are resolved at the start of each run.
6. Open the site's **Agent Assets** library (if there is none, ask Copilot in SharePoint to create it). Inside `Skills`, upload the three inner folders: `skills/<name>/<name>/`, each with its `SKILL.md` and, for the build and review skills, its `references` folder. The folder name must match the `name` in each `SKILL.md`.

Leave `answer-key.xlsx` on your computer either way. It's for checking results, and if it's on the site Copilot can read it.

## 2. Check the skills

Paste **Prompt C**, or type `/` in the Copilot pane: all three skills should appear, and the build and review skills should each list `references/packet-manifest.md` and `references/template-fields.md`.

## 3. Test each skill from the chat

Before adding any buttons, run each skill once from the Copilot pane so you know it works on your site:

1. In New Customers, select `Zava Cafe - Application.pdf` and type `Use the new-customer-packet skill on this selected application.` (Florida, 11 documents, a quick first run.) Watch Packages fill, then Completed Packets. The row ends at Package ready with the documents listed.
2. In Completed Packets, select the new packet and type `Use the review-customer-packet skill for this selected packet.` Read the table, then reply `Confirm packet ready`.
3. Change the Contact email on that row to an inbox you can check, select it and type `Use the send-customer-packet skill for the selected packet.` Check the preview and reply `Confirm to send`.

## 4. Add the buttons

Once the skills work, give them buttons. Quick Steps are a column type: add a **Quick Steps** column to New Customers and one to Completed Packets (Add column, Quick Steps). Then ask Copilot in SharePoint to attach each skill to a quick step on that column, shown only when the row's status says the step is next:

| Library | Button | Show when | Skill it runs |
|---|---|---|---|
| New Customers | Build package | Package status is `New` or `Needs information` | new-customer-packet |
| Completed Packets | Review packet | Packet status is `Packet Complete` | review-customer-packet |
| Completed Packets | Send to customer | Packet status is `Customer Ready` | send-customer-packet |

For example, on Completed Packets: *"Add a quick step to the Actions column called Send to customer. Show it only when Packet status is Customer Ready. It should run the send-customer-packet skill on the selected packet, show the draft for confirmation, and send only after I explicitly confirm."*

The statuses are what move a row from one button to the next: the build sets Package ready, the review sets Customer Ready, the send sets Customer Sent. The button on a row acts on that row. From the command bar it acts on every selected row at once, which these skills don't expect, so press the row's button.

## 5. Run it with the buttons

1. In New Customers, press **Build package** on `Zava Roofing - Application.pdf` (Texas and Louisiana, six vehicles, 31 documents). Watch Packages fill, then Completed Packets.
2. In Completed Packets, press **Review packet** on the new packet. Read the table, then reply `Confirm packet ready`.
3. Change the Contact email on that row to an inbox you can check, then press **Send to customer**. Check the preview and reply `Confirm to send`.

Then press **Build package** on `Zava Landscaping - Application.pdf`, which stops with Needs information because the employee count is missing. Compare each run with `answer-key.xlsx`.

## If something doesn't match

- **"Columns not found" or a packet built from file names.** The columns don't have the internal names the skills use (`DocumentType`, `Scope`, `TemplateState`, `CoverageTrigger`, `BusinessTypeTrigger`, `PacketOrder`, `FormNumber`, `PackageStatus`, `PacketStatus` and the rest). An internal name can't be changed after a column is created: delete the column and create it again with the setup script or Prompt A.
- **A seal is missing or wrong.** The `Seals` folder must sit in Template Layouts and hold `tx_seal.png`, `fl_seal.png`, `la_seal.png`. The skill lists that folder at the start of each run.
- **The skill stalls before writing anything.** Stop it and press again in a fresh chat. If it happens repeatedly on one account after a lot of runs, try another account; SharePoint applies per-user request limits that slow Copilot down without a message.
- **Send says there is no email tool.** Send email from Copilot in SharePoint is rolling out from October 2026. Until it reaches your tenant, the send skill stops at the preview.
- **External email addresses.** Sharing with an outside address depends on your tenant's sharing settings. Use an internal inbox for the test.

## Clearing the site between runs

Delete the customer's folder in Packages and its file in Completed Packets. Then set the application row's Package status back to New with the other columns blank, or rerun the setup script with `-SkipSkills`, which re-uploads every application and resets its row. The sample files are unchanged by a run.
