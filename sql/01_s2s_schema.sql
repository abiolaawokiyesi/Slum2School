-- ============================================================================
--  Slum2School Africa — S2S People Portal
--  01 · DATABASE SCHEMA  (PostgreSQL 13+)
--
--  Purpose: persistent backend for the S2S People Portal so that ALL staff
--  attendance and records are saved centrally and can be reported in the
--  Admin (HR) dashboard and the Executive Director (ED) dashboard.
--
--  The app currently stores data in the browser (localStorage keys:
--  s2s_kv_staff, s2s_kv_salaries, s2s_kv_att_records, s2s_kv_payslips,
--  s2s_kv_requisitions, s2s_kv_audit ...). These tables mirror that model
--  1:1 so the portal can POST its records here for permanent storage.
--
--  Load order:  01_s2s_schema.sql  →  02_s2s_seed.sql  →  03_s2s_reporting_views.sql
--  Run reports: 04_s2s_reports.sql
-- ============================================================================

BEGIN;

-- ---- Clean rebuild (safe to re-run) --------------------------------------
DROP VIEW  IF EXISTS v_ed_dashboard, v_admin_dashboard,
                     v_org_attendance_daily, v_department_attendance_today,
                     v_attendance_today, v_attendance_daily,
                     v_attendance_monthly_summary,
                     v_payroll_summary, v_payroll_register_current,
                     v_requisitions_pending, v_requisition_monthly_spend CASCADE;
DROP TABLE IF EXISTS audit_log, leave_requests, requisition_items, requisitions,
                     payslips, payroll_runs, attendance, salaries, pay_rates,
                     staff, app_users, departments CASCADE;

-- ---- Reference: departments ----------------------------------------------
CREATE TABLE departments (
    id          SERIAL PRIMARY KEY,
    name        TEXT UNIQUE NOT NULL,
    lead_email  TEXT
);

-- ---- Portal accounts (login) ---------------------------------------------
CREATE TABLE app_users (
    email        TEXT PRIMARY KEY,
    first_name   TEXT,
    last_name    TEXT,
    user_type    TEXT NOT NULL DEFAULT 'employee'
                 CHECK (user_type IN ('superadmin','admin','employee','volunteer')),
    role         TEXT,                 -- job title / designation
    department   TEXT,
    staff_id     TEXT UNIQUE,
    phone        TEXT,
    location     TEXT,
    start_month  TEXT,
    supervisor   TEXT,
    is_active    BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- Only HR, the Executive Director and the Finance Manager may see Payroll.
-- This mirrors canViewPayroll() in the portal and is enforced again here.
CREATE OR REPLACE FUNCTION can_view_payroll(p_email TEXT)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM app_users u
        WHERE u.email = p_email
          AND ( u.user_type = 'superadmin'
             OR u.role ~* 'human\s*resource|(^|[^a-z])hr([^a-z]|$)|executive\s*director|(^|[^a-z])ed([^a-z]|$)|finance'
             OR u.department ~* 'human\s*resource|finance' )
    );
$$;

