-- ════════════════════════════════════════════════════════════════════════════
--  S2S People Portal — v6.10.0 database migration
--  SUPABASE · 07 · cross-device sign-in · HR / ED visibility · salary proration
--
--  Run in the Supabase SQL editor AFTER 01 … 05. Safe to run more than once.
--
--  What this fixes
--  1. HR and the Executive Director could not see staff clock-ins.
--     Access was decided by free-text job titles typed at registration, so an
--     ED who registered as "Management" had no access. Access is now decided
--     by a small table (public.access_roles) that HR controls, plus the job
--     title taken from the staff roster — never from what a person types.
--  2. New accounts were created without a link to the staff roster, so payslips
--     and the HR attendance board could not match people. A profile is now
--     built from the roster record whose email matches the login email.
--  3. Staff can no longer promote themselves. Before this, any signed-in
--     person could update their own profile row (including user_type and role)
--     and, for example, open Payroll. The profile guard below stops that, and
--     registration no longer trusts the user_type / role / staff_id a browser
--     sends.
--  4. Email confirmation no longer blocks staff. Company addresses (and any
--     address on the roster) are confirmed automatically, so nobody is stuck
--     waiting for a confirmation email to sign in on a second device.
--  5. Salary proration: columns and a table to keep start / last-working-day,
--     the proration basis, and one-period adjustments.
-- ════════════════════════════════════════════════════════════════════════════

create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- ── 1 ── who may see staff activity ────────────────────────────────────────
create table if not exists public.access_roles (
    email       citext primary key,
    access      text not null check (access in ('hr','ed','finance','admin')),
    note        text,
    created_at  timestamptz default now()
);
alter table public.access_roles enable row level security;

-- HR, the ED and Finance. Add every address each person may sign in with.
insert into public.access_roles (email, access, note) values
  ('abiola.awokiyesi@slum2school.org', 'hr',      'HR & Volunteer Engagement Manager'),
  ('otto.orondaam@slum2school.org',    'ed',      'Executive Director'),
  ('otto.harmony@slum2school.org',     'ed',      'Executive Director (roster address)'),
  ('hammed.balogun@slum2school.org',   'finance', 'Finance Manager'),
  ('balogun.olanrewaju@slum2school.org','finance','Finance Manager (roster address)')
on conflict (email) do update set access = excluded.access, note = excluded.note;

-- ── 2 ── helper functions (security definer, so they work inside RLS) ───────
create or replace function public.has_access(p_levels text[]) returns boolean
    language sql stable security definer set search_path = public as $$
    select exists (
        select 1
          from public.access_roles ar
          join public.profiles p on lower(p.email) = lower(ar.email::text)
         where p.id = auth.uid() and ar.access = any (p_levels));
$$;

create or replace function public.is_superadmin() returns boolean
    language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.profiles where id = auth.uid() and user_type = 'superadmin')
        or public.has_access(array['hr']);
$$;

-- HR, Super Admin, Admin and the ED see all staff activity.
create or replace function public.is_admin() returns boolean
    language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.profiles where id = auth.uid() and user_type in ('superadmin','admin'))
        or public.has_access(array['hr','ed','admin']);
$$;

-- Payroll: HR, the ED and Finance. The job-title test now only reads the title
-- copied from the staff roster (profiles.role), never the department a person
-- picked on the registration form.
create or replace function public.can_view_payroll() returns boolean
    language sql stable security definer set search_path = public as $$
    select exists (
        select 1 from public.profiles p
         where p.id = auth.uid()
           and ( p.user_type = 'superadmin'
              or p.role ~* 'human\s*resource|(^|[^a-z])hr([^a-z]|$)|executive\s*director|finance' ))
        or public.has_access(array['hr','ed','finance']);
$$;

-- ── 3 ── profiles are built from the roster, and cannot be self-promoted ────
create or replace function public.s2s_make_profile(p_id uuid, p_email text, p_meta jsonb) returns void
    language plpgsql security definer set search_path = public as $$
declare s public.staff; v_type text;
begin
    select * into s from public.staff where lower(email) = lower(p_email) limit 1;
    v_type := case when coalesce(p_meta->>'user_type','') = 'volunteer' then 'volunteer' else 'employee' end;
    if exists (select 1 from public.access_roles where lower(email::text) = lower(p_email) and access = 'hr') then
        v_type := 'superadmin';
    elsif exists (select 1 from public.access_roles where lower(email::text) = lower(p_email) and access = 'admin') then
        v_type := 'admin';
    end if;
    insert into public.profiles (id, email, first_name, last_name, user_type, role, department, staff_id, phone, location)
    values (p_id, lower(p_email),
            coalesce(p_meta->>'first_name',''), coalesce(p_meta->>'last_name',''),
            v_type,
            coalesce(s.role, ''),                         -- job title comes from the roster only
            coalesce(nullif(p_meta->>'department',''), ''),
            s.staff_id,                                   -- linked by email, never typed in
            p_meta->>'phone', p_meta->>'location')
    on conflict (id) do nothing;
end $$;

