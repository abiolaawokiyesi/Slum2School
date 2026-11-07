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

* **Team** is a drop-down of the available teams (Admin and Logistics, Executive Office,
  Finance, Growth and Fundraising, Human Resource, Media and Communication, Partnerships,
  Programs, Projects, Volunteer Management, Operations, Education). The most likely team is
  suggested first; staff can also type their own. Department and "From" follow the team.
* The drafted background now reads "This memo is written to request for funds for the ...".

## Edit a saved requisition, or save a draft and finish later
* Every saved requisition (all three templates) has an **Edit** button while it is Draft or Pending.
  It reopens the form with everything filled in, including the vendor invoice. **Save changes**
  replaces the same requisition (no copy). Once it is approved or paid it is locked; **Reuse** still makes a copy.
* **Save draft** keeps a half-filled form with nothing required. Drafts show a Draft label with a
  **Continue** button, and stay out of the Finance / ED approval queue until you save them as a real requisition.
* Edits made offline are queued and update the same requisition in the cloud when you reconnect.
* Cancel on the form now closes it (it did nothing before).
* Cloud: run `supabase/12_v613_requisition_drafts.sql` so drafts can sync across devices and be edited
  from any device. Editing a Pending requisition needs no SQL.

## HR approves every new account
* Anyone who registers is a **request**. They cannot sign in, or see or save anything, until
  HR approves them. They are told this on screen.
* HR (Super Admin) sees a banner on the dashboard and an **Account requests** card at the top
  of the Admin Panel, with Approve and Decline buttons. Existing accounts stay approved. HR,
  ED and Finance addresses in `access_roles` are approved automatically.
* In the cloud this is enforced by the database, not just the screen (file 11 below).

## Payroll print in the company design
The Summarized Salary Report now prints on the company letterhead (full-page photo, logo and
copyright footer in the same places as the requisition) with the headings and table laid out as in
the company's May 2026 report: SLUM2SCHOOL AFRICA, SUMMARIZED SALARY REPORT FOR MAY 2026,
FULL-TIME STAFF, then S/N, STAFF NAME, DESIGNATION, ACCOUNT NO., BANK NAME, AMOUNT and the
TOTAL box at the bottom right. Positions were measured from that report (within about 1 mm).
Amounts, proration and categories are still worked out by the portal exactly as before. A long
list continues on the next letterhead page with the headings repeated.

## Attendance: who sees clock-ins, and automatic reports
* HR, the Executive Director (and Finance) see every member of staff's clock-in and clock-out
  under Attendance: Today, Monthly Summary, Charts and Table.
* New **Attendance > Reports** tab. The latest completed week and month are built automatically,
  and HR / ED get a notice when a new one is ready. Pick any other week or month, then **Print / Save PDF**
  (company letterhead and table design) or **Download for Excel**.
  Weekly: each day's first clock-in and last clock-out, days present, late, total hours.
  Monthly: days present, working days, absent, late, average clock-in, total and average hours.

## Show / hide password
Every password box (sign in, admin sign in, register, new password) has an eye icon.

## Offline
The app shell, libraries, PDF reader and the requisition print fonts are cached on first
visit, so the portal opens with no network. Requisitions, memos, invoices (kept on the device),
printing, attendance and sign-in for known accounts work offline and sync when the phone
is back online. Registering a new account needs a connection, because HR approval is in the cloud.

## Setting up the cloud (2 steps, once, in the Supabase SQL Editor)
1. `supabase/10_v613_company_requisition.sql` so requisitions and invoices follow staff across devices.
2. `supabase/11_v613_account_approval.sql` to switch on HR approval. Run it **after** 01 and 07.
   Until it is run, everybody counts as approved.
Without them everything still works on the device that raised the requisition.

## Release markers
Build comment, `S2S_VERSION`/`S2S_BUILD`, the loaded banner and the service worker cache
(`s2s-portal-v6_13_0`) are all 6.13.0 / 2026-11-07. Hard-refresh once after deploying.
