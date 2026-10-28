-- ============================================================================
--  Slum2School Africa — S2S People Portal
--  SUPABASE · 01 · SCHEMA + AUTH + ROW-LEVEL SECURITY
--
--  Paste this into the Supabase SQL Editor (or `supabase db push`) FIRST.
--  Then run 02_seed.sql and 03_views.sql.
--
--  What it does:
--   • profiles table linked 1:1 to auth.users (created automatically on sign-up)
--   • all record tables (staff, salaries, attendance, payroll, requisitions, leave)
--   • Row-Level Security so:
--        – any signed-in staff member can raise requisitions & clock attendance
--        – ONLY HR, the Executive Director and the Finance Manager see Payroll
--        – people see their own records; admins/ED see everything for dashboards
--   • realtime enabled on attendance & requisitions so dashboards live-update
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- ---------------------------------------------------------------------------
-- 1. PROFILES  (one row per auth user)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
    id          uuid primary key references auth.users(id) on delete cascade,
    email       text,
    first_name  text,
    last_name   text,
    user_type   text not null default 'employee'
                check (user_type in ('superadmin','admin','employee','volunteer')),
    role        text,                 -- job title / designation
    department  text,
    staff_id    text,
    phone       text,
    location    text,
    supervisor  text,
    bio         text,
    created_at  timestamptz default now(),
    updated_at  timestamptz default now()
);

-- ---------------------------------------------------------------------------
-- 2. HELPER FUNCTIONS  (security definer → usable inside RLS policies safely)
-- ---------------------------------------------------------------------------
create or replace function public.my_email() returns text
    language sql stable security definer set search_path = public as $$
    select email from public.profiles where id = auth.uid();
$$;

create or replace function public.my_staff_id() returns text
    language sql stable security definer set search_path = public as $$
    select staff_id from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin() returns boolean
    language sql stable security definer set search_path = public as $$
    select exists (
        select 1 from public.profiles
        where id = auth.uid() and user_type in ('superadmin','admin')
    );
$$;

-- Payroll is limited to HR, the Executive Director and the Finance Manager.
create or replace function public.can_view_payroll() returns boolean
    language sql stable security definer set search_path = public as $$
    select exists (
        select 1 from public.profiles p
        where p.id = auth.uid()
          and ( p.user_type = 'superadmin'
             or p.role       ~* 'human\s*resource|(^|[^a-z])hr([^a-z]|$)|executive\s*director|(^|[^a-z])ed([^a-z]|$)|finance'
             or p.department ~* 'human\s*resource|finance' )
    );
$$;

-- ---------------------------------------------------------------------------
-- 3. Auto-create a profile whenever a user signs up
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user() returns trigger
    language plpgsql security definer set search_path = public as $$
begin
    insert into public.profiles (id, email, first_name, last_name, user_type, role, department, staff_id, phone, location)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'first_name',''),
        coalesce(new.raw_user_meta_data->>'last_name',''),
        coalesce(new.raw_user_meta_data->>'user_type','employee'),
        coalesce(new.raw_user_meta_data->>'role',''),
        coalesce(new.raw_user_meta_data->>'department',''),
        nullif(new.raw_user_meta_data->>'staff_id',''),
        new.raw_user_meta_data->>'phone',
        new.raw_user_meta_data->>'location'
    )
    on conflict (id) do nothing;
    return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 4. RECORD TABLES
-- ---------------------------------------------------------------------------
create table if not exists public.staff (
    staff_id    text primary key,
    full_name   text not null,
    role        text,
    department  text,
    category    text check (category in ('Full-Time','Contract','Auxiliary','School')),
    status      text default 'Active',
    start_date  text,
    email       text,
    account_no  text,
    bank_name   text,
    created_at  timestamptz default now()
);
-- (idempotent) add banking columns if the table already existed
alter table public.staff add column if not exists account_no text;
alter table public.staff add column if not exists bank_name  text;

-- ---- Office locations (multi-site geofence) -------------------------------
create table if not exists public.offices (
    id         text primary key,
    name       text not null,
    address    text,
    lat        double precision not null,
    lng        double precision not null,
    radius     integer default 100,          -- geofence radius in metres (0.1km)
    calibrated boolean default false,        -- true once pinned on-site via GPS
    updated_at timestamptz default now()
);

