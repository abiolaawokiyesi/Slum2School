-- ============================================================================
--  Slum2School Africa — S2S People Portal
--  SUPABASE · 03 · DASHBOARD VIEWS  (run AFTER 01_schema.sql and 02_seed.sql)
--
--  Views use security_invoker so Row-Level Security still applies:
--    • HR (Super Admin) and the Executive Director / Finance see org-wide figures
--    • an ordinary employee sees only what their policies allow
--  Feed the HR panel from v_admin_dashboard and the ED screen from v_ed_dashboard.
-- ============================================================================

-- ---- Attendance: one row per staff per day, classified --------------------
create or replace view public.v_attendance_daily
with (security_invoker = on) as
select a.work_date, a.staff_id, coalesce(s.full_name, a.name) as full_name,
       coalesce(s.department, a.department) as department, s.category,
       a.email, a.clock_in, a.clock_out, a.worked_minutes,
       round(a.worked_minutes / 60.0, 2) as worked_hours,
       case when a.clock_in is null              then 'Absent'
            when a.clock_in::time > time '09:00'  then 'Late'
            else 'Present' end as status
from public.attendance a
left join public.staff s on s.staff_id = a.staff_id;

-- ---- Attendance: today's board (every active staff) -----------------------
create or replace view public.v_attendance_today
with (security_invoker = on) as
select s.staff_id, s.full_name, s.department, s.category,
       a.clock_in, a.clock_out, a.worked_minutes,
       case when a.clock_in  is null then 'Absent / Not tracked'
            when a.clock_out is null then 'Working'
            else 'Present' end as today_status
from public.staff s
left join public.attendance a
       on a.staff_id = s.staff_id and a.work_date = current_date
where s.status <> 'Resigned';

-- ---- Attendance: per-staff monthly summary --------------------------------
create or replace view public.v_attendance_monthly_summary
with (security_invoker = on) as
select to_char(a.work_date,'YYYY-MM') as month,
       a.staff_id, coalesce(s.full_name,a.name) as full_name,
       coalesce(s.department,a.department) as department,
       count(*) filter (where a.clock_in is not null)              as days_present,
       count(*) filter (where a.clock_in::time > time '09:00')     as late_days,
       round(coalesce(sum(a.worked_minutes),0)/60.0, 1)            as total_hours
from public.attendance a
left join public.staff s on s.staff_id = a.staff_id
group by 1,2,3,4;

-- ---- Attendance: department roll-up for today -----------------------------
create or replace view public.v_department_attendance_today
with (security_invoker = on) as
select department,
       count(*)                                                        as headcount,
       count(*) filter (where today_status in ('Present','Working'))   as present,
       count(*) filter (where today_status like 'Absent%')             as absent,
       round(100.0*count(*) filter (where today_status in ('Present','Working'))
             / nullif(count(*),0),1)                                   as present_pct
from public.v_attendance_today
group by department order by department;

-- ---- Attendance: organisation-wide daily rate (ED trend) ------------------
create or replace view public.v_org_attendance_daily
with (security_invoker = on) as
select d.work_date,
       count(*) filter (where d.status='Present') as present,
       count(*) filter (where d.status='Late')    as late,
       (select count(*) from public.staff where status <> 'Resigned') as headcount,
       round(100.0*count(*) filter (where d.status in ('Present','Late'))
             / nullif((select count(*) from public.staff where status <> 'Resigned'),0),1) as attendance_pct
from public.v_attendance_daily d
group by d.work_date order by d.work_date desc;

-- ---- Payroll: current register from salaries + rates ----------------------
create or replace view public.v_payroll_register_current
with (security_invoker = on) as
select s.staff_id, s.full_name, s.role, s.category, sal.gross,
       round(sal.gross * r.paye    /100,2)                 as paye,
       round(sal.gross * r.pension /100,2)                 as pension,
       round(sal.gross * r.nhf     /100,2)                 as nhf,
       round(sal.gross * r.other   /100,2) + sal.other_fixed as other,
       sal.gross - (round(sal.gross*(r.paye+r.pension+r.nhf+r.other)/100,2)+sal.other_fixed) as net
from public.staff s
join public.salaries sal on sal.staff_id = s.staff_id
cross join public.pay_rates r
where s.status <> 'Resigned'
order by s.category, s.full_name;

