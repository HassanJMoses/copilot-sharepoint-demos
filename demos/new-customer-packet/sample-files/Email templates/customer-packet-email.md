# Email template: new customer package

Used by the "Share with customer" quick step in the Completed Packets library. Fill every placeholder from the packet's own columns, as the table below says, and keep all other wording exactly as written. Do not add, remove or reword sentences. All companies and people are fictional.

## Placeholders

| Placeholder | Where the value comes from |
|---|---|
| `{{contact_name}}` | Contact name column |
| `{{business_name}}` | Business name column |
| `{{policy_number}}` | Policy number column |
| `{{policy_start_date}}` | Policy start date column, written as a date like March 2, 2027 |
| `{{package_link}}` | The view-only sharing link created for this file when it is shared with the Contact email address |

Send to the address in the Contact email column. Send nothing if any placeholder has no value; say which one is missing.

## Subject

Contoso Insurance: new customer package for {{business_name}}, policy {{policy_number}}

## Body

Dear {{contact_name}},

Thank you for choosing Contoso Insurance. Your new customer package for {{business_name}} is now available.

Policy number: {{policy_number}}
Policy start date: {{policy_start_date}}

The package contains your welcome letter, coverage summary, policy documents and the notices required in each state where you operate. You can view it securely here:

{{package_link}}

This link provides view-only access. Please review the documents carefully and retain a copy for your records. Where the package includes notices that must be displayed for employees, please post them as directed.

If any information in the package is incorrect or differs from what you expected, please contact us before your policy start date by replying to this email or calling 1-800-555-0100.

We look forward to working with you.

Sincerely,

Dana Whitfield
New Business Coordinator
Contoso Insurance
8400 Innovation Parkway, Suite 300, Dallas, TX 75201 | 1-800-555-0100

Contoso Insurance, Zava, and all names, addresses, policy numbers, and figures in this email are fictional, created for a product demonstration. This is not an insurance policy and provides no coverage.
