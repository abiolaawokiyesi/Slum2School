-- ============================================================================
--  Slum2School Africa — S2S People Portal
--  SUPABASE · 06 · VERIFY THE INSTALL  +  LIVE ACTIVITY QUERIES
--
--  Run this LAST, after 01 → 05. It changes nothing: every statement is a
--  read. Part A tells you whether the database was built correctly. Part B is
--  a set of ready-made queries HR and the Executive Director can run in the
--  SQL editor to see what everyone is doing, without going through the app.
--
--  Run the whole file at once and read the results panel top to bottom, or
--  highlight a single query and press Run to see just that one.
-- ============================================================================


-- ════════════════════════════════════════════════════════════════════════════
--  PART A — DID EVERYTHING INSTALL?
-- ════════════════════════════════════════════════════════════════════════════

-- A1. All 13 tables present, with Row-Level Security switched on.
--     Expect 13 rows, every rls_enabled = true.
select c.relname                       as table_name,
       c.relrowsecurity                as rls_enabled,
       (select count(*) from pg_policies p
         where p.schemaname='public' and p.tablename=c.relname) as policies
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname='public' and c.relkind='r'
  and c.relname in ('profiles','staff','offices','announcements','pay_rates',
                    'salaries','attendance','payroll_runs','payslips',
                    'requisitions','requisition_items','leave_requests','audit_log')
order by c.relname;

-- A2. The four security helper functions the policies depend on.
--     Expect 4 rows.
select proname as function_name
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname='public'
  and proname in ('my_email','my_staff_id','is_admin','can_view_payroll')
order by proname;

-- A3. Did the seed load?  Expect roughly 51 staff and 51 salary rows.
select (select count(*) from public.staff)          as staff_rows,
       (select count(*) from public.salaries)       as salary_rows,
       (select count(*) from public.offices)        as office_locations,
       (select count(*) from public.pay_rates)      as pay_rate_rows;

-- A4. Did 05_attendance_punches.sql run?  Expect all three = true.
select
  (select count(*) from information_schema.columns
     where table_schema='public' and table_name='attendance'
       and column_name='punches')  = 1                      as multi_punch_ready,
  (select count(*) from information_schema.views
     where table_schema='public' and table_name='attendance_daily')   = 1 as daily_view_ready,
  (select count(*) from information_schema.views
     where table_schema='public' and table_name='attendance_monthly') = 1 as monthly_view_ready;

-- A5. Do the HR and ED dashboard views exist?  Expect both, plus the rest.
select table_name
from information_schema.views
where table_schema='public' and table_name like 'v\_%'
order by table_name;

-- A6. Were the three key accounts created, and do they have payroll access?
--     Expect 3 rows: HR as superadmin, ED and Finance as employee.
--     can_open_payroll must be true for all three.
select p.email, p.first_name || ' ' || p.last_name as name, p.user_type,
       p.role, p.department,
       ( p.user_type = 'superadmin'
         or p.role       ~* 'human\s*resource|(^|[^a-z])hr([^a-z]|$)|executive\s*director|(^|[^a-z])ed([^a-z]|$)|finance'
         or p.department ~* 'human\s*resource|finance' ) as can_open_payroll
from public.profiles p
where p.email in ('abiola.awokiyesi@slum2school.org',
                  'otto.orondaam@slum2school.org',
                  'hammed.balogun@slum2school.org')
order by p.user_type desc, p.email;

-- A7. Everyone who has actually registered so far, and what they can open.
select p.email, p.first_name || ' ' || p.last_name as name, p.role, p.user_type,
       case when p.user_type in ('superadmin','admin') then 'Full admin'
            when p.role ~* 'executive\s*director|finance'  then 'Payroll + org-wide'
            else 'Own records only' end                as access_level,
       p.created_at
from public.profiles p
order by p.created_at;

-- A8. Is realtime publishing on, so dashboards update without a reload?
--     Expect attendance, requisitions, requisition_items, payslips,
--     announcements and offices.
select tablename
from pg_publication_tables
where pubname = 'supabase_realtime' and schemaname = 'public'
order by tablename;


-- ════════════════════════════════════════════════════════════════════════════
--  PART B — WHAT IS EVERYONE DOING?   (HR / ED activity queries)
-- ════════════════════════════════════════════════════════════════════════════

-- B1. WHO IS AT WORK RIGHT NOW — the live board.
select full_name, department, category, clock_in, clock_out,
       round(worked_minutes/60.0, 2) as hours_so_far, today_status
from public.v_attendance_today
order by case today_status when 'Working' then 1 when 'Present' then 2 else 3 end,
         full_name;

-- B2. TODAY AT A GLANCE — the numbers on the HR dashboard.
select * from public.v_admin_dashboard;

