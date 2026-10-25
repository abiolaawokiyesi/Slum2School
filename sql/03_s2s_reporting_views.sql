-- ============================================================================
--  Slum2School Africa — S2S People Portal
--  03 · REPORTING VIEWS  (PostgreSQL)
--
--  These views feed two dashboards:
--    • v_admin_dashboard  → the HR / Admin panel
--    • v_ed_dashboard     → the Executive Director's dashboard
--  plus the attendance, payroll and requisition breakdowns they drill into.
--
--  Late threshold = clock-in after 09:00 (matches the portal rule).
-- ============================================================================

BEGIN;

-- ---- Attendance: one row per staff per day, classified ---------------------
CREATE OR REPLACE VIEW v_attendance_daily AS
SELECT a.work_date,
       a.staff_id,
       s.full_name,
       s.department,
       s.category,
       a.clock_in,
       a.clock_out,
       a.worked_minutes,
       ROUND(a.worked_minutes / 60.0, 2) AS worked_hours,
       CASE
           WHEN a.clock_in IS NULL                       THEN 'Absent'
           WHEN a.clock_in::time > TIME '09:00'          THEN 'Late'
           ELSE 'Present'
       END AS status,
       a.verified_id
FROM attendance a
JOIN staff s ON s.staff_id = a.staff_id;

-- ---- Attendance: today's board (every active staff, present or not) --------
CREATE OR REPLACE VIEW v_attendance_today AS
SELECT s.staff_id,
       s.full_name,
       s.department,
       s.category,
       a.clock_in,
       a.clock_out,
       a.worked_minutes,
       CASE
           WHEN a.clock_in  IS NULL THEN 'Absent / Not tracked'
           WHEN a.clock_out IS NULL THEN 'Working'
           ELSE 'Present'
       END AS today_status
FROM staff s
LEFT JOIN attendance a
       ON a.staff_id = s.staff_id AND a.work_date = CURRENT_DATE
WHERE s.status <> 'Resigned';

-- ---- Attendance: per-staff monthly summary ---------------------------------
CREATE OR REPLACE VIEW v_attendance_monthly_summary AS
SELECT to_char(a.work_date,'YYYY-MM')                                   AS month,
       s.staff_id,
       s.full_name,
       s.department,
       COUNT(*) FILTER (WHERE a.clock_in IS NOT NULL)                   AS days_present,
       COUNT(*) FILTER (WHERE a.clock_in::time > TIME '09:00')          AS late_days,
       COUNT(*) FILTER (WHERE a.clock_out IS NULL
                          AND a.clock_in IS NOT NULL)                   AS missing_clockout,
       ROUND(COALESCE(SUM(a.worked_minutes),0) / 60.0, 1)              AS total_hours
FROM attendance a
JOIN staff s ON s.staff_id = a.staff_id
GROUP BY 1,2,3,4;

-- ---- Attendance: department roll-up for today ------------------------------
CREATE OR REPLACE VIEW v_department_attendance_today AS
SELECT department,
       COUNT(*)                                                          AS headcount,
       COUNT(*) FILTER (WHERE today_status IN ('Present','Working'))     AS present,
       COUNT(*) FILTER (WHERE today_status LIKE 'Absent%')               AS absent,
       ROUND(100.0 * COUNT(*) FILTER (WHERE today_status IN ('Present','Working'))
             / NULLIF(COUNT(*),0), 1)                                    AS present_pct
FROM v_attendance_today
GROUP BY department
ORDER BY department;

-- ---- Attendance: organisation-wide rate per day (ED trend) -----------------
CREATE OR REPLACE VIEW v_org_attendance_daily AS
SELECT d.work_date,
       COUNT(*) FILTER (WHERE d.status = 'Present')                      AS present,
       COUNT(*) FILTER (WHERE d.status = 'Late')                         AS late,
       (SELECT COUNT(*) FROM staff WHERE status <> 'Resigned')           AS headcount,
       ROUND(100.0 * COUNT(*) FILTER (WHERE d.status IN ('Present','Late'))
             / NULLIF((SELECT COUNT(*) FROM staff WHERE status <> 'Resigned'),0), 1)
                                                                         AS attendance_pct
FROM v_attendance_daily d
GROUP BY d.work_date
ORDER BY d.work_date DESC;

-- ---- Payroll: per-run summary ---------------------------------------------
CREATE OR REPLACE VIEW v_payroll_summary AS
SELECT id AS run_id, period, period_month, run_by, staff_count,
       gross_total, deduction_total, net_total, run_at
