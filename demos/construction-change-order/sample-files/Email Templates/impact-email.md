# Email template: change order impact notice

Used by the notify-project-team skill for every phase whose Effect is Direct or Shifted. One email per phase; a vendor holding two affected phases gets two emails. Fill every placeholder from the project list and the change order as the table says, keep all other wording and markup exactly as written. The body is HTML and is sent as the email's HTML body. All companies and people are fictional.

## Placeholders

| Placeholder | Where the value comes from |
|---|---|
| `{{manager_name}}` | Phase Manager on the phase's Current row (its address: the Project Team row of that name) |
| `{{vendor}}` | Vendor on the phase's Current row |
| `{{project_name}}`, `{{project_id}}` | Projects list |
| `{{change_order_no}}`, `{{accepted_on}}` | Change Orders library row |
| `{{change_order_title}}` | the title line on the change order's first page, directly above "<Vendor> requests the following change" |
| `{{phase_no}}`, `{{phase_name}}` | the phase |
| `{{effect}}` | `Direct` (the change order names your phase) or `Shifted` (a phase you depend on moved) |
| `{{effect_sentence}}` | Direct: "Change order {{change_order_no}} changes the work in your phase." Shifted: "Your phase moves because Phase {{depends_on}} ({{depends_on_name}}), which it depends on, now ends later." |
| `{{previous_start}}`, `{{revised_start}}`, `{{previous_end}}`, `{{revised_end}}` | the phase's Change row for this change order: Old Start, New Start, Old End, New End, written as 7 December 2026 |
| `{{slip_days}}` | revised end minus previous end, in days |
| `{{previous_cost}}`, `{{revised_cost}}` | the Change row: New Cost minus Cost Delta, and New Cost, as $1,028,000 |
| `{{project_rows}}` | One `<tr>` per phase on the project, in phase order: `<tr><td>N · Phase name</td><td>Vendor</td><td>Effect</td><td>Previous end</td><td>Revised end</td></tr>`; Effect is Direct, Shifted or Unchanged |
| `{{previous_completion}}`, `{{revised_completion}}` | previous: the latest of every Change row's Old End and every unchanged phase's End; revised: Projects list, Current Completion |
| `{{addendum_url}}` | the absolute URL of the addendum PDF in Contracts for this change order, used inside the `href` only |
| `{{pm_name}}` | Project Manager on the Projects list |

To: the Email of the Project Team row whose name is the phase's Phase Manager. CC: every Project Team row with Cc On Every Notice = Yes (the Zava Builders team). Send nothing for a phase whose manager has no Project Team row or no email; say which phase.

## Subject

{{project_name}}: change order {{change_order_no}} affects Phase {{phase_no}} {{phase_name}}

## Body (HTML)

```html
<div style="font-family:'Segoe UI',Arial,sans-serif;font-size:15px;line-height:1.55;color:#222;max-width:680px">
  <p style="font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#666;margin:0 0 6px">Zava Builders · Project {{project_id}}</p>
  <h2 style="font-weight:600;font-size:22px;margin:0 0 16px;color:#222">Schedule change for Phase {{phase_no}}: {{phase_name}}</h2>

  <p>Hello {{manager_name}},</p>
  <p>Change order <b>{{change_order_no}}</b> ({{change_order_title}}) on {{project_name}} was accepted on {{accepted_on}}. {{effect_sentence}} Here is the impact on your phase.</p>

  <table style="border-collapse:collapse;width:100%;margin:12px 0 18px;font-size:14px">
    <tr><th style="text-align:left;padding:8px 10px;border:1px solid #bbb;background:#f2f2f2"></th><th style="text-align:left;padding:8px 10px;border:1px solid #bbb;background:#f2f2f2">Previous</th><th style="text-align:left;padding:8px 10px;border:1px solid #bbb;background:#f2f2f2">Revised</th></tr>
    <tr><td style="padding:8px 10px;border:1px solid #bbb"><b>Start</b></td><td style="padding:8px 10px;border:1px solid #bbb">{{previous_start}}</td><td style="padding:8px 10px;border:1px solid #bbb">{{revised_start}}</td></tr>
    <tr><td style="padding:8px 10px;border:1px solid #bbb"><b>End</b></td><td style="padding:8px 10px;border:1px solid #bbb">{{previous_end}}</td><td style="padding:8px 10px;border:1px solid #bbb"><b>{{revised_end}}</b> ({{slip_days}} days later)</td></tr>
    <tr><td style="padding:8px 10px;border:1px solid #bbb"><b>Phase cost</b></td><td style="padding:8px 10px;border:1px solid #bbb">{{previous_cost}}</td><td style="padding:8px 10px;border:1px solid #bbb">{{revised_cost}}</td></tr>
  </table>

  <h3 style="font-size:14px;letter-spacing:.08em;text-transform:uppercase;color:#555;margin:22px 0 6px">The rest of the project</h3>
  <table style="border-collapse:collapse;width:100%;margin:6px 0 18px;font-size:13px">
    <tr><th style="text-align:left;padding:6px 8px;border:1px solid #bbb;background:#f2f2f2">Phase</th><th style="text-align:left;padding:6px 8px;border:1px solid #bbb;background:#f2f2f2">Vendor</th><th style="text-align:left;padding:6px 8px;border:1px solid #bbb;background:#f2f2f2">Effect</th><th style="text-align:left;padding:6px 8px;border:1px solid #bbb;background:#f2f2f2">Previous end</th><th style="text-align:left;padding:6px 8px;border:1px solid #bbb;background:#f2f2f2">Revised end</th></tr>
{{project_rows}}
  </table>
  <p>Planned completion for the project: {{previous_completion}} before this change order, <b>{{revised_completion}}</b> after.</p>

  <p style="margin:22px 0 10px">The updated agreement, with this change order attached as an addendum, is here:</p>
  <p style="margin:0 0 22px"><a href="{{addendum_url}}" style="display:inline-block;background:#333;color:#ffffff;text-decoration:none;padding:10px 18px;border-radius:4px;font-weight:600">Open the updated agreement</a></p>

  <p>Please confirm within two business days that your crew and material deliveries can meet the revised dates, or reply with what you need to make them. Do not change your own schedule records; the project schedule is held by Zava Builders.</p>

  <p style="margin-top:22px">Thank you,<br>{{pm_name}}<br>Project Manager, Zava Builders</p>

  <p style="font-size:11px;color:#999;margin-top:28px">Zava Builders, its projects, vendors, people and figures are fictional, created for a product demonstration.</p>
</div>
```