create or replace function public.handle_new_user() returns trigger
    language plpgsql security definer set search_path = public as $$
begin
    perform public.s2s_make_profile(new.id, new.email, coalesce(new.raw_user_meta_data, '{}'::jsonb));
    return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Called by the app when a signed-in user has no profile row yet.
create or replace function public.ensure_my_profile() returns public.profiles
    language plpgsql security definer set search_path = public, auth as $$
declare p public.profiles; u auth.users;
begin
    if auth.uid() is null then return null; end if;
    select * into p from public.profiles where id = auth.uid();
    if found then return p; end if;
    select * into u from auth.users where id = auth.uid();
    if not found then return null; end if;
    perform public.s2s_make_profile(u.id, u.email, coalesce(u.raw_user_meta_data, '{}'::jsonb));
    select * into p from public.profiles where id = auth.uid();
    return p;
end $$;

-- Profile guard: only the Super Admin can change user_type, role, staff_id, email.
create or replace function public.profiles_guard() returns trigger
    language plpgsql security definer set search_path = public as $$
begin
    if coalesce(current_setting('s2s.bypass_guard', true), '') = '1' then return new; end if;
    if auth.uid() is null then return new; end if;            -- SQL editor / service role
    if not public.is_superadmin() then
        new.user_type := old.user_type;
        new.role      := old.role;
        new.staff_id  := old.staff_id;
        new.email     := old.email;
    end if;
    new.updated_at := now();
    return new;
end $$;

drop trigger if exists profiles_guard on public.profiles;
create trigger profiles_guard before update on public.profiles
    for each row execute function public.profiles_guard();

-- Browsers never insert profiles directly any more (the trigger / RPC do it).
drop policy if exists profiles_insert on public.profiles;
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
    for update using (id = auth.uid() or public.is_superadmin())
               with check (id = auth.uid() or public.is_superadmin());

alter table public.profiles add column if not exists must_change_password boolean default false;

drop policy if exists profiles_delete on public.profiles;
create policy profiles_delete on public.profiles for delete using (public.is_superadmin());

-- Keep a person's profile in step with the roster when HR edits the roster.
create or replace function public.sync_profile_from_staff() returns trigger
    language plpgsql security definer set search_path = public as $$
begin
    if new.email is null or new.email = '' then return new; end if;
    perform set_config('s2s.bypass_guard', '1', true);
    update public.profiles p
       set role     = coalesce(nullif(new.role, ''), p.role),
           staff_id = new.staff_id
     where lower(p.email) = lower(new.email);
    return new;
end $$;

drop trigger if exists staff_sync_profile on public.staff;
create trigger staff_sync_profile after insert or update of email, role, staff_id on public.staff
    for each row execute function public.sync_profile_from_staff();

-- Super Admin tool used by the Admin Panel: change type / title / staff link.
create or replace function public.admin_set_profile(
    p_email text, p_user_type text default null, p_role text default null, p_staff_id text default null)
    returns public.profiles
    language plpgsql security definer set search_path = public as $$
declare p public.profiles;
begin
    if not public.is_superadmin() then
        raise exception 'Only the Super Admin can change accounts' using errcode = '42501';
    end if;
    if p_user_type is not null and p_user_type not in ('superadmin','admin','employee','volunteer') then
        raise exception 'Unknown user type %', p_user_type;
    end if;
    perform set_config('s2s.bypass_guard', '1', true);
    update public.profiles
       set user_type = coalesce(p_user_type, user_type),
           role      = coalesce(p_role, role),
           staff_id  = coalesce(p_staff_id, staff_id)
     where lower(email) = lower(p_email)
     returning * into p;
    return p;
end $$;

-- access_roles: you can read your own row; only the Super Admin changes them.
drop policy if exists access_select on public.access_roles;
create policy access_select on public.access_roles
    for select using (auth.uid() is not null and (lower(email::text) = lower(coalesce(public.my_email(), '')) or public.is_superadmin()));
drop policy if exists access_write on public.access_roles;
create policy access_write on public.access_roles
    for all using (public.is_superadmin()) with check (public.is_superadmin());

-- ── 4 ── real login emails for the three leadership accounts ────────────────
-- The seed roster used guessed addresses. These two are the real ones; HR
-- should correct every other person's address in Payroll → Staff register.
update public.staff set email = 'otto.orondaam@slum2school.org'  where staff_id = 'S26001';
update public.staff set email = 'hammed.balogun@slum2school.org' where staff_id = 'S26008';

-- Re-link profiles that already exist (sets the roster title and staff id).
do $$
declare s record;
begin
    perform set_config('s2s.bypass_guard', '1', true);
    for s in select * from public.staff where email is not null and email <> '' loop
        update public.profiles p
           set role = coalesce(nullif(s.role, ''), p.role), staff_id = s.staff_id
         where lower(p.email) = lower(s.email);
    end loop;
    update public.profiles p set user_type = 'superadmin'
     where exists (select 1 from public.access_roles a where lower(a.email::text) = lower(p.email) and a.access = 'hr');
end $$;