FROM payroll_runs
ORDER BY run_at DESC;

-- ---- Payroll: current register straight from salaries + rates --------------
CREATE OR REPLACE VIEW v_payroll_register_current AS
SELECT s.staff_id,
       s.full_name,
       s.role,
       s.category,
       sal.gross,
       ROUND(sal.gross * r.paye    / 100, 2)                            AS paye,
       ROUND(sal.gross * r.pension / 100, 2)                            AS pension,
       ROUND(sal.gross * r.nhf     / 100, 2)                            AS nhf,
       ROUND(sal.gross * r.other   / 100, 2) + sal.other_fixed          AS other,
       sal.gross
         - (ROUND(sal.gross * (r.paye + r.pension + r.nhf + r.other) / 100, 2)
            + sal.other_fixed)                                          AS net
FROM staff s
JOIN salaries sal ON sal.staff_id = s.staff_id
CROSS JOIN pay_rates r
WHERE s.status <> 'Resigned'
ORDER BY s.category, s.full_name;

-- ---- Requisitions: approval queue -----------------------------------------
CREATE OR REPLACE VIEW v_requisitions_pending AS
SELECT r.id, r.subject, r.amount, r.requester_name, r.designation,
       r.method, r.status, r.created_at
FROM requisitions r
WHERE r.status = 'Pending'
ORDER BY r.created_at DESC;

-- ---- Requisitions: monthly spend ------------------------------------------
CREATE OR REPLACE VIEW v_requisition_monthly_spend AS
SELECT to_char(created_at,'YYYY-MM')  AS month,
       COUNT(*)                       AS requisitions,
       SUM(amount)                    AS total_amount,
       SUM(amount) FILTER (WHERE status IN ('Approved','Paid')) AS approved_amount
FROM requisitions
GROUP BY 1
ORDER BY 1 DESC;

-- ============================================================================
--  DASHBOARD ROLL-UPS
-- ============================================================================

-- ---- HR / Admin dashboard (single row of KPIs) ----------------------------
CREATE OR REPLACE VIEW v_admin_dashboard AS
SELECT
  (SELECT COUNT(*) FROM staff WHERE status <> 'Resigned')                       AS headcount,
  (SELECT COUNT(*) FROM v_attendance_today WHERE today_status IN ('Present','Working')) AS present_today,
  (SELECT COUNT(*) FROM v_attendance_today WHERE today_status LIKE 'Absent%')   AS absent_today,
  (SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE today_status IN ('Present','Working'))
          / NULLIF(COUNT(*),0),1) FROM v_attendance_today)                      AS attendance_pct_today,
  (SELECT COUNT(*) FROM requisitions WHERE status = 'Pending')                  AS pending_requisitions,
  (SELECT COALESCE(SUM(amount),0) FROM requisitions WHERE status = 'Pending')   AS pending_req_amount,
  (SELECT COUNT(*) FROM leave_requests WHERE status = 'Pending')                AS pending_leave,
  (SELECT COALESCE(SUM(gross),0) FROM salaries)                                 AS monthly_payroll_gross;

-- ---- Executive Director dashboard (organisation health) -------------------
CREATE OR REPLACE VIEW v_ed_dashboard AS
SELECT
  (SELECT COUNT(*) FROM staff WHERE status <> 'Resigned')                       AS total_staff,
  (SELECT COUNT(*) FROM staff WHERE category = 'Full-Time' AND status <> 'Resigned') AS core_staff,
  (SELECT COUNT(*) FROM v_attendance_today WHERE today_status IN ('Present','Working')) AS present_today,
  (SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE today_status IN ('Present','Working'))
          / NULLIF(COUNT(*),0),1) FROM v_attendance_today)                      AS attendance_pct_today,
  (SELECT COALESCE(SUM(gross),0) FROM salaries)                                 AS monthly_payroll_gross,
  (SELECT net_total FROM payroll_runs ORDER BY run_at DESC LIMIT 1)             AS last_run_net,
  (SELECT period    FROM payroll_runs ORDER BY run_at DESC LIMIT 1)             AS last_run_period,
  (SELECT COUNT(*) FROM requisitions WHERE status = 'Pending')                  AS pending_requisitions,
  (SELECT COALESCE(SUM(amount),0) FROM requisitions WHERE status = 'Pending')   AS pending_req_amount,
  (SELECT COUNT(*) FROM leave_requests WHERE status = 'Pending')                AS pending_leave;

COMMIT;
