# Email template: change order information notice

Used by the notify-project-team skill for every phase whose Effect is Unchanged (Informational). One email per phase. Fill every placeholder as the table says, keep all other wording and markup exactly as written. The body is HTML. All companies and people are fictional.

## Placeholders

| Placeholder | Where the value comes from |
|---|---|
| `{{manager_name}}`, `{{vendor}}` | the phase's Current row |
| `{{project_name}}`, `{{project_id}}` | Projects list |
| `{{change_order_no}}`, `{{accepted_on}}` | Change Orders library row |
| `{{change_order_title}}` | the title line on the change order's first page, directly above "<Vendor> requests the following change" |
| `{{phase_no}}`, `{{phase_name}}`, `{{start}}`, `{{end}}` | the phase's Current row (unchanged) |
| `{{changed_phases}}` | One `<li>` per Change row of this change order (Direct or Shifted): `<li><b>Phase N · Name</b> (Vendor): ends Old End → New End</li>` |
| `{{previous_completion}}`, `{{revised_completion}}` | previous: the latest of every Change row's Old End and every unchanged phase's End; revised: Projects list, Current Completion |
| `{{addendum_url}}` | the absolute URL of the addendum PDF in Contracts for this change order, used inside the `href` only |
| `{{pm_name}}` | Project Manager on the Projects list |

To: the Email of the Project Team row whose name is the phase's Phase Manager. CC: every Project Team row with Cc On Every Notice = Yes. Send nothing for a phase whose manager has no Project Team row or no email; say which phase.

## Subject

{{project_name}}: change order {{change_order_no}} accepted (no change to Phase {{phase_no}})

## Body (HTML)

```html
<div style="font-family:'Segoe UI',Arial,sans-serif;font-size:15px;line-height:1.55;color:#222;max-width:680px">
  <p style="font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#666;margin:0 0 6px">Zava Builders · Project {{project_id}}</p>
  <h2 style="font-weight:600;font-size:22px;margin:0 0 16px;color:#222">Change order {{change_order_no}} accepted on {{project_name}}</h2>

  <p>Hello {{manager_name}},</p>
  <p>Change order <b>{{change_order_no}}</b> ({{change_order_title}}) was accepted on {{accepted_on}}. <b>It does not affect your work.</b> Phase {{phase_no}}, {{phase_name}}, stays on its current schedule: {{start}} to {{end}}.</p>

  <h3 style="font-size:14px;letter-spacing:.08em;text-transform:uppercase;color:#555;margin:22px 0 6px">What changed elsewhere on the project</h3>
  <ul style="margin:0 0 12px 18px;padding:0">
{{changed_phases}}
  </ul>
  <p>Planned completion for the project: {{previous_completion}} before this change order, <b>{{revised_completion}}</b> after.</p>

  <p style="margin:22px 0 10px">The updated agreement, with the change order attached as an addendum, is here for your records:</p>
  <p style="margin:0 0 22px"><a href="{{addendum_url}}" style="display:inline-block;background:#333;color:#ffffff;text-decoration:none;padding:10px 18px;border-radius:4px;font-weight:600">Open the updated agreement</a></p>

  <p>No action is needed. If you believe the change does affect your phase, reply to this email before the revised dates above are relied on.</p>

  <p style="margin-top:22px">Thank you,<br>{{pm_name}}<br>Project Manager, Zava Builders</p>

  <p style="font-size:11px;color:#999;margin-top:28px">Zava Builders, its projects, vendors, people and figures are fictional, created for a product demonstration.</p>
</div>
```
