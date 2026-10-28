# S2S People Portal v6.11.0 - 28 October 2026

Adds the records needed for NSITF, Group Life and Occupiers' Liability registration, and a working-day option for part-month pay.

## Deploy
1. Run `supabase/08_v611_compliance.sql` in the Supabase SQL editor (after `07`). Safe to run again.
2. Upload the new `index.html` and `sw.js`, then hard-refresh (Ctrl+Shift+R).

## Payroll: Statutory & insurance schedules (new card under the staff register)
- **NSITF payroll schedule (Form ECS RE03).** One row per employee: staff ID, name, designation, date of employment, basic, housing, transport, other allowances, benefits, gross pay, employee pension, NHF, PAYE, other deductions and net pay, with totals for the whole payroll. A summary shows the number of employees, total monthly payroll, the NSITF contribution (1% of total monthly payroll by default), PAYE, employee and employer pension. Print (landscape, with signature lines) or export to CSV. It uses the saved payroll run for the month, or a projection if payroll has not been run.
- **Group Life.** Employees, date of birth, date of employment, monthly gross, annual total emolument and sum assured (3 x annual total emolument by default; based on basic + housing + transport, or on gross pay). Print or export to CSV.
- **Occupiers' liability.** A premises register built from your office locations, with use of premises, floor area, staff based and average daily visitors. Print or export to CSV.

## Salary breakdown
Staff record > Salary breakdown: basic, housing, transport, other allowances and benefits. When filled, gross pay becomes the total. When left empty, the default split in Rates & settings is used (50% basic, 25% housing, 25% transport). Payslips now list the earnings lines. The payroll CSV carries the same columns.
Staff record > Date of birth is new (insurers ask for it).

## Part-month pay by working days
- The Payroll page has a new selector next to the month: **Pro-rate: calendar days / working days / 30-day month**.
- Working days exclude weekends and public holidays. Working week is Monday to Friday, or Monday to Saturday in Rates & settings.
- Public holidays are editable in Rates & settings. Fixed-date 2026 holidays are pre-filled; **add Eid and any other holidays once announced**.
- The proration dialog shows calendar days and working days side by side.

## Things to confirm
- NSITF: 1% of total monthly payroll is the rate on NSITF's website; change it in Rates & settings if your registration says otherwise. Check the layout against the current form when you register.
- Group Life: 3 x annual total emolument is the statutory minimum in the Pension Reform Act 2014 (section 4(5)). Confirm the earnings definition with your insurer.
- Employment dates: the seeded roster has month and year only (for example "Jun 2026"). Enter exact dates in each staff record before filing.