-- ---- Notice board / announcements -----------------------------------------
create table if not exists public.announcements (
    id               text primary key,
    title            text not null,
    message          text,
    audience_type    text default 'everyone' check (audience_type in ('everyone','admins','department')),
    audience_value   text,
    urgency          text default 'Normal' check (urgency in ('Normal','Important','Urgent')),
    theme            text,
    responsibilities jsonb default '[]'::jsonb,
    poster_email     text,
    poster_name      text,
    created_at       timestamptz default now()
);
create index if not exists idx_ann_created on public.announcements(created_at desc);

create table if not exists public.pay_rates (
    id         int primary key default 1 check (id = 1),
    paye       numeric(6,3) default 0,
    pension    numeric(6,3) default 0,
    nhf        numeric(6,3) default 0,
    other      numeric(6,3) default 0,
    updated_at timestamptz default now()
);

create table if not exists public.salaries (
    staff_id       text primary key references public.staff(staff_id) on delete cascade,
    gross          numeric(14,2) not null default 0,
    other_fixed    numeric(14,2) not null default 0,
    effective_from date default current_date,
    updated_at     timestamptz default now()
);

-- staff_id kept as plain text (no FK) so ANY signed-in user can clock in,
-- whether or not they are on the seeded roster yet.
create table if not exists public.attendance (
    id             bigint generated always as identity primary key,
    staff_id       text,
    email          text,
    name           text,
    department     text,
    work_date      date not null,
    clock_in       timestamptz,
    clock_out      timestamptz,
    lat            double precision,
    lng            double precision,
    accuracy       double precision,
    location_id    text,
    location_name  text,
    verified_id    boolean default false,
    source         text default 'portal',
    worked_minutes integer generated always as (
        case when clock_in is not null and clock_out is not null
             then (extract(epoch from (clock_out - clock_in)) / 60)::int end
    ) stored,
    created_at     timestamptz default now(),
    unique (email, work_date)
);
create index if not exists idx_attendance_date  on public.attendance(work_date);
create index if not exists idx_attendance_email on public.attendance(email);
-- (idempotent) attendance location columns if the table already existed
alter table public.attendance add column if not exists accuracy      double precision;
alter table public.attendance add column if not exists location_id   text;
alter table public.attendance add column if not exists location_name text;

create table if not exists public.payroll_runs (
    id              bigint generated always as identity primary key,
    period          text not null,
    period_month    date,
    run_by          text,
    staff_count     int,
    gross_total     numeric(16,2),
    deduction_total numeric(16,2),
    net_total       numeric(16,2),
    run_at          timestamptz default now()
);

create table if not exists public.payslips (
    id               bigint generated always as identity primary key,
    run_id           bigint references public.payroll_runs(id) on delete set null,
    staff_id         text,
    period           text not null,
    gross            numeric(14,2),
    paye             numeric(14,2),
    pension          numeric(14,2),
    nhf              numeric(14,2),
    other            numeric(14,2),
    total_deductions numeric(14,2),
    net              numeric(14,2),
    created_at       timestamptz default now(),
    unique (staff_id, period)
);

create table if not exists public.requisitions (
    id                  text primary key,
    doc_date            text,          -- memo date as shown on the printed letter
    on_behalf           text,          -- "For" — raise a requisition on behalf of someone
    subject             text,
    addressed_to        text default 'Hammed Balogun',
    through             text default 'The Executive Director',
    background          text,
    purpose             text,
    method              text,
    method_detail       text,
    amount              numeric(14,2),
    amount_words        text,
    requester_email     text,
    requester_name      text,
    designation         text,
    status              text default 'Pending'
                        check (status in ('Pending','Approved by Finance','Approved','Rejected','Paid')),
    finance_approved_by text,
    ed_approved_by      text,
    created_at          timestamptz default now()
);

create table if not exists public.requisition_items (
    id              bigint generated always as identity primary key,
    requisition_id  text references public.requisitions(id) on delete cascade,
    sn              int,
    description     text,
    unit            text,           -- unit / quantity (e.g. "2 pcs", "3 months")
    amount          numeric(14,2),
    account_details text
);
create index if not exists idx_req_status    on public.requisitions(status);
create index if not exists idx_req_requester on public.requisitions(requester_email);
-- (idempotent) new columns if the tables already existed
alter table public.requisitions      add column if not exists on_behalf text;
alter table public.requisition_items add column if not exists unit      text;

