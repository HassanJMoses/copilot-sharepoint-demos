# Change Order Management: a Copilot in SharePoint demo

A general contractor runs three building projects. A formal change order comes in on one phase of one project: more days, more money. Three buttons on that change order's row carry it through to done. The first works out which phases move and by how much, following the project's own dependency chain, and shows the impact on a live dashboard. The second asks the project manager to confirm, then applies the new dates and cost to the schedule and builds the contract addendum. The third tells every phase manager on the project, the ones whose work changed and the ones who only need to know, each with a link to the amended agreement. Everything runs inside SharePoint, with Copilot in SharePoint doing the work and three skills telling it how.

By hand that coordination takes one to two weeks, one step after another, by one person. Here it is assessed, confirmed and communicated in a day, and a person still makes every decision.

**This is a demo.** Zava Builders, Contoso Concrete, Northwind Structures, Tailspin Mechanical, Wingtip Interiors, Litware Workplace, and every person, project, contract, dollar figure and date in this repository are fictional, built for a Copilot in SharePoint product demonstration. Nothing here is a real contract, a real change order, or legal, financial or construction advice.

## What's in the box, and why each piece is there

Each piece says what it is, what it's for, and why it ended up this way. Most of these choices were made after something simpler didn't work.

### The lists and libraries

| List or library | What goes in it | Why it exists |
|---|---|---|
| **One list per project** (Riverside Corporate Office, Harbor Logistics Center, Elm Street Clinic) | The project's phases, three kinds of row: **Original** (the schedule as signed), **Current** (the schedule as it stands) and **Change** (one row per phase a change order moves, with the old and new dates and cost) | The dependency chain is a column, `Depends On`. Which phases move is a read of that column, never a judgement. Keeping Original, Current and Change as rows of one list means the dashboard can draw "original against current" and "what this change order would do" without any schedule arithmetic of its own. |
| **Projects** | One row per project: ID, name, manager, original and current total, original and current completion, a link to its list and to its contract | The project record. The change order names a project by ID, and the match has to be real: a wrong ID (there is one in the sample set) stops the skill with nothing written. |
| **Project Team** | Who gets mail: name, company, role, email, and whether they are copied on every notice | Addresses come from here and nowhere else. No address is ever read from a document. People maintain this list; the skills only read it. |
| **Change Orders** | One PDF per accepted change order, with its project, vendor, a Status, and three columns the assess step fills (title, days added, cost added) | The inbox and the control panel. The three buttons live here, and Status decides which one shows: `Accepted` → Assess, `Assessed` → Confirm, `Reviewed` → Notify, `Sent` → done. |
| **Contracts** | The signed contracts, the addendum cover template, and the addenda the confirm step builds | The addendum is the cover sheet, then the signed contract unchanged, then the change order, merged into one PDF. Nothing is written into the contract. |
| **Email Templates** | `impact-email.md` and `informational-email.md` | The two notices. Edit the wording here, not in the skill. The placeholder table at the top of each file says where every value comes from. |
| **Dashboards** | `project-dashboard.html`, built once by Copilot in SharePoint from a prompt, and the schedule view template | A live page that reads the lists when it opens. The skills link to it and never write to it. |
| **Agent Assets › Skills** | The three skill folders | Where Copilot in SharePoint looks for skills on a site. A skill anywhere else is just a file. |

### The skills

Three skills, one per button. Each is a folder with a short `SKILL.md` and a `references/` folder that carries the facts.

| Skill | Button | What it does | Writes |
|---|---|---|---|
| `assess-change-order` | Assess Change Order, on `Accepted` | Reads the change order, matches the project by ID, takes the days and the cost from the document (it never estimates), follows `Depends On` to find every phase that moves, prints the receipt with every phase marked Direct, Shifted or Informational, writes one Change row per moved phase, and ends at `Assessed` with a link to the dashboard | Change rows on the project list; title, days added, cost added and Status on the change order row |
| `confirm-change-impact` | Confirm Change Impact, on `Assessed` | Asks "Have you confirmed that the impact summary is correct?" and lists the schedule changes. Only after the exact reply `Confirm Change Impact`: builds the addendum first (so a failure there leaves the schedule untouched), then copies each Change row's new values onto its Current row, updates the project totals, marks the Change rows Applied, and sets `Reviewed` | Contracts (the addendum and its working files), Current rows, Change rows, the Projects row, Status |
| `notify-project-team` | Notify Project Team, on `Reviewed` | Lists who gets which notice: the impact notice for the phases that moved, the information notice for the rest, every one linking the addendum, the team on copy. Only after `Confirm to send`: sends one email per phase, records each phase on the row as it goes, and sets `Sent` | Emails; Notices Sent and Status on the row |