-- B3. THE EXECUTIVE DIRECTOR'S SUMMARY.
select * from public.v_ed_dashboard;

-- B4. EVERY PUNCH TODAY, in order — who came and went, and when.
--     This is the multiple clock-in / clock-out detail from 05.
select name, email, office, clock_in, clock_out,
       round(minutes/60.0, 2) as hours
from public.attendance_sessions
where work_date = current_date
order by name, clock_in;

-- B4b. TODAY'S TOTALS PER PERSON — first in, last out, punches, hours.
select name, department, office, first_in, last_out, sessions, hours
from public.attendance_daily
where work_date = current_date
order by first_in;

-- B5. THIS MONTH, PER STAFF MEMBER — days present, sessions, total hours.
select name, department, days_present, total_sessions,
       total_hours, avg_hours_per_day
from public.attendance_monthly
where period = to_char(current_date, 'YYYY-MM')
order by total_hours desc nulls last;

-- B6. LAST 30 DAYS, DAY BY DAY — the organisation-wide attendance trend.
select work_date, present, late, headcount, attendance_pct
from public.v_org_attendance_daily
where work_date >= current_date - interval '30 days'
order by work_date desc;

-- B7. ATTENDANCE BY DEPARTMENT, TODAY.
select * from public.v_department_attendance_today;

-- B8. WHICH OFFICE PEOPLE CLOCKED IN FROM TODAY, and how good the GPS was.
select * from public.v_attendance_by_location_today;

-- B9. ANYONE WHO HAS NOT CLOCKED IN TODAY — the follow-up list.
select s.staff_id, s.full_name, s.department, s.role
from public.staff s
where s.status <> 'Resigned'
  and not exists (select 1 from public.attendance a
                   where a.email = s.email and a.work_date = current_date)
order by s.department, s.full_name;

-- B10. LATE ARRIVALS THIS MONTH — after 09:00.
select full_name, department, count(*) as late_days,
       min(clock_in) as earliest_late, max(clock_in) as latest_late
from public.v_attendance_daily
where status = 'Late'
  and to_char(work_date,'YYYY-MM') = to_char(current_date,'YYYY-MM')
group by full_name, department
order by late_days desc;

-- B11. REQUISITIONS WAITING FOR APPROVAL.
select id, created_at::date as raised_on, requester_name, designation,
       subject, amount, method, status
from public.requisitions
where status = 'Pending'
order by created_at desc;

-- B12. EVERY REQUISITION RAISED IN THE LAST 90 DAYS, newest first.
select r.id, r.created_at::date as raised_on, r.requester_name, r.subject,
       r.amount, r.status,
       (select count(*) from public.requisition_items i where i.requisition_id = r.id) as line_items
from public.requisitions r
where r.created_at >= current_date - interval '90 days'
order by r.created_at desc;

-- B13. REQUISITION SPEND BY MONTH.
select * from public.v_requisition_monthly_spend;

-- B14. WHO RAISES THE MOST, AND FOR HOW MUCH — last 90 days.
select requester_name, designation, count(*) as requisitions,
       sum(amount) as total_requested,
       sum(amount) filter (where status in ('Approved','Paid')) as approved
from public.requisitions
where created_at >= current_date - interval '90 days'
group by requester_name, designation
order by total_requested desc;

-- B15. LEAVE REQUESTS AWAITING A DECISION.
select id, name, email, leave_type, start_date, end_date, days, status, created_at::date
from public.leave_requests
where status = 'Pending'
order by start_date;

-- B16. NOTICES POSTED, and who they went to.
select created_at::date as posted_on, poster_name, title, urgency,
       audience_type, audience_value
from public.announcements
order by created_at desc
limit 50;

-- B17. THE AUDIT TRAIL — who changed what, last 200 actions. (HR only.)
select ts, who_name, who_email, action, target, old_value, new_value
from public.audit_log
order by ts desc
limit 200;

-- B18. THE PAYROLL REGISTER AS IT STANDS. (HR / ED / Finance only.)
select category, full_name, role, gross, paye, pension, nhf, other, net
from public.v_payroll_register_current
order by category, full_name;

-- ============================================================================
--  Reading the results
--  ---------------------------------------------------------------------------
--  Part A should show 13 tables with RLS on, 4 helper functions, ~51 staff,
--  three true flags for the punch upgrade, the v_ dashboard views, and the
--  three key accounts with can_open_payroll = true. Anything missing points at
--  a file that did not finish — re-run that one file; all of them are safe to
--  run twice.
--
--  Part B run here in the SQL editor shows the raw data. The same information
--  reaches HR and the ED inside the portal automatically once the app is
--  connected — Dashboard, and Attendance → Charts & Table.
-- ============================================================================