create table if not exists public.leave_requests (
    id         bigint generated always as identity primary key,
    email      text,
    name       text,
    role       text,
    leave_type text,
    start_date date,
    end_date   date,
    days       int,
    reason     text,
    status     text default 'Pending' check (status in ('Pending','Approved','Rejected')),
    created_at timestamptz default now()
);

create table if not exists public.audit_log (
    id        bigint generated always as identity primary key,
    ts        timestamptz default now(),
    who_email text,
    who_name  text,
    action    text,
    target    text,
    old_value jsonb,
    new_value jsonb
);

-- ---------------------------------------------------------------------------
-- 5. ENABLE ROW-LEVEL SECURITY
-- ---------------------------------------------------------------------------
alter table public.profiles          enable row level security;
alter table public.staff             enable row level security;
alter table public.pay_rates         enable row level security;
alter table public.salaries          enable row level security;
alter table public.attendance        enable row level security;
alter table public.payroll_runs      enable row level security;
alter table public.payslips          enable row level security;
alter table public.requisitions      enable row level security;
alter table public.requisition_items enable row level security;
alter table public.leave_requests    enable row level security;
alter table public.audit_log         enable row level security;
alter table public.announcements     enable row level security;
alter table public.offices           enable row level security;

-- ---------------------------------------------------------------------------
-- 6. POLICIES
-- ---------------------------------------------------------------------------
-- PROFILES ------------------------------------------------------------------
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
    for select using (auth.uid() is not null);          -- staff directory
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles
    for insert with check (id = auth.uid());
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
    for update using (id = auth.uid() or public.is_admin())
               with check (id = auth.uid() or public.is_admin());
drop policy if exists profiles_delete on public.profiles;
create policy profiles_delete on public.profiles
    for delete using (public.is_admin());

-- STAFF (roster) ------------------------------------------------------------
drop policy if exists staff_select on public.staff;
create policy staff_select on public.staff
    for select using (auth.uid() is not null);
drop policy if exists staff_write on public.staff;
create policy staff_write on public.staff
    for all using (public.is_admin() or public.can_view_payroll())
            with check (public.is_admin() or public.can_view_payroll());

-- PAY RATES / SALARIES / PAYROLL RUNS  → payroll roles only -----------------
drop policy if exists rates_all on public.pay_rates;
create policy rates_all on public.pay_rates
    for all using (public.can_view_payroll()) with check (public.can_view_payroll());

drop policy if exists sal_all on public.salaries;
create policy sal_all on public.salaries
    for all using (public.can_view_payroll()) with check (public.can_view_payroll());

drop policy if exists runs_all on public.payroll_runs;
create policy runs_all on public.payroll_runs
    for all using (public.can_view_payroll()) with check (public.can_view_payroll());

-- PAYSLIPS  → your own, plus payroll roles see all --------------------------
drop policy if exists slip_select on public.payslips;
create policy slip_select on public.payslips
    for select using (public.can_view_payroll() or staff_id = public.my_staff_id());
drop policy if exists slip_write on public.payslips;
create policy slip_write on public.payslips
    for all using (public.can_view_payroll()) with check (public.can_view_payroll());

-- ATTENDANCE  → clock your own; admins/payroll roles see all ----------------
drop policy if exists att_select on public.attendance;
create policy att_select on public.attendance
    for select using (email = public.my_email() or public.is_admin() or public.can_view_payroll());
drop policy if exists att_insert on public.attendance;
create policy att_insert on public.attendance
    for insert with check (email = public.my_email());
drop policy if exists att_update on public.attendance;
create policy att_update on public.attendance
    for update using (email = public.my_email() or public.is_admin())
               with check (email = public.my_email() or public.is_admin());

-- REQUISITIONS  → any staff raises; owner + payroll roles read; roles approve
drop policy if exists req_insert on public.requisitions;
create policy req_insert on public.requisitions
    for insert with check (requester_email = public.my_email());
drop policy if exists req_select on public.requisitions;
create policy req_select on public.requisitions
    for select using (requester_email = public.my_email() or public.is_admin() or public.can_view_payroll());
