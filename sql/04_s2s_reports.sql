-- ============================================================================
--  Slum2School Africa — S2S People Portal
--  04 · READY-TO-RUN REPORTS
--  Run these against the loaded database (psql -f 04_s2s_reports.sql).
-- ============================================================================

\echo '=== HR / ADMIN DASHBOARD ==='
SELECT * FROM v_admin_dashboard;

\echo '=== EXECUTIVE DIRECTOR DASHBOARD ==='
SELECT * FROM v_ed_dashboard;

\echo '=== TODAY: ATTENDANCE BY DEPARTMENT ==='
SELECT * FROM v_department_attendance_today;

\echo '=== ATTENDANCE: 5 most recent days, org-wide rate ==='
SELECT * FROM v_org_attendance_daily LIMIT 5;

\echo '=== ATTENDANCE: monthly summary per staff (top 15 by hours) ==='
SELECT month, full_name, department, days_present, late_days, total_hours
FROM v_attendance_monthly_summary
ORDER BY total_hours DESC
LIMIT 15;

\echo '=== ATTENDANCE: staff who were late most often this month ==='
SELECT full_name, department, late_days, days_present
FROM v_attendance_monthly_summary
WHERE late_days > 0
ORDER BY late_days DESC;

\echo '=== PAYROLL: current register (first 15 rows) ==='
SELECT full_name, role, category, gross, paye, pension, nhf, other, net
FROM v_payroll_register_current
LIMIT 15;

\echo '=== PAYROLL: totals by staff category ==='
SELECT s.category,
       COUNT(*)      AS staff,
       SUM(sal.gross) AS monthly_gross
FROM staff s JOIN salaries sal ON sal.staff_id = s.staff_id
WHERE s.status <> 'Resigned'
GROUP BY s.category
ORDER BY monthly_gross DESC;

\echo '=== PAYROLL: organisation grand total (should read 8,315,000) ==='
SELECT SUM(gross) AS total_monthly_payroll FROM salaries;

\echo '=== REQUISITIONS: pending approval queue ==='
SELECT id, subject, amount, requester_name, status, created_at::date AS raised
FROM v_requisitions_pending;

\echo '=== REQUISITIONS: full detail with line items ==='
SELECT r.subject, r.amount, ri.sn, ri.description, ri.amount AS line_amount, ri.account_details
FROM requisitions r
JOIN requisition_items ri ON ri.requisition_id = r.id
ORDER BY r.created_at DESC, ri.sn;

\echo '=== REQUISITIONS: spend by month ==='
SELECT * FROM v_requisition_monthly_spend;
