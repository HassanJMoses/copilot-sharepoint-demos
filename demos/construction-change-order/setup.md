# Setup: Change Order Management on your own site

Everything below is done in the browser with Copilot in SharePoint, plus drag-and-drop uploads. No PowerShell, no app registration. About forty-five minutes.

You need: a SharePoint site where Copilot in SharePoint is available, a Microsoft 365 Copilot licence, and site owner rights. The prompts are in [`prompts/provision-prompt.md`](prompts/provision-prompt.md); paste each one into a fresh Copilot chat on the site, in order.

## 1. Lists, libraries and columns

Paste **Prompt A**. It creates the three project lists, Projects, Project Team, and the Change Orders, Contracts, Email Templates and Dashboards libraries, with exactly the columns and choices the skills expect.

The skills find lists by URL and columns by internal name, so the names matter. Each list is created under a short name and renamed afterwards, so the URL keeps the short name (`/Lists/RiversideCorporateOffice`). Check the URLs Copilot prints end in:

```
/Lists/RiversideCorporateOffice   /Lists/HarborLogisticsCenter   /Lists/ElmStreetClinic
/Lists/Projects   /Lists/ProjectTeam
/ChangeOrders   /Contracts   /EmailTemplates   /Dashboards
```

If one differs, delete that list and create it again under the short name, or edit the Addresses table in each skill's `references/site.md` before step 5.

## 2. Upload the sample files

Drag and drop:

| From | To |
|---|---|
| `sample-files/Lists/*.csv` | the site's **Documents** library (root); the prompts read them from there |
| `sample-files/Contracts/*.pdf` and `addendum-template.html` | **Contracts** |
| `sample-files/Change Orders/*.pdf` | **Change Orders** |
| `sample-files/Email Templates/*.md` | **Email Templates** |

Leave `answer-key.md` and the `reference/` addenda on your computer. They are for checking results, and if they are on the site Copilot can read them.

## 3. Load the rows

Paste **Prompt B**. It reads the three list CSVs and creates the phase rows (12, 14 and 10: Original and Current for each phase), then the three Projects rows, then labels the contracts and the template in Contracts. Check each project list shows its Original rows then its Current rows, and that the Projects row's two links open the list and the contract.

Paste **Prompt C**. It creates the Project Team rows from `project-team.csv`. The addresses in the CSV are fictional and will not deliver. Before running the notify step, change at least one phase manager's Email to an inbox you can check, and add a row for yourself with Cc On Every Notice = Yes to receive a copy of every notice.

Paste **Prompt D**. It labels the four change orders (number, project, vendor, accepted on, Status `Accepted`) and prints the internal name of every column. Check them against the skills' `references/site.md`: `RowKind`, `PhaseNo`, `DependsOn`, `PhaseManager`, `ProjectID`, `ChangeOrderNo`, `DocumentType`, `CcOnEveryNotice`, `NoticesSent` and so on, with no `_x0020_` in any of them. A column Copilot creates as "Row Kind" sometimes gets the internal name `Row_x0020_Kind`; if so, ask Copilot to recreate it under the internal name and then set the display name.

## 4. Point the skills at your site

The skills name every list and library by full address, in `references/site.md`. Open each of the three copies and replace every occurrence of

```
https://YOUR-TENANT.sharepoint.com/sites/YOUR-SITE
```

with your site's address, for example `https://contoso.sharepoint.com/sites/ZavaBuilders`. Then do the same for the bare host, `https://YOUR-TENANT.sharepoint.com`, which `site.md` uses as the prefix for file reads. A find-and-replace across the three `site.md` files and `notify-project-team/SKILL.md` gets them all. Nothing else in the skills is site-specific.

## 5. Upload the skills

Open the site's **Agent Assets** library. If the site has none, ask Copilot in SharePoint to create it; it also creates the `Skills` folder. Inside `Skills`, upload the three inner folders:

```
Agent Assets/Skills/assess-change-order/SKILL.md
Agent Assets/Skills/assess-change-order/references/site.md
Agent Assets/Skills/assess-change-order/references/propagation.md
Agent Assets/Skills/confirm-change-impact/SKILL.md
Agent Assets/Skills/confirm-change-impact/references/site.md
Agent Assets/Skills/confirm-change-impact/references/addendum.md
Agent Assets/Skills/notify-project-team/SKILL.md
Agent Assets/Skills/notify-project-team/references/site.md
Agent Assets/Skills/notify-project-team/references/notices.md
```

The folder name must match the `name` in each `SKILL.md`. In the Copilot pane, type `/` and check all three skills appear.