drop policy if exists req_update on public.requisitions;
create policy req_update on public.requisitions
    for update using (public.is_admin() or public.can_view_payroll()
                      or (requester_email = public.my_email() and status = 'Pending'))
               with check (public.is_admin() or public.can_view_payroll()
                      or requester_email = public.my_email());
drop policy if exists req_delete on public.requisitions;
create policy req_delete on public.requisitions
    for delete using (public.is_admin() or public.can_view_payroll()
                      or (requester_email = public.my_email() and status = 'Pending'));

-- REQUISITION ITEMS  → follow the parent requisition ------------------------
drop policy if exists reqitem_all on public.requisition_items;
create policy reqitem_all on public.requisition_items
    for all using (exists (
        select 1 from public.requisitions r
        where r.id = requisition_id
          and (r.requester_email = public.my_email() or public.is_admin() or public.can_view_payroll())))
    with check (exists (
        select 1 from public.requisitions r
        where r.id = requisition_id
          and (r.requester_email = public.my_email() or public.is_admin() or public.can_view_payroll())));

-- LEAVE  → own requests; admins see/approve all -----------------------------
drop policy if exists leave_insert on public.leave_requests;
create policy leave_insert on public.leave_requests
    for insert with check (email = public.my_email());
drop policy if exists leave_select on public.leave_requests;
create policy leave_select on public.leave_requests
    for select using (email = public.my_email() or public.is_admin());
drop policy if exists leave_update on public.leave_requests;
create policy leave_update on public.leave_requests
    for update using (public.is_admin()) with check (public.is_admin());

-- AUDIT LOG  → anyone writes their own line; admins read ---------------------
drop policy if exists audit_insert on public.audit_log;
create policy audit_insert on public.audit_log
    for insert with check (auth.uid() is not null);
drop policy if exists audit_select on public.audit_log;
create policy audit_select on public.audit_log
    for select using (public.is_admin());

-- ANNOUNCEMENTS  → any staff posts; visibility follows the chosen audience ---
drop policy if exists ann_insert on public.announcements;
create policy ann_insert on public.announcements
    for insert with check (poster_email = public.my_email());
drop policy if exists ann_select on public.announcements;
create policy ann_select on public.announcements
    for select using (
         audience_type = 'everyone'
      or poster_email  = public.my_email()
      or public.is_admin()
      or public.can_view_payroll()
      or (audience_type = 'admins'     and (public.is_admin() or public.can_view_payroll()))
      or (audience_type = 'department'  and audience_value =
              (select department from public.profiles where id = auth.uid())) );
drop policy if exists ann_update on public.announcements;
create policy ann_update on public.announcements
    for update using (poster_email = public.my_email() or public.is_admin())
               with check (poster_email = public.my_email() or public.is_admin());
drop policy if exists ann_delete on public.announcements;
create policy ann_delete on public.announcements
    for delete using (poster_email = public.my_email() or public.is_admin());

-- OFFICES  → everyone signed-in can read (to pick a location); admins manage ---
drop policy if exists offices_select on public.offices;
create policy offices_select on public.offices
    for select using (auth.uid() is not null);
drop policy if exists offices_write on public.offices;
create policy offices_write on public.offices
    for all using (public.is_admin() or public.can_view_payroll())
            with check (public.is_admin() or public.can_view_payroll());

-- ---------------------------------------------------------------------------
-- 7. GRANTS  (RLS still applies; grants just open the tables to the roles)
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
grant execute on all functions in schema public to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 8. REALTIME  (dashboards live-update on new clock-ins / requisitions)
-- ---------------------------------------------------------------------------
do $$
begin
    begin execute 'alter publication supabase_realtime add table public.attendance';        exception when others then null; end;
    begin execute 'alter publication supabase_realtime add table public.requisitions';       exception when others then null; end;
    begin execute 'alter publication supabase_realtime add table public.requisition_items';  exception when others then null; end;
    begin execute 'alter publication supabase_realtime add table public.payslips';           exception when others then null; end;
    begin execute 'alter publication supabase_realtime add table public.announcements';       exception when others then null; end;
    begin execute 'alter publication supabase_realtime add table public.offices';             exception when others then null; end;
end $$;