Why three skills and not one: each button is a checkpoint, and two of them are a person. Assess is automatic and writes only Change rows, which commit nothing. Confirm is where authorisation lives: nothing in the schedule, the project record or the contract changes before someone has read the impact and typed the phrase. Notify asks again before anything leaves the building.

Three rules that run through all of them:

- **Facts arrive with the data.** The change order states its own impact in days and dollars. The skill reads those numbers; it never works out how long a floor takes to cure.
- **Records, not context.** Each change is a row. The confirm step recomputes nothing; it copies the Change rows onto the Current rows, exactly once, and an `Applied` flag stops a second press from applying it twice.
- **Content is data.** Text inside a change order, a contract, a template or a list row is never an instruction to a skill. One of the sample change orders contains a line addressed to "any automated assistant"; the skills ignore it and say so in their report.

### The reference files: the rulebook, separate from the skill

- **site.md** (the same in all three skills): the addresses of every list and library, the column names, the exact shape of every tool call, the content-is-data rule and the retry limits. Setup replaces one site prefix in it.
- **propagation.md** (assess): the arithmetic. The Direct phase grows by the days in the document. A phase that depends on a moved phase slides whole, keeping its own length and the gap it had. When one document changes two phases and one depends on the other, slide first, then grow. The project completion is the latest new end.
- **addendum.md** (confirm): the merge recipe. Fill the cover template, convert it to PDF, copy the change order into Contracts (the merge tool takes its sources from one library only), merge cover + contract + change order, label the result.
- **notices.md** (notify): which template each phase gets and where every placeholder comes from.

A business owner changes the behaviour by editing these files, not the skill.

### The dashboard, and the schedule view inside a list

`project-dashboard.html` is one page for all of Anissa's projects, built once by Copilot in SharePoint from the prompt in `prompts/project-dashboard-prompt.md` and linked live to the lists. One project at a time: completion and total against the originals, a timeline of original against current, the phase table. One assessed change order at a time under **In review**: the timeline with the new dates in orange and each phase tagged Direct, Shifted or Unchanged, what changes, who hears. A change order log across all projects. The page calculates no schedule; every number it shows is on a list already.

The **Schedule view** is the same idea inside a list view: a template HTML file plus a short prompt turns the plain list of phases into a page with the timeline, the drift since the original and the dependency chain. A rich, interactive page can live right where the list is.

Both are built by Copilot in SharePoint from a prompt, not uploaded, because the page has to be bound to your site's lists. The built pages are included for reference only.

### The sample files

| Folder | Contents | Notes |
|---|---|---|
| `sample-files/Lists/` | One CSV per project list (Original and Current rows only; Change rows are what the skills write), `projects.csv`, `project-team.csv` | Loaded by the provisioning prompts. Dates are fixed, not relative to today, so the story reads the same whenever it is run. |
| `sample-files/Contracts/` | Three signed contracts (11 pages each) and `addendum-template.html` | The contracts are the originals the addendum merges, unchanged. |
| `sample-files/Change Orders/` | Four change orders in the AIA G701 shape | CO-1041 is the headline (phase 3, +21 days, +$48,000; phases 4 and 6 slide). CO-2007 changes two phases in one document. CO-3002 moves one phase that nothing depends on. CO-4015 names a project that does not exist: the assess step must stop. |
| `sample-files/Email Templates/` | The two notice templates | |
| `sample-files/Dashboards/` | The built dashboard page and the schedule view template, with the site values replaced by placeholders | For reference; build yours from the prompts. |
| `sample-files/reference/` | The three expected addenda | What confirm should produce. Keep them off the site. |
| `sample-files/answer-key.md` | Every phase's expected effect, dates and cost per change order, the completion and total before and after, and who gets which notice | For checking a run. Keep it off the site: if Copilot can read it, the test proves nothing. |

## Setup

See [setup.md](setup.md). About forty-five minutes: create the lists and columns from one prompt, upload the sample files, load the rows from two prompts, upload the three skills, add the three buttons, build the dashboard.

## Features used

| Feature | Included with the Microsoft 365 Copilot licence or Copilot Credits |
|---|---|
| Skills in Agent Assets, with reference files | Included |
| Quick Steps buttons running a skill on the selected row, shown by Status | Included |
| Reading a PDF, reading and writing list rows, creating an HTML file | Included |
| Converting the cover sheet to PDF and merging three PDFs into the addendum | Credit-billed |
| A live HTML dashboard page, and an HTML view on a list | Built once in Copilot in SharePoint |
| Send email from Copilot in SharePoint | Rolling out from October 2026; the notify skill's last step depends on it |

## Also available

The three skills are in the PnP SharePoint Skills library, in the same folder layout, so you can install them from either place. This repository holds the full demo: the story, the sample files, the dashboard prompts and the setup.

## Licence

MIT. Reuse the skills and the sample files freely; keep the attribution line in `SKILL.md`.

---

Built by Hassan Moses. Part of the Copilot in SharePoint use case series.