## 6. Add the buttons

Quick Steps are a column type. On Change Orders, add a column of type Quick Steps and name it `Actions`. Then, in that column's Quick Steps pane, paste the three prompts under **Quick Steps** in the prompts file, one at a time. They create:

| Button | Show when | Prompt the button sends |
|---|---|---|
| Assess Change Order | Status is `Accepted` | `Use the assess-change-order skill for the selected Change Orders row.` |
| Confirm Change Impact | Status is `Assessed` | `Use the confirm-change-impact skill for the selected Change Orders row.` |
| Notify Project Team | Status is `Reviewed` | `Use the notify-project-team skill for the selected Change Orders row.` |

Only one button shows on a row at a time, and it is always the next step. Press the button on the row, not the one on the command bar: the command bar one acts on every selected row at once, which these skills don't expect.

## 7. Build the dashboard

The dashboard is bound to your lists, so it is built on your site rather than uploaded. Upload `prompts/project-dashboard-prompt.md` to the Documents library in a folder named `Skill Build`, then paste **Prompt E** in a fresh chat. It saves `Dashboards/project-dashboard.html`; the skills link to that exact path. Build it after the first assess step (step 8.1 below) so the In review section has something to show, or build it now and it will say "No change orders in review" until then.

If a detail is wrong, talk to the page in the same chat. If Copilot cannot change the page in place, delete it and run Prompt E again rather than patching; that is what worked for us.

The schedule view is optional. Upload `sample-files/Dashboards/schedule-view-template.html` to Dashboards in a folder named `Templates`, open a project list, and paste **Prompt F** in a fresh chat. Repeat per list.

## 8. Run it

Select the row `CO-1041 Riverside Corporate Office - Contoso Concrete.pdf` in Change Orders.

1. Press **Assess Change Order**. Expect a receipt: phase 3 Direct, phases 4 and 6 Shifted, phases 1, 2 and 5 Informational; completion 12 March → 2 April 2027; total $6,400,000 → $6,448,000; three Change rows on the Riverside list; the row at `Assessed` with a link to the dashboard.
2. Open the dashboard and look at CO-1041 under In review. Then press **Confirm Change Impact**. Read the schedule changes it shows, then reply `Confirm Change Impact`. Expect the addendum in Contracts (one-page cover, the contract, the change order: 16 pages), the Current rows for phases 3, 4 and 6 updated, the Projects row at 2 April and $6,448,000, the row at `Reviewed`.
3. Press **Notify Project Team**. It lists six phase managers, three impact notices and three information notices, each with the addendum link. Reply `Confirm to send`. Expect Notices Sent `1, 2, 3, 4, 5, 6` and the row at `Sent`, with no button left.

Then try CO-2007 (two changes in one document; phase 5 slides first, then grows; the completion does not move) and CO-3002 (one phase moves and nothing depends on it). Press Assess on CO-4015: it names a project that does not exist, and the skill must stop with nothing written. Compare each with `sample-files/answer-key.md`.

## If something doesn't match

- **"List not found" or a skill reading the wrong list.** The URLs in step 1 and the addresses in `site.md` must match exactly. The skills never search for a list by name.
- **"Column not found".** Internal names, step 3. The display name you type when a column is created decides its internal name.
- **Confirm stops before writing.** It builds the addendum first, on purpose: if the convert or merge tool is missing or refuses, nothing in the schedule has changed. It reports the tool names the site offers. Convert and merge need Copilot in SharePoint's file tools enabled on the tenant.
- **The merge produced the wrong pages.** The merge tool takes its sources from one library only, which is why the skill copies the change order into Contracts first. Check Contracts holds the cover PDF, the contract and the change order copy before the merged file.
- **Notify says there is no email tool.** Send email from Copilot in SharePoint is rolling out from October 2026. Until it reaches your tenant, the skill stops after listing who gets what.
- **A send was refused.** The skill reports it, records the phases that did send in Notices Sent, and leaves the row at `Reviewed`; pressing the button again offers only the unsent phases. Fictional addresses are refused by some tenants; use real inboxes in Project Team.
- **The skill stalls before writing anything.** Stop it and press again in a fresh chat. The Status gate and the Applied flag make a second press safe.

## Running it again

The chain is one-way (`Accepted` → `Assessed` → `Reviewed` → `Sent`). To run CO-1041 again, paste **Prompt G**: it deletes the Change rows and the addendum working files, puts the Current rows and the project totals back to the originals, and sets the change order back to `Accepted` with its columns cleared. It shows the plan and waits for `Confirm reset` before touching anything.
