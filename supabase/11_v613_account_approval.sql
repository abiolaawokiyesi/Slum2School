-- ============================================================================
-- S2S People Portal v6.13.0 - HR approves every new account
-- Run once in Supabase: SQL Editor -> New query -> paste -> Run. Safe to re-run.
--
-- After this file:
--   * everyone who already has an account stays approved;
--   * anyone who registers from now on is "pending" and cannot see or save
--     anything until HR approves them in Admin Panel -> Account requests;
--   * HR, ED and Finance addresses listed in access_roles are approved
--     automatically so the leadership can never be locked out.
-- Needs files 01 and 07 to have been run first.
-- ============================================================================

alter table public.profiles add column if not exists approval      text;
alter table public.profiles add column if not exists approval_note text;
alter table public.profiles add column if not exists approved_by   text;
alter table public.profiles add column if not exists approved_at   timestamptz;

-- every existing account keeps working
update public.profiles set approval = 'approved' where approval is null;
alter table public.profiles alter column approval set default 'pending';
alter table public.profiles alter column approval set not null;
alter table public.profiles drop constraint if exists profiles_approval_check;
alter table public.profiles add constraint profiles_approval_check
    check (approval in ('pending','approved','rejected'));

-- true only for an approved signed-in user
create or replace function public.is_approved() returns boolean
    language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.profiles where id = auth.uid() and approval = 'approved');
$$;

-- new profiles start as pending, except the leadership addresses
create or replace function public.s2s_make_profile(p_id uuid, p_email text, p_meta jsonb) returns void
    language plpgsql security definer set search_path = public as $$
declare s public.staff; v_type text; v_appr text := 'pending';
begin
    select * into s from public.staff where lower(email) = lower(p_email) limit 1;
    v_type := case when coalesce(p_meta->>'user_type','') = 'volunteer' then 'volunteer' else 'employee' end;
    if exists (select 1 from public.access_roles where lower(email::text) = lower(p_email) and access = 'hr') then
        v_type := 'superadmin'; v_appr := 'approved';
    elsif exists (select 1 from public.access_roles where lower(email::text) = lower(p_email) and access = 'admin') then
        v_type := 'admin'; v_appr := 'approved';
    elsif exists (select 1 from public.access_roles where lower(email::text) = lower(p_email)) then
        v_appr := 'approved';
    end if;
    insert into public.profiles (id, email, first_name, last_name, user_type, role, department, staff_id, phone, location, approval)
    values (p_id, lower(p_email),
            coalesce(p_meta->>'first_name',''), coalesce(p_meta->>'last_name',''),
            v_type,
            coalesce(s.role, ''),
            coalesce(nullif(p_meta->>'department',''), ''),
            s.staff_id,
            p_meta->>'phone', p_meta->>'location', v_appr)
    on conflict (id) do nothing;
end $$;

-- nobody can approve themselves: only HR / Super Admin changes these columns
create or replace function public.profiles_guard() returns trigger
    language plpgsql security definer set search_path = public as $$
begin
    if coalesce(current_setting('s2s.bypass_guard', true), '') = '1' then return new; end if;
    if auth.uid() is null then return new; end if;
    if not public.is_superadmin() then
        new.user_type := old.user_type;
        new.role      := old.role;
        new.staff_id  := old.staff_id;
        new.email     := old.email;
        new.approval      := old.approval;
        new.approval_note := old.approval_note;
        new.approved_by   := old.approved_by;
        new.approved_at   := old.approved_at;
    end if;
    new.updated_at := now();
    return new;
end $$;

-- HR's approve / decline button
create or replace function public.admin_set_approval(p_email text, p_status text, p_note text default null)
    returns public.profiles
    language plpgsql security definer set search_path = public as $$
declare p public.profiles; me text;
begin
    if not public.is_superadmin() then
        raise exception 'Only HR can approve accounts' using errcode = '42501';
    end if;
    if p_status not in ('approved','rejected','pending') then
        raise exception 'Unknown status %', p_status;
    end if;
    select email into me from public.profiles where id = auth.uid();
    perform set_config('s2s.bypass_guard', '1', true);
    update public.profiles
       set approval = p_status, approval_note = p_note, approved_by = me, approved_at = now()
     where lower(email) = lower(p_email)
     returning * into p;
    return p;
end $$;

-- the safety net: until approved, a signed-in user can read and write nothing
-- except their own profile row (needed so the app can tell them "waiting").
do $$
declare t record;
begin
    for t in select tablename from pg_tables
              where schemaname = 'public' and rowsecurity
                and tablename not in ('profiles','access_roles') loop
        execute format('drop policy if exists s2s_approved_only on public.%I', t.tablename);
        execute format('create policy s2s_approved_only on public.%I as restrictive for all to authenticated using (public.is_approved()) with check (public.is_approved())', t.tablename);
    end loop;
end $$;

-- check:  select email, approval from public.profiles order by created_at desc;
