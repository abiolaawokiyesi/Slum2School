# S2S People Portal v6.10.0 - 25 October 2026

Three things were fixed or added in this release.

1. Staff can now sign in from any device.
2. HR and the Executive Director can now see every clock-in and clock-out.
3. Salary proration (part-month pay) is now built into payroll.

## Before you deploy - two steps, in this order

1. **Run `supabase/07_v610_login_visibility_proration.sql`** in the Supabase SQL editor (Run once; it is safe to run again).
2. **Upload the new `index.html` and `sw.js`**, then hard-refresh each device (Ctrl+Shift+R, or clear the site data on phones) so the new service worker takes over.

Also in Supabase: **Authentication > Providers > Email > turn "Confirm email" OFF.** The SQL already confirms every @slum2school.org address and every roster address automatically, but switching it off removes the last chance of someone waiting for an email.

Do not run `01_schema.sql` again after `07` without running `07` again afterwards, because `01` puts back the older rules.

## 1. Sign-in from different devices

**Cause.** Accounts used to be created on the phone or laptop where the person registered, and the login fell back to that device's own storage whenever the cloud refused or was slow. A second device had never heard of the account, and the first device had no real cloud session, so its clock-ins never reached the database.

**Fix.**
- Sign-in now goes to the cloud first, on every device.
- An account that only exists on one device is moved to the cloud the next time that person signs in there with their password.
- Only a one-way hash is kept on the device, for signing back in while offline.
- If a device is online but has no cloud session, the app signs the person out and asks them to sign in again, instead of silently losing their clock-ins.
- Registration is blocked while the cloud is unreachable, so no more device-only accounts are created.
- Added "Forgot password" that returns to the portal, a "resend confirmation" link, a first-sign-in "choose a new password" box for accounts HR provisions, and a fallback to a second CDN if the first fails to load.

## 2. HR and the ED can see staff activity

**Cause.** Who could see attendance was decided by the job title a person typed when registering. An ED who typed "Management" had no access. The attendance tabs were also limited to Admin-type accounts.

**Fix.**
- A new table, `access_roles`, lists who is HR, ED, Finance or Admin by email. It starts with Abiola (HR), Otto Orondaam (ED) and Hammed Balogun (Finance). The Admin Panel can add or remove people.
- The job title now comes from the staff roster, matched on email, not from the registration form.
- The "Today - All Staff", "Monthly Summary" and "Charts & Table" tabs show for HR, ED, Finance and Admin.
- The board has a live status bar (refreshes every 45 seconds and when the screen is reopened), and a "Cloud check" panel that shows why anything is missing.
- Clock-ins are matched to the roster by email, staff ID or name. Anyone who clocked in but cannot be matched is listed separately, so nothing is hidden.
- Every punch (in, out, in again) is stored with its time, place and distance. Anything that failed to upload is kept on the phone and resent automatically.

**Security fix found on the way.** In the earlier version any signed-in person could change their own role and open Payroll. A guard on the database now stops anyone but HR from changing a user type, job title, staff ID or email, and registration no longer trusts what the browser sends.

**What HR must do once.** The seed roster contains guessed email addresses for most staff. Open Payroll > Staff register and put each person's real login email against their record. Until then that person's clock-ins will still appear, but under "clocked in, not matched".

## 3. Salary proration

Pay for a part month = salary x days payable / days in the month. PAYE, pension, NHF and fixed deductions follow the same factor.

- **Start date** mid-month: pay from that day.
- **Last working day** (new field on the staff record): pay up to that day. The person stays on the payroll for that month even if their status is already changed to left.
- **Approved unpaid leave** (leave type "Unpaid"): those days are deducted automatically.
- **Manual adjustment** (the % button beside a name in Payroll): set the exact days to pay, or unpaid days, with a reason that prints on the payslip. It applies to that month only.
- **Basis** (Payroll > Deduction rates): calendar days (default), working days Monday to Friday, or a fixed 30-day month.
- Payroll table, payslip, printed payroll and CSV all show full salary, days paid, factor and the reason.
- Running payroll again for a month asks you to confirm and replaces that month's payslips.
- Bug fixed: the previous payroll run did not send its payslips to the cloud correctly.

**Please confirm:** the default basis is calendar days. If S2S pays on working days or a fixed 30 days, change it once in Deduction rates.

## Files in this release

- `index.html`, `sw.js` - the app
- `supabase/07_v610_login_visibility_proration.sql` - the database update
- `supabase/README_SUPABASE.md` - updated set-up guide
