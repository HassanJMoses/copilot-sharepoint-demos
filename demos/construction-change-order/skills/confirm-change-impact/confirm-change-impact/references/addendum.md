# The contract addendum: cover sheet + signed contract + change order

"Addendum" here means the place where an accepted change order is appended to the contract. The output is one PDF made of three documents, each starting on its own page: a one-page cover sheet filled from the lists, the signed contract unchanged, and the change order. Nothing is written into the contract itself.

## Files (Contracts library, addresses in `site.md`)
- The project's signed contract: the Contracts file with `ProjectID` = the project and `DocumentType` = `Contract` (its name is also in the Projects row, `ContractFile`).
- The cover sheet template: `addendum-template.html`, `DocumentType` = `Template`. Read it with `tools.files.read({fileUrl: "https://YOUR-TENANT.sharepoint.com/sites/YOUR-SITE/Contracts/addendum-template.html"})`; the signed contract in a second, separate call, with the site prefix + its `FileRef`. One file per read call; never both in one `paths` list.
- The change order PDF: the selected Change Orders file.

## Placeholders in `addendum-template.html`
Every `{{...}}` below must be filled; none may be left, and no other text in the template changes. Dates are written long (`7 December 2026`); money as `$6,448,000`.

| Placeholder | Value |
|---|---|
| `{{addendum_no}}` | 1 + the number of `Addendum` files already in Contracts for this `ProjectID` |
| `{{contract_date}}` | the contract's date as printed on its first page (the signed contract is read once for this; take "dated <date>" from the title block) |
| `{{project_id}}`, `{{project_name}}` | Projects row |
| `{{change_order_no}}`, `{{change_order_title}}` | the Change Orders row's `ChangeOrderNo`; the title line printed on the change order's first page directly above the sentence "<Vendor> requests the following change", written with plain letters (PDF text can carry ligature characters such as ﬁ, ﬂ, ﬃ for fi, fl, ffi; spell them out) |
| `{{vendor}}` | Change Orders row `Vendor` |
| `{{submitted_on}}` | the submission date printed on the change order |
| `{{accepted_by}}` | Projects row `ProjectManager` |
| `{{accepted_on}}` | Change Orders row `AcceptedOn` |
| `{{original_total}}`, `{{current_total}}` | Projects row `CurrentTotal` before this change (as read in the gate), and the total after (sum of the Change rows' `NewCost` plus the other Current rows' `Cost`) |
| `{{original_completion}}`, `{{current_completion}}` | Projects row `CurrentCompletion` before, and the completion after (the latest of every Change row's `NewEnd` and every other Current row's `End`) |

"Before" means before this change order, which is what the Projects row says at the gate; it is not the Original rows.

## Steps
1. **Fill** the template text (read in this run) and save with `tools.output.createFile({fileName:"<CO No> Addendum - <Project Name> Cover.html", listUrl:"<Contracts URL>", folderPath:"", content: <the filled page>})`. This is the one place `content` is allowed, because the page is built from template text read in the same run. Check no `{{` remains. Leave the html's columns blank (no `DocumentType`).
2. **Convert** it with the site's PDF convert tool: `tools.files.convert({fileUrl: <the html's fileUrl>, format:"pdf"})`, or `convertToPdf` where that is the name offered. The result is `<CO No> Addendum - <Project Name> Cover.pdf`, one page; the merged file below gets the name without `Cover`.
3. **Copy the change order into Contracts**: merge only takes sources from one library, and the change order lives in Change Orders. `tools.files.copy({jobs:[{itemPaths:["<the selected file's server-relative path, e.g. /sites/ZavaBuilders/ChangeOrders/CO-1041 Riverside Corporate Office - Contoso Concrete.pdf>"], destinationFolderPath:"", sourceListUrl:"<Change Orders URL>", destinationListUrl:"<Contracts URL>"}], nameConflictBehavior:"rename"})`. The copy keeps the selected file's exact name (`FileLeafRef`, e.g. `CO-1041 Riverside Corporate Office - Contoso Concrete.pdf`), so its absolute URL is the Contracts URL + `/` + that name; if the copy result reports a renamed file (a number added on a name clash), use the name it reports. Confirm by reading the Contracts file row whose `FileLeafRef` equals that name. Never pick the change order source by prefix: the cover pdf and the cover html also start with the change order number. A file whose name contains `Addendum` or `Cover` is never the change order.
4. **Merge** with the site's PDF merge tool (`tools.files.merge`, or `mergePdfs` where that is the name offered): `tools.files.merge({fileUrls:[<cover pdf>, <signed contract pdf>, <the change order copy in Contracts>], fileName:"<CO No> Addendum - <Project Name>.pdf", listUrl:"<Contracts URL>"})`, in that order, all three in Contracts. Before calling, check the three URLs name three different files: the first ends in `Cover.pdf`, the second is the `Contract` row's file, the third is the change order's own file name. A list with the cover twice, or without the change order, is wrong; fix it, do not merge. (Seen 2026-10-28: CO-3002's first addendum was cover, contract, cover, with the change order missing.)
5. **Label** the merged file's row: `ProjectID`, `DocumentType` = `Addendum`, `ChangeOrderNo`. The html, the cover pdf and the change order copy stay with `DocumentType` blank (never `Template`: that label is the one real template only); only the merged pdf is labelled `Addendum`. Never delete anything.
6. Read the Contracts file rows where `ChangeOrderNo` equals the number and `DocumentType` = `Addendum`: exactly one. Its absolute URL is the addendum link the notify skill puts in every email.

The tool names vary by site (`tools.files.convert` / `convertToPdf`, `tools.files.merge` / `mergePdfs`); call whichever the site offers. Only if no tool converts to PDF or none merges PDFs, stop before any schedule write and report the exact tool names available. Never substitute a generated document for the contract.
