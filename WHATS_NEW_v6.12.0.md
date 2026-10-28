# S2S People Portal v6.12.0 - 28 October 2026

## Deploy
1. Run `supabase/09_v612_departments_insurance.sql` in the Supabase SQL editor (after `08`). Safe to run again.
2. Upload the new `index.html` and `sw.js`, then hard-refresh (Ctrl+Shift+R).

## Outsourced staff and who is on the insurance
- **Staff record > Employer & insurance.** Choose "Slum2School Africa" or "Another company (outsourced)", enter the company name (for example Amala Security, Crystalclean), and tick whether the person is on the **NSITF schedule** and the **Group Life schedule**. Choosing "Another company" switches both off, because that company insures them; you can still switch either back on.
- **Payroll > Statutory & insurance schedules > "Who is insured".** One table of everyone on payroll, with the employer, company and two tick boxes. Changes save at once. Search, and "All / None" buttons for each schedule.
- The NSITF and Group Life schedules (print and CSV) now list only the people who are ticked, with a footnote naming who was left off and which company insures them. Payroll itself is unchanged: they are still paid.
- Amala Security and NFSS Security are marked as outsourced automatically. Mark any other outsourced person (security, cleaning and similar) in the "Who is insured" tab.

## Departments
The seven departments are now the way staff are grouped:
External Relations and Partnerships, Finance, Admin Procurement and Logistics, Program Management, Media and Communication, Human Resource, Growth and Sustainability.
- Staff record: **Department** (a list of the seven) and **Also works in** for people who span two (Hauwa is in External Relations and Partnerships and in Growth and Sustainability).
- The roster has been sorted by the names you gave. Anyone not yet placed shows as **Unassigned**; set their department in their staff record.
- Staff register: a count for each department (tap one to filter), the department in each row, and an Outsourced badge with the company name.
- **Payroll > By department** prints the payroll grouped by department, with a department summary and total.
- The NSITF and Group Life schedules carry a Department column and a department summary.
- People in two departments are costed under their main department only, so nothing is counted twice.