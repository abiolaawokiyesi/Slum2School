# What's new in v6.13.0 (7 November 2026)

## Company format requisition (third template)

New template at the top of the list: **Company format: Memo, Requisition and Vendor invoice**.
The two existing templates are untouched.

* The Memo and the Requisition print exactly as in `MEMO AND REQUISITION ONE DOC.pdf`: A4,
  the full-page letterhead photo, logo, MEMO mark, blue side bar, copyright line, fonts,
  colours, columns and positions. Every text line measured within about 1 point of the PDF.
* **Vendor invoice**: upload a photo, scan or PDF (several allowed). Each page prints
  after the Requisition, so one print gives three documents: Memo, Requisition, Invoice.
* **Automatic filling**: start typing the staff name and the job title, team, department,
  "From" and the fund-transfer account (from the salary report) fill themselves. The date,
  "To: FINANCE", appendix line, and the Finance and Executive Director signatories are
  pre-filled. The background is drafted from the subject. Qty x Cost gives Total Cost; the
  total gives the amount, the amount in words and the prayer on the memo.
* The portal **learns**: after a save it remembers each person's team, department and
  account, and offers earlier subjects, payees and item descriptions as suggestions.
* A long item list continues on a second letterhead sheet with the table headings repeated.

## Setting up the cloud (optional, 2 minutes)
Run `supabase/10_v613_company_requisition.sql` once in the Supabase SQL Editor so
requisitions and invoices follow staff across devices. Without it everything still works
on the device that raised the requisition.

## Release markers
Build comment, `S2S_VERSION`/`S2S_BUILD`, the loaded banner and the service worker cache
(`s2s-portal-v6_13_0`) are all 6.13.0 / 2026-11-07. Hard-refresh once after deploying.
