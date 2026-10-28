-- ════════════════════════════════════════════════════════════════════════════
--  S2S People Portal — v6.9 migration
--  Multiple clock-ins and clock-outs per day.
--
--  Run this in the Supabase SQL editor AFTER 01_schema.sql … 04_accounts.sql.
--  It is idempotent: running it twice is harmless.
--
--  Up to v6.8 a day was one row with one clock_in and one clock_out. From v6.9
--  a staff member can clock in and out as many times as they need, so the row
--  keeps the full punch list and the derived totals. clock_in / clock_out are
--  retained and now mean "first in" and "last out", so every existing report,
--  view and export keeps working unchanged.
-- ════════════════════════════════════════════════════════════════════════════

-- 1 ── new columns ──────────────────────────────────────────────────────────
alter table public.attendance add column if not exists punches  jsonb   default '[]'::jsonb;
alter table public.attendance add column if not exists sessions integer default 0;
alter table public.attendance add column if not exists minutes  integer default 0;

comment on column public.attendance.punches is
  'Ordered punch list for the day: [{t:ISO timestamp, dir:"in"|"out", lat, lng, acc, officeId, office}, ...]';
comment on column public.attendance.sessions is
  'Number of completed in→out pairs for the day';
comment on column public.attendance.minutes is
  'Total minutes worked across every session that day (open sessions excluded)';

-- 2 ── backfill existing rows from the old single-punch shape ───────────────
update public.attendance
   set punches = (
         case when clock_in is null then '[]'::jsonb
              else jsonb_build_array(jsonb_build_object('t', clock_in, 'dir', 'in'))
                   || case when clock_out is null then '[]'::jsonb
                           else jsonb_build_array(jsonb_build_object('t', clock_out, 'dir', 'out'))
                      end
         end),
       sessions = case when clock_in is not null and clock_out is not null then 1 else 0 end,
       minutes  = coalesce(worked_minutes, 0)
 where punches is null or punches = '[]'::jsonb;

-- 3 ── index for the dashboard charts ───────────────────────────────────────
create index if not exists idx_attendance_email_date
    on public.attendance (email, work_date desc);

-- 4 ── reporting view: one row per session, for charts and CSV exports ──────
-- cascade: attendance_daily / attendance_monthly are rebuilt below, and a
-- plain drop would fail on a re-run because they depend on this view.
drop view if exists public.attendance_sessions cascade;
create view public.attendance_sessions
with (security_invoker = on) as
with p as (
  select a.id, a.email, a.name, a.department, a.work_date,
         row_number() over (partition by a.id order by ord) as seq,
         (e ->> 'dir')                as dir,
         (e ->> 't')::timestamptz     as t,
         (e ->> 'office')             as office
    from public.attendance a,
         lateral jsonb_array_elements(coalesce(a.punches, '[]'::jsonb))
              with ordinality as x(e, ord)
),
paired as (
  select p.*, lead(t)   over (partition by id order by seq) as next_t,
              lead(dir) over (partition by id order by seq) as next_dir
    from p
)
select id            as attendance_id,
       email, name, department, work_date, office,
       t              as clock_in,
       next_t         as clock_out,
       case when next_dir = 'out' and next_t is not null
            then (extract(epoch from (next_t - t)) / 60)::int end as minutes
  from paired
 where dir = 'in';

comment on view public.attendance_sessions is
  'One row per in→out session. Feeds the HR / ED attendance charts and the CSV export.';

-- 5 ── daily rollup used by the dashboard tables ────────────────────────────
drop view if exists public.attendance_daily cascade;   -- attendance_monthly depends on it
create view public.attendance_daily
with (security_invoker = on) as
select email,
       max(name)       as name,
       max(department) as department,
       work_date,
       min(clock_in)   as first_in,
       max(clock_out)  as last_out,
       max(coalesce(sessions, 0)) as sessions,
       max(coalesce(minutes,  0)) as minutes,
       round(max(coalesce(minutes, 0)) / 60.0, 2) as hours,
       max(location_name) as office
  from public.attendance
 group by email, work_date;

comment on view public.attendance_daily is
  'One row per staff member per day, with session count and total hours.';

-- 6 ── monthly rollup ───────────────────────────────────────────────────────
drop view if exists public.attendance_monthly;
create view public.attendance_monthly
with (security_invoker = on) as
select email,
       max(name)       as name,
       max(department) as department,
       to_char(work_date, 'YYYY-MM')       as period,
       count(*)                            as days_present,
       sum(sessions)                       as total_sessions,
       sum(minutes)                        as total_minutes,
       round(sum(minutes) / 60.0, 2)       as total_hours,
       round(avg(minutes) / 60.0, 2)       as avg_hours_per_day
  from public.attendance_daily
 group by email, to_char(work_date, 'YYYY-MM');

comment on view public.attendance_monthly is
  'Per-staff monthly attendance summary for the HR and ED dashboards.';

-- 7 ── views run as the signed-in user (security_invoker), so Row-Level
--      Security still applies: a staff member sees only their own rows,
--      while HR / the ED / Finance see everyone. Then expose them. ───────
grant select on public.attendance_sessions to authenticated;
grant select on public.attendance_daily    to authenticated;
grant select on public.attendance_monthly  to authenticated;

-- ── done ───────────────────────────────────────────────────────────────────
-- Verify with:
--   select email, work_date, sessions, minutes, jsonb_array_length(punches) as punch_count
--     from public.attendance order by work_date desc limit 20;
