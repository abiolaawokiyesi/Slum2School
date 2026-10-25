# S2S People Portal — Integration Notes (v5)

This build integrates the **Requisition & Memo template** and the **S2S staff payroll** into the portal, restricts payroll access, embeds the letter-headed background into printed documents, and ships a **SQL backend** for attendance and records reporting.

## 1. What changed in the app (`index.html`)

**Payroll is now restricted.** Only three roles can open the Payroll module:
Human Resource Manager (Super Admin), the Executive Director, and the Finance Manager.
The rule lives in `canViewPayroll()` and matches a user's role/department against
`HR / Human Resource`, `Executive Director / ED`, and `Finance` (Super Admin always passes).
The Payroll link is hidden for everyone else, and navigating to it directly is blocked and
redirected to the dashboard.

**Payroll is pre-loaded with the June 2026 roster.** All 51 staff from the *Summarized Salary
Report* (Full-Time, Contract, Auxiliary and School staff) are seeded with their monthly figures.
The register totals **₦8,315,000**, matching the report. Deduction rates default to 0% (the report
is a flat payout); HR can change them under *Deduction rates*.

**New "Requisitions" module — open to every staff member.** Anyone can raise a payment
requisition + memo that mirrors the uploaded template: date, to/through, subject, background,
purpose, payment method, amount (with an automatic amount-in-words), and a line-by-line account
breakdown. Each is saved and listed under *My requisitions*; HR/Finance/ED see the full approval
queue.

**Print-ready output carries the letterhead + background.** Both the requisition/memo and the
payslip print through a branded document with the Slum2School logo, the faint children watermark,
and `print-color-adjust:exact` so the background renders in the final PDF/print. See
`S2S_Requisition_sample.pdf` for an example.

> The app stores data in the browser (localStorage). To make records permanent and reportable
> across users, point the portal at the SQL backend below.

## 2. SQL backend (`/sql`) — PostgreSQL 13+

| File | Purpose |
|------|---------|
| `01_s2s_schema.sql` | Tables: departments, app_users, staff, salaries, pay_rates, attendance, payroll_runs, payslips, requisitions, requisition_items, leave_requests, audit_log. Includes `can_view_payroll()` and a generated `worked_minutes` column. |
| `02_s2s_seed.sql` | Seeds the 51-person roster, salaries (₦8,315,000), the payroll accounts, sample attendance, and the CCTV requisition. |
| `03_s2s_reporting_views.sql` | Reporting views incl. **`v_admin_dashboard`** (HR) and **`v_ed_dashboard`** (Executive Director). |
| `04_s2s_reports.sql` | Ready-to-run reports. |

**Load & run:**

```bash
createdb s2s_portal
psql -d s2s_portal -f sql/01_s2s_schema.sql
psql -d s2s_portal -f sql/02_s2s_seed.sql
psql -d s2s_portal -f sql/03_s2s_reporting_views.sql
psql -d s2s_portal -f sql/04_s2s_reports.sql   # prints the dashboards
```

**Dashboards:** `SELECT * FROM v_admin_dashboard;` and `SELECT * FROM v_ed_dashboard;`
return headcount, present-today, attendance %, monthly payroll, pending requisitions and
pending leave. Attendance drill-downs: `v_attendance_today`, `v_attendance_daily`,
`v_attendance_monthly_summary`, `v_department_attendance_today`, `v_org_attendance_daily`.

## 3. Wiring the portal to the database (localStorage → tables)

| Portal store (localStorage) | Table |
|---|---|
| `s2s_kv_att_records` | `attendance` |
| `s2s_kv_staff` | `staff` |
| `s2s_kv_salaries` / `s2s_kv_payrates` | `salaries` / `pay_rates` |
| `s2s_kv_payslips` / `lastrun` | `payslips` / `payroll_runs` |
| `s2s_kv_requisitions` | `requisitions` + `requisition_items` |
| `s2s_kv_audit` | `audit_log` |

On each clock-in/out, payroll run, or requisition save, POST the same record to a small API that
inserts into the matching table (upsert on the natural keys already defined, e.g.
`attendance(staff_id, work_date)` and `payslips(staff_id, period)`). The Admin and ED dashboards
then read from the views above.