-- ---- Payroll: per-run summary ---------------------------------------------
create or replace view public.v_payroll_summary
with (security_invoker = on) as
select id as run_id, period, period_month, run_by, staff_count,
       gross_total, deduction_total, net_total, run_at
from public.payroll_runs order by run_at desc;

-- ---- Requisitions: approval queue -----------------------------------------
create or replace view public.v_requisitions_pending
with (security_invoker = on) as
select id, subject, amount, requester_name, designation, method, status, created_at
from public.requisitions where status = 'Pending'
order by created_at desc;

-- ---- Requisitions: monthly spend ------------------------------------------
create or replace view public.v_requisition_monthly_spend
with (security_invoker = on) as
select to_char(created_at,'YYYY-MM') as month, count(*) as requisitions,
       sum(amount) as total_amount,
       sum(amount) filter (where status in ('Approved','Paid')) as approved_amount
from public.requisitions group by 1 order by 1 desc;

-- ---- HR / Admin dashboard --------------------------------------------------
create or replace view public.v_admin_dashboard
with (security_invoker = on) as
select
  (select count(*) from public.staff where status <> 'Resigned')                              as headcount,
  (select count(*) from public.v_attendance_today where today_status in ('Present','Working')) as present_today,
  (select count(*) from public.v_attendance_today where today_status like 'Absent%')          as absent_today,
  (select round(100.0*count(*) filter (where today_status in ('Present','Working'))
          / nullif(count(*),0),1) from public.v_attendance_today)                              as attendance_pct_today,
  (select count(*) from public.requisitions where status='Pending')                            as pending_requisitions,
  (select coalesce(sum(amount),0) from public.requisitions where status='Pending')             as pending_req_amount,
  (select count(*) from public.leave_requests where status='Pending')                          as pending_leave,
  (select coalesce(sum(gross),0) from public.salaries)                                          as monthly_payroll_gross;

-- ---- Executive Director dashboard -----------------------------------------
create or replace view public.v_ed_dashboard
with (security_invoker = on) as
select
  (select count(*) from public.staff where status <> 'Resigned')                              as total_staff,
  (select count(*) from public.staff where category='Full-Time' and status <> 'Resigned')     as core_staff,
  (select count(*) from public.v_attendance_today where today_status in ('Present','Working')) as present_today,
  (select round(100.0*count(*) filter (where today_status in ('Present','Working'))
          / nullif(count(*),0),1) from public.v_attendance_today)                              as attendance_pct_today,
  (select coalesce(sum(gross),0) from public.salaries)                                          as monthly_payroll_gross,
  (select net_total from public.payroll_runs order by run_at desc limit 1)                      as last_run_net,
  (select period    from public.payroll_runs order by run_at desc limit 1)                      as last_run_period,
  (select count(*) from public.requisitions where status='Pending')                            as pending_requisitions,
  (select coalesce(sum(amount),0) from public.requisitions where status='Pending')             as pending_req_amount,
  (select count(*) from public.leave_requests where status='Pending')                          as pending_leave;

-- ---- Attendance grouped by office location (today) ------------------------
create or replace view public.v_attendance_by_location_today
with (security_invoker = on) as
select coalesce(a.location_name,'Unspecified') as office,
       count(*) filter (where a.clock_in is not null)  as clocked_in,
       round(avg(a.accuracy)::numeric,0)               as avg_gps_accuracy_m
from public.attendance a
where a.work_date = current_date
group by 1
order by clocked_in desc;

-- ---- Attendance, last 7 days, grouped by office (per shared reporting query) --
create or replace view public.v_attendance_last7_by_office
with (security_invoker = on) as
select a.work_date                                    as log_date,
       coalesce(a.location_id,'unspecified')          as office_id,
       coalesce(a.location_name,'Unspecified')        as office,
       count(distinct a.email)                        as total_staff_present,
       count(*) filter (where a.clock_in  is not null) as total_clock_ins,
       count(*) filter (where a.clock_out is not null) as total_clock_outs
from public.attendance a
where a.work_date >= current_date - interval '7 days'
group by 1,2,3
order by log_date desc, office_id;

grant select on all tables in schema public to authenticated;