-- ── 5 ── no more "check your inbox" dead ends ───────────────────────────────
-- Company addresses and addresses on the roster are confirmed on sign-up, so a
-- member of staff can sign in on a second device straight away.
create or replace function public.auto_confirm_staff_email() returns trigger
    language plpgsql security definer set search_path = public, auth as $$
begin
    if new.email_confirmed_at is null
       and ( new.email ilike '%@slum2school.org'
          or exists (select 1 from public.staff s where lower(s.email) = lower(new.email)) ) then
        new.email_confirmed_at := now();
    end if;
    return new;
end $$;

drop trigger if exists auto_confirm_staff_email on auth.users;
create trigger auto_confirm_staff_email before insert on auth.users
    for each row execute function public.auto_confirm_staff_email();

-- Confirm anyone who is already waiting on that email.
update auth.users u set email_confirmed_at = now()
 where u.email_confirmed_at is null
   and ( u.email ilike '%@slum2school.org'
      or exists (select 1 from public.staff s where lower(s.email) = lower(u.email)) );

-- ── 6 ── HR can pre-create accounts (optional) ──────────────────────────────
-- Use for anyone who cannot register themselves. They sign in with the temporary
-- password and the portal makes them choose their own on first sign-in.
create or replace function public.create_staff_user(p_email text, p_password text, p_meta jsonb)
returns uuid language plpgsql security definer set search_path = auth, public as $$
declare uid uuid;
begin
    select id into uid from auth.users where lower(email) = lower(p_email);
    if uid is not null then
        update auth.users
           set raw_user_meta_data = coalesce(p_meta, raw_user_meta_data),
               encrypted_password = crypt(p_password, gen_salt('bf')),
               email_confirmed_at = coalesce(email_confirmed_at, now()),
               updated_at         = now()
         where id = uid;
        return uid;
    end if;
    uid := gen_random_uuid();
    insert into auth.users
        (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
         raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
         confirmation_token, recovery_token, email_change_token_new, email_change)
    values
        ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', lower(p_email),
         crypt(p_password, gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}'::jsonb, coalesce(p_meta, '{}'::jsonb), now(), now(),
         '', '', '', '');
    insert into auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), uid::text, uid,
            jsonb_build_object('sub', uid::text, 'email', lower(p_email)), 'email', now(), now(), now());
    return uid;
end $$;

-- Example (one person):
--   select public.provision_staff_account('name@slum2school.org', 'Temp-Pass-2026', 'First', 'Last');
create or replace function public.provision_staff_account(
    p_email text, p_password text, p_first text default '', p_last text default '')
returns uuid language plpgsql security definer set search_path = public, auth as $$
declare uid uuid;
begin
    uid := public.create_staff_user(p_email, p_password,
             jsonb_build_object('first_name', p_first, 'last_name', p_last, 'user_type', 'employee'));
    perform set_config('s2s.bypass_guard', '1', true);
    update public.profiles set must_change_password = true where id = uid;
    return uid;
end $$;

-- ── 7 ── salary proration ───────────────────────────────────────────────────
alter table public.staff     add column if not exists end_date text;         -- last working day (ISO date), optional
alter table public.pay_rates add column if not exists prorate_basis text default 'calendar';
alter table public.payslips  add column if not exists gross_full     numeric(14,2);
alter table public.payslips  add column if not exists days_payable   numeric(6,2);
alter table public.payslips  add column if not exists days_in_period numeric(6,2);
alter table public.payslips  add column if not exists prorate_factor numeric(8,6);
alter table public.payslips  add column if not exists prorate_note   text;

create table if not exists public.pay_adjustments (
    id           bigint generated always as identity primary key,
    period       text not null,                  -- e.g. 'October 2026'
    staff_id     text not null,
    days_payable numeric(6,2),                   -- null = let the portal work it out
    unpaid_days  numeric(6,2) default 0,
    note         text,
    updated_by   text,
    updated_at   timestamptz default now(),
    unique (period, staff_id)
);
alter table public.pay_adjustments enable row level security;
drop policy if exists payadj_all on public.pay_adjustments;
create policy payadj_all on public.pay_adjustments
    for all using (public.can_view_payroll()) with check (public.can_view_payroll());

-- ── 8 ── grants + realtime ──────────────────────────────────────────────────
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
grant execute on all functions in schema public to anon, authenticated;
-- the provisioning helpers must never be callable from a browser
revoke execute on function public.create_staff_user(text, text, jsonb)            from public, anon, authenticated;
revoke execute on function public.provision_staff_account(text, text, text, text) from public, anon, authenticated;
revoke execute on function public.s2s_make_profile(uuid, text, jsonb)             from public, anon, authenticated;

do $$
begin
    begin execute 'alter publication supabase_realtime add table public.pay_adjustments'; exception when others then null; end;
end $$;

-- ── 9 ── check ──────────────────────────────────────────────────────────────
-- select email, user_type, role, staff_id from public.profiles order by created_at;
-- select * from public.access_roles;
-- select count(*) as clockins_visible_to_me from public.attendance;   -- run while signed in as HR / ED in the app's SQL
