# New Customer Packet: a Copilot in SharePoint demo

One button on a new customer's application builds their whole insurance welcome packet: it reads the application, picks the right documents for their state and coverage, fills them in, renders them as branded PDFs, merges them into one file, and files it for review. A second button reviews the packet against the application. A third emails it to the customer. Everything runs inside SharePoint, with Copilot in SharePoint doing the work and three skills telling it how.

**Watch it run:** [Copilot in SharePoint for Insurance](https://www.youtube.com/watch?v=xFWDL-QakWM) (12 minutes).

Tested on packets of up to 37 documents and 65 pages, two states and nine vehicles, built from one click in about four minutes.

**This is a demo.** Contoso Insurance, Zava, and every business, person, policy number, dollar figure, and vehicle identification number (VIN) in this repository is fictional, built for a Copilot in SharePoint product demonstration. Nothing here is a real insurance policy, offer of coverage, or legal, financial, or insurance advice.

The three state seals used on the Texas, Florida, and Louisiana sample documents are public-domain images from Wikimedia Commons, used here only for visual realism on synthetic demo documents. Their use is not an endorsement by, or affiliation with, any state government, and state law can restrict the use of official seals independent of their copyright status. Do not reuse these seal files outside this demo, and do not use them on anything that could pass as a real government or insurance document. See `sample-files/Template Layouts/Seals/README.md` for sources.

## What's in the box, and why each piece is there

Everything below is explained the way you'd explain it to a colleague who has never built a skill. Each piece says what it is, what it's for, and why it ended up this way. The "why" matters more than the "what": most of these choices were made after something simpler didn't work.

### The SharePoint libraries

The demo site has five document libraries plus a skills folder. Each one holds one kind of thing, and the skills address them by name.

| Library | What goes in it | Why it exists |
|---|---|---|
| **New Customers** | One PDF per application, with columns for the customer's details and a Package status | This is the inbox. The Build package button lives on each row. The columns are filled by the skill as it reads the application, so a person can see at a glance what Copilot understood before trusting the packet. |
| **Templates** | One Word document per form (32 of them: 5 standard, 9 for each of Texas, Florida and Louisiana), with columns that say when each applies | The columns are the rules. Scope (Standard or State), State, Coverage trigger and Business type trigger let the skill select by filtering, never by guessing from file names. Adding a state is uploading its nine forms with the columns set. Nothing else changes. |
| **Template Layouts** | One HTML file per template, plus a `Seals` folder with the three state seal images | Optional, and the reason the PDFs look like the Word templates. See the next section. |
| **Packages** | One working folder per customer, holding the filled documents and the merged PDF | The scratch space. Everything here is rebuilt from scratch on every run, so it can be cleared at any time. |
| **Completed Packets** | The merged PDF only, with the customer's details as columns and a Packet status | What the business actually keeps. The review and send buttons live here, and they work from the columns rather than re-reading the application, so they're fast and predictable. |
| **Agent Assets › Skills** | The three skill folders | Where Copilot in SharePoint looks for skills on a site. A skill anywhere else is just a file. |

### Template Layouts: optional, and why you probably want it

Copilot in SharePoint can fill a Word template and turn it into a PDF on its own. What it can't do, today, is keep the template's pictures and most of its formatting when it does that: it reads the Word file as text, writes a fresh document from that text, and converts it. The letterhead, the colours and the seal are gone.

The Template Layouts library fixes that. Each layout is the same document as its Word template, converted once to HTML with its fonts, colours, spacing, tables and letterhead written out in full, and with the customer's values marked as placeholders like `{{business_name}}`. The skill fills the placeholders, saves the HTML, and asks SharePoint to convert that file to PDF. Because the conversion starts from the full layout rather than from extracted text, the PDF keeps the design.

So: if you only need the words on the page, skip this library and let the skill work from the Word templates. If the documents have to look like your documents, with a logo, a seal, a coloured rule and real tables, use the layouts. That's the whole trade-off, and it's why the library is marked optional.

A few things we learned the hard way, which the layouts already account for:

- The converter is a browser engine. It handles fonts, colours, borders and tables well. It drops background fills behind table header rows and doesn't have every font, so the layouts use a navy rule instead of a filled banner.
- The layouts contain no image data. Images go in through the file writer's own image mechanism, described next.
- The layouts have no structural edits for Copilot to make. The vehicle schedule has twelve fixed rows; unused rows are blanked. Asking Copilot to "repeat a row" lost half a document once.

### Seals: the image files, and why they live where they do

Every state document carries that state's seal. The seals are three PNG files in `Template Layouts/Seals`. The build skill resolves each one's address at the start of every run and hands it to the file writer alongside the filled layout, and the writer embeds the image when it saves the file.

Why a separate folder of image files, and not pictures inside the layouts: when Copilot reads any file, it strips the pictures out and replaces them with placeholders. So an image inside a layout never survives the trip. The only way a picture gets into a file Copilot writes is by naming the image file on the site when the file is saved. That turned out to be the reliable path on large packets. On builds of 60 pages and more it resolved every seal, where embedding the images in the layouts failed in different ways on different runs.

The writer can also pull "stock" images by description. Don't. It's a stock photo library: asked for "Seal of Louisiana" it returned a photograph of a sealed cardboard box.

### The skills

Three skills, one per button. Each is a folder with a `SKILL.md` that tells Copilot what to do, and the build and review skills carry two reference files.

| Skill | Button | What it does | Writes |
|---|---|---|---|
| `new-customer-packet` | Build package, on New Customers | Reads the application, fills the columns, selects templates by their columns, builds one ordered list of documents, renders each one, merges, copies to Completed Packets, marks the application Package ready. Stops with Needs information if a required count is missing. | New Customers columns; one folder in Packages; one file and its columns in Completed Packets |
| `review-customer-packet` | Review packet, on Completed Packets | Works out from the application and the rulebook what the packet should contain, reads the merged PDF, and shows an expected-versus-found table with every VIN reconciled. Sets Customer Ready only after you reply "Confirm packet ready". | One column, Packet status |
| `send-customer-packet` | Send to customer, on Completed Packets | Fills the email template from the packet's columns, creates a view-only link, shows you To, Subject and body, and sends only after "Confirm to send". Then sets Customer Sent. | One column, Packet status |

Why three skills and not one: each button is a human checkpoint. Build is automatic. Review stops and asks. Send stops and asks. The statuses (Package ready, Packet Complete, Customer Ready, Customer Sent) are what make the buttons appear in the right place at the right time, and they're plain SharePoint columns anyone can read.

### The reference files: the rulebook, separate from the skill

Two markdown files travel with the build and review skills, in their `references` folders.

- **packet-manifest.md** says what a complete packet is: which documents, in what order, one state section per state the customer touches, one proof-of-insurance card per vehicle in every state section, when to stop and ask for information, and what to write in the "Documents included and why" column.
- **template-fields.md** says where every placeholder's value comes from on the application, and how to treat "N/A".

Why they're separate from the skill: a business owner changes the packet by editing the rulebook, not the skill. Adding a document, changing the order, tightening a stop rule: all edits to a readable file. The skill itself is about *how* to do the work (which tools, in what order, what to check); the rulebook is about *what* the work is. Keeping them apart is also why the review skill can check the build: both read the same rulebook.

### The sample files

| Folder | Contents | Notes |
|---|---|---|
| `sample-files/New Customers/` | 50 application PDFs | 45 complete, 5 with a required count missing (the stop-rule cases), 17 that mention work in a second state. All synthetic. |
| `sample-files/Templates/` | 32 Word templates | Their column values are in `setup/document-columns.csv`. |
| `sample-files/Template Layouts/` | 32 HTML layouts and the `Seals` folder | Generated from the Word templates. Optional (see above). |
| `sample-files/Email templates/` | `customer-packet-email.md` | The email the send skill fills. Edit the wording here, not in the skill. |
| `sample-files/answer-key.xlsx` | The expected packet for every application | For checking a run: status, documents, order, the exact "why" line for each document. Keep it off the site: if Copilot can read it, the test proves nothing. |
| `setup/libraries-and-columns.csv` | Every library and column: internal name, display name, type, choices, default | Read by the setup script and by the Copilot prompts, so both routes build the same site. |
| `setup/document-columns.csv` | Every template and layout with its column values, headed by internal names | Same: one source for the script and the prompts. |

### How the skill talks to SharePoint, in one paragraph

Every call the build skill makes names the library by its full address and then the file or folder relative to it: "this library, this folder, this file". It never composes a path. The library addresses sit at the top of the skill as constants, and setup replaces one site prefix to point them at your site. The same idea runs through the whole skill: anything Copilot would otherwise have to look up, infer or compose (column names, file names, call shapes, the seal addresses) is either written down as a fact or resolved once at the start of the run and then held. That's the single biggest reason the build runs the same way every time.

## Setup

See [setup.md](setup.md). In short:

1. **Provision.** Run `setup/Setup-NewCustomerPacket.ps1 -SiteUrl <your site>`. It creates the five libraries and their columns, uploads the sample files with their column values, and uploads the three skills with your site address filled in. No PowerShell? The Copilot prompts in `prompts/` do the same by hand.
2. **Test.** Run each skill once from the Copilot pane on a selected file, so you know it works on your site.
3. **Add the buttons.** Add a Quick Steps column to New Customers and to Completed Packets, then ask Copilot in SharePoint to attach each skill to a quick step, shown by status: Build package when Package status is New or Needs information, Review packet when Packet status is Packet Complete, Send to customer when Packet status is Customer Ready.

## Features used

| Feature | Included with the Microsoft 365 Copilot licence or Copilot Credits |
|---|---|
| Skills in Agent Assets, with reference files | Included |
| Quick Steps buttons running a skill on the selected item | Included |
| Reading PDFs, filling and saving HTML, converting to PDF, merging PDFs, copying files, setting columns | Included for everyday volumes; a 37-document build asked for Copilot Credits once when a run was interrupted and retried, and not on a clean run |
| Send email from Copilot in SharePoint | Rolling out from October 2026; the send skill's final step depends on it |

## Also available

The three skills are in the PnP SharePoint Skills library, in the same folder layout, so you can install them from either place. This repository holds the full demo: the story, the sample files, the layouts and the setup.

## Licence

MIT. Reuse the skills and the sample files freely; keep the attribution line in `SKILL.md`.

---

Built by Hassan Moses. The seven-part video series runs up to Microsoft Ignite 2026.