-- ---- Staff roster (payroll + attendance subject) -------------------------
CREATE TABLE staff (
    staff_id    TEXT PRIMARY KEY,
    full_name   TEXT NOT NULL,
    role        TEXT,
    department  TEXT,
    category    TEXT CHECK (category IN ('Full-Time','Contract','Auxiliary','School')),
    status      TEXT DEFAULT 'Active',          -- Active | Probation | Resigned
    start_date  TEXT,
    email       TEXT REFERENCES app_users(email) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- ---- Payroll deduction rates (organisation-wide singleton) ---------------
CREATE TABLE pay_rates (
    id         INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    paye       NUMERIC(6,3) DEFAULT 0,   -- percentages
    pension    NUMERIC(6,3) DEFAULT 0,
    nhf        NUMERIC(6,3) DEFAULT 0,
    other      NUMERIC(6,3) DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ---- Monthly salary per staff --------------------------------------------
CREATE TABLE salaries (
    staff_id       TEXT PRIMARY KEY REFERENCES staff(staff_id) ON DELETE CASCADE,
    gross          NUMERIC(14,2) NOT NULL DEFAULT 0,
    other_fixed    NUMERIC(14,2) NOT NULL DEFAULT 0,
    effective_from DATE DEFAULT CURRENT_DATE,
    updated_at     TIMESTAMPTZ DEFAULT now()
);

-- ---- Attendance (GPS + Work-ID verified clock in / out) ------------------
CREATE TABLE attendance (
    id            BIGSERIAL PRIMARY KEY,
    staff_id      TEXT REFERENCES staff(staff_id) ON DELETE CASCADE,
    email         TEXT,
    name          TEXT,
    department    TEXT,
    work_date     DATE NOT NULL,
    clock_in      TIMESTAMPTZ,
    clock_out     TIMESTAMPTZ,
    lat           DOUBLE PRECISION,
    lng           DOUBLE PRECISION,
    verified_id   BOOLEAN DEFAULT FALSE,
    source        TEXT DEFAULT 'portal',
    worked_minutes INTEGER GENERATED ALWAYS AS (
        CASE WHEN clock_in IS NOT NULL AND clock_out IS NOT NULL
             THEN (EXTRACT(EPOCH FROM (clock_out - clock_in)) / 60)::INT END
    ) STORED,
    created_at    TIMESTAMPTZ DEFAULT now(),
    UNIQUE (staff_id, work_date)
);
CREATE INDEX idx_attendance_date  ON attendance(work_date);
CREATE INDEX idx_attendance_staff ON attendance(staff_id);

-- ---- Payroll runs & payslips ---------------------------------------------
CREATE TABLE payroll_runs (
    id              BIGSERIAL PRIMARY KEY,
    period          TEXT NOT NULL,                 -- e.g. 'June 2026'
    period_month    DATE,                          -- first day of month
    run_by          TEXT,
    staff_count     INT,
    gross_total     NUMERIC(16,2),
    deduction_total NUMERIC(16,2),
    net_total       NUMERIC(16,2),
    run_at          TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE payslips (
    id               BIGSERIAL PRIMARY KEY,
    run_id           BIGINT REFERENCES payroll_runs(id) ON DELETE CASCADE,
    staff_id         TEXT REFERENCES staff(staff_id) ON DELETE CASCADE,
    period           TEXT NOT NULL,
    gross            NUMERIC(14,2),
    paye             NUMERIC(14,2),
    pension          NUMERIC(14,2),
    nhf              NUMERIC(14,2),
    other            NUMERIC(14,2),
    total_deductions NUMERIC(14,2),
    net              NUMERIC(14,2),
    created_at       TIMESTAMPTZ DEFAULT now(),
    UNIQUE (staff_id, period)
);

-- ---- Requisition & memo (raised by ANY staff member) ---------------------
CREATE TABLE requisitions (
    id                 TEXT PRIMARY KEY,           -- 'REQ<epoch>'
    subject            TEXT,
    addressed_to       TEXT DEFAULT 'Hammed Balogun',
    through            TEXT DEFAULT 'The Executive Director',
    background         TEXT,
    purpose            TEXT,
    method             TEXT,                        -- Fund Transfer | Cash | Cheque | Bank Draft
    method_detail      TEXT,
    amount             NUMERIC(14,2),
    amount_words       TEXT,
    requester_email    TEXT,
    requester_name     TEXT,
    designation        TEXT,
    status             TEXT DEFAULT 'Pending'
                       CHECK (status IN ('Pending','Approved by Finance','Approved','Rejected','Paid')),
    finance_approved_by TEXT,
    ed_approved_by      TEXT,
    created_at         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE requisition_items (
    id               BIGSERIAL PRIMARY KEY,
    requisition_id   TEXT REFERENCES requisitions(id) ON DELETE CASCADE,
    sn               INT,
    description      TEXT,
    amount           NUMERIC(14,2),
    account_details  TEXT
);
CREATE INDEX idx_req_status    ON requisitions(status);
CREATE INDEX idx_req_requester ON requisitions(requester_email);

-- ---- Leave requests -------------------------------------------------------
CREATE TABLE leave_requests (
    id         BIGSERIAL PRIMARY KEY,
    email      TEXT,
    name       TEXT,
    role       TEXT,
    leave_type TEXT,
    start_date DATE,
    end_date   DATE,
    days       INT,
    reason     TEXT,
    status     TEXT DEFAULT 'Pending' CHECK (status IN ('Pending','Approved','Rejected')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ---- Audit trail ----------------------------------------------------------
CREATE TABLE audit_log (
    id        BIGSERIAL PRIMARY KEY,
    ts        TIMESTAMPTZ DEFAULT now(),
    who_email TEXT,
    who_name  TEXT,
    action    TEXT,
    target    TEXT,
    old_value JSONB,
    new_value JSONB
);

COMMIT;
