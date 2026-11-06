# Notices: which template each phase gets, and where every value comes from

Two templates in Email Templates, read in the run: `impact-email.md` and `informational-email.md`. Each has a placeholder table, a Subject line and a Body (HTML) block. This file is the authoritative placeholder map; where a template's own table differs, this file wins. The Body is sent as `htmlBody` with every placeholder filled and the markup kept exactly; the addendum link is the `<a href>` already in the template, never a pasted URL. Never invent substitute wording.

## Which template
- **Impact** (`impact-email.md`): every phase that has a Change row for this change order (`Kind` `Direct` or `Shifted`).
- **Informational** (`informational-email.md`): every other Current row.
- One email per phase. A vendor holding two phases gets two emails. A `Complete` phase still gets its informational notice.

## Values
Dates are written long (`7 December 2026`); money as `$1,028,000`. All from the lists read in the gate.

| Placeholder | Impact notice | Informational notice |
|---|---|---|
| `{{manager_name}}`, `{{vendor}}` | the phase's Current row (`PhaseManager`, `Vendor`) | same |
| `{{project_name}}`, `{{project_id}}`, `{{pm_name}}` | Projects row (`ProjectName`, `ProjectID`, `ProjectManager`) | same |
| `{{change_order_no}}`, `{{accepted_on}}` | Change Orders row | same |
| `{{change_order_title}}` | the title line printed on the change order's first page directly above the sentence "<Vendor> requests the following change" (read the file once) | same |
| `{{phase_no}}`, `{{phase_name}}` | the phase | same |
| `{{effect}}` | the Change row's `Kind` | (not used) |
| `{{effect_sentence}}` | Direct: "Change order <no> changes the work in your phase." Shifted: "Your phase moves because Phase <DependsOn> (<that phase's name>), which it depends on, now ends later." | (not used) |
| `{{previous_start}}`, `{{revised_start}}`, `{{previous_end}}`, `{{revised_end}}` | the Change row: `OldStart`, `NewStart`, `OldEnd`, `NewEnd` | (not used) |
| `{{slip_days}}` | `NewEnd` − `OldEnd` in days | (not used) |
| `{{previous_cost}}`, `{{revised_cost}}` | `NewCost` − `CostDelta`, and `NewCost` | (not used) |
| `{{start}}`, `{{end}}` | (not used) | the Current row's `Start`, `End` |
| `{{project_rows}}` | one `<tr>` per phase on the project in phase order: `<tr><td>N · Phase name</td><td>Vendor</td><td>Effect</td><td>Previous end</td><td>Revised end</td></tr>`; Effect `Direct` / `Shifted` from the Change row or `Unchanged`; previous and revised end from the Change row, or the Current `End` twice for Unchanged | (not used) |
| `{{changed_phases}}` | (not used) | one `<li>` per Change row: `<li><b>Phase N · Name</b> (Vendor): ends <OldEnd> → <NewEnd></li>` |
| `{{previous_completion}}` | the latest of every Change row's `OldEnd` and every unchanged Current row's `End` (the schedule before this change order; never the Original rows) | same |
| `{{revised_completion}}` | Projects row `CurrentCompletion`, always a date; when it equals the previous completion both placeholders carry the same date (the chat summary says "unchanged", the email shows the dates) | same |
| `{{addendum_url}}` | the absolute URL of the Contracts `Addendum` file for this change order, inside the `href` only | same |

## Subjects
As the templates say: impact "<project name>: change order <no> affects Phase <n> <name>"; informational "<project name>: change order <no> accepted (no change to Phase <n>)".

## Receipt
Before asking for confirmation, freeze (do not print) the change order number and, per phase in order, phase, manager, address, template, subject, body. `Confirm to send` authorises only that receipt. Phases listed in the row's `NoticesSent` are not in the receipt.
