# S2S People Portal — v6.8 (28 July 2026)

Version badge in the app now reads **S2S Portal v6.8 · 28 Jul 2026**. If you still see 6.7
after deploying, do one hard refresh (Ctrl+Shift+R / Cmd+Shift+R) — the service-worker cache
name was bumped to `s2s-portal-v6_8`, so one refresh is all it takes.

---

## 1. Headquarters location corrected

HQ is now pinned to **6.443385, 3.476079** with a 200 m geofence, marked as calibrated.
This is applied in three places so nothing is left stale: the app's office list, the Supabase
seed (`supabase/02_seed.sql`) and the reference React/Express integration files.

Existing installs pick the new pin up automatically — the migration key was bumped from
`s2s_offices_v3` to `s2s_offices_v4`, which forces the correction onto phones that already
cached the old coordinates.

**GPS accuracy also improved.** Clock-in and "Pin this office to where I am" no longer take
the first fix the phone offers. They now sample continuously for up to 10 seconds and keep the
most accurate reading, stopping early once the phone reports better than 15 m. The reading's
accuracy figure is shown to the user, so a bad fix is visible rather than silent.

## 2. Four levels of signatories

Every memo and requisition now prints signature columns in this order:

1. **1st signatory** — the person raising the requisition
2. **2nd signatory** — the line manager *(optional — only appears if a name is entered)*
3. **Finance Manager** — Hammed Balogun
4. **Executive Director** — Otto Orondaam

Leave the line-manager field blank and the block collapses cleanly to three columns. Fill it in
(e.g. Mojet raising a requisition puts Lois in as line manager) and all four print, each labelled
with its position in the chain.

## 3. Scholar memo & requisition template

The requisition page now has a **template selector**: *Standard* or *Scholars*.

The scholar template prints a "Scholars Payment Schedule" with the columns you specified —
Last name, First name, Institution, Course of study, Account number, Bank name, Account name,
Total cost — and a totals row.

Scholars can be added one at a time, or **pasted straight out of Excel or Google Sheets**
(Paste a scholar list → paste → Import rows). Tab-separated or comma-separated both work.
The total cost column sums itself.

## 4. Bulk expense breakdown

The standard template's expense breakdown now handles the messy real cases:

- **Multiple people** — each line can carry its own beneficiary
- **Multiple vendors** — lines are grouped and sub-totalled per vendor when a vendor is named
- **Multiple description lines for one vendor** — as many rows as you need under one vendor
- **Quantity × unit rate** — enter quantity and rate and the amount calculates itself; or type an
  amount directly and it is used as-is

## 5. Everything sums itself

The expense breakdown (or the scholar schedule, whichever template is active) is now the single
source of truth. Its total flows automatically into **Amount requested (₦)** and into
**amount in words** — both fields update as you type and neither can drift out of step with the
table any more.

## 6. Background covers the whole printed page

The print engine was rebuilt. The page margin is now zero and the letterhead background is a
fixed full-bleed layer, so **the artwork reaches all four paper edges on every page** — page 1,
page 5, and every page in between. Verified by rendering a 5-page scholar requisition and a
3-page payroll to PDF and probing the corner pixels: no white anywhere.

## 7. No text on the footer design

Rather than hoping text stops in time, each printed page now reserves a **26 mm band at the
bottom and 17 mm at the top that content structurally cannot enter**. Body text, tables and
signature blocks are physically unable to spill into the footer artwork, including on
continuation pages. Verified by comparing the footer band of every page against page 1 —
pixel-identical on all of them, i.e. nothing intruded.

## 8. Staff directory is editable, and salaries now actually flow into payroll

This was the bug behind "a new staff was added but her salary did not add up".

There is now a **Staff register** card on the Payroll page (admin / HR / ED / Finance only).
From it an admin can:

- **Add a new staff member** — name, role, department, payroll category, status, start date,
  work email, account number, bank, gross salary and fixed deductions, all in one form
- **Edit any existing staff member** — every one of those fields
- **Remove a staff member**

The critical fix: **saving a staff record now writes the salary at the same moment**. Gross and
deductions are stored against the staff ID as part of the save, so a newly added person appears
in the payroll register with PAYE, pension, NHF and net pay already calculated. No second step,
nothing to remember.

## 9. Print payroll for any month of any year

The Payroll page header now has a **month and year picker** next to the Print payroll button.

When you run payroll, the result is snapshotted and kept. Printing a past month reprints that
saved run exactly as it was — the printout says *"Saved payroll run of &lt;date&gt;"*. If no run was
ever saved for that month, it prints a projection from today's salary register and says so
plainly on the page, so nobody mistakes an estimate for history.

## 10. Staff statuses you control

A **Statuses** manager lets an admin add, remove and assign statuses. It ships with Active,
Probation, On Leave, Suspended, Resigned, Retired, Terminated and Contract Ended, and you can
add your own (Sabbatical, Secondment, whatever you need).

Each status carries an **"Off payroll"** tick. Anyone on a status marked off-payroll is removed
automatically from the payroll register, the payroll run and the printed payroll — so marking
someone Resigned takes them off the payroll in the same action, with no separate cleanup.

---

## Files in this release

| File | What it is |
|---|---|
| `index.html` | The whole app — single file, v6.8 |
| `sw.js` | Service worker (cache `s2s-portal-v6_8`) |
| `icon-192.png`, `icon-512.png` | App icons for install-to-home-screen |
| `supabase/01_schema.sql` … `04_accounts.sql` | Database schema, seed, views, pre-created accounts |
| `supabase/README_SUPABASE.md` | How to run the SQL and connect the app |
| `reference-integrations/` | React Native / React / Express / SQL reference code for the mobile build |
| `DEPLOY_AND_TROUBLESHOOT.md` | Deploying, and what to do if a change doesn't appear |
