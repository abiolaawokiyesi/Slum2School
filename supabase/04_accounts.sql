-- ============================================================================
--  Slum2School Africa — S2S People Portal
--  SUPABASE · 04 · PRE-CREATE KEY ACCOUNTS  (HR, Executive Director, Finance)
--
--  Run AFTER 01_schema.sql (needs the pgcrypto extension + handle_new_user
--  trigger it creates). This creates real, confirmed Supabase Auth accounts, so
--  the three payroll roles can log in immediately. Their profiles are built
--  automatically by the sign-up trigger, so payroll access is granted at once.
--
--  ⚠ CHANGE THESE PASSWORDS after first login (Supabase → Authentication → Users,
--    or the portal's "Forgot password?" once email is configured).
--
--  If your Supabase version rejects the direct insert below, use the fallback:
--  have each person Register in the portal, then run the promote UPDATE at the
--  bottom for HR. ED and Finance get payroll access automatically from their role.
-- ============================================================================

create or replace function public.create_staff_user(p_email text, p_password text, p_meta jsonb)
returns uuid
language plpgsql
security definer
set search_path = auth, public
as $$
declare uid uuid;
begin
  select id into uid from auth.users where email = p_email;
  if uid is not null then
     -- keep metadata/password in sync on re-run
     update auth.users
        set raw_user_meta_data = p_meta,
            encrypted_password  = crypt(p_password, gen_salt('bf')),
            email_confirmed_at  = coalesce(email_confirmed_at, now()),
            updated_at          = now()
      where id = uid;
     return uid;
  end if;

  uid := gen_random_uuid();

  insert into auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
     raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values
    ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', p_email,
     crypt(p_password, gen_salt('bf')), now(),
     '{"provider":"email","providers":["email"]}'::jsonb, p_meta, now(), now());

  insert into auth.identities
    (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  values
    (gen_random_uuid(), uid::text, uid,
     jsonb_build_object('sub', uid::text, 'email', p_email),
     'email', now(), now(), now());

  return uid;
end $$;

-- ---- Create the three accounts (default passwords — CHANGE AFTER LOGIN) -----
select public.create_staff_user(
  'abiola.awokiyesi@slum2school.org', 'S2S-HR-2026',
  '{"first_name":"Abiola","last_name":"Awokiyesi","user_type":"superadmin","role":"Human Resource Manager","department":"HR & Talent","staff_id":"S26003"}'::jsonb);

select public.create_staff_user(
  'otto.orondaam@slum2school.org', 'S2S-ED-2026',
  '{"first_name":"Otto","last_name":"Orondaam","user_type":"employee","role":"Executive Director","department":"Management","staff_id":"S26001"}'::jsonb);

select public.create_staff_user(
  'hammed.balogun@slum2school.org', 'S2S-Finance-2026',
  '{"first_name":"Hammed","last_name":"Balogun","user_type":"employee","role":"Finance Manager","department":"Finance","staff_id":"S26008"}'::jsonb);

-- Make sure HR is Super Admin even if the profile already existed
update public.profiles set user_type = 'superadmin'
where email = 'abiola.awokiyesi@slum2school.org';

-- ---- Login details created --------------------------------------------------
--   HR (Super Admin) : abiola.awokiyesi@slum2school.org  /  S2S-HR-2026
--   Executive Director: otto.orondaam@slum2school.org    /  S2S-ED-2026
--   Finance Manager  : hammed.balogun@slum2school.org    /  S2S-Finance-2026
--   → All three can open Payroll. Everyone else cannot.
--
-- FALLBACK (if the insert above is rejected on your Supabase version):
--   1) Have each person open the portal and Register with the same email + role.
--   2) Promote HR:  update public.profiles set user_type='superadmin'
--                   where email='abiola.awokiyesi@slum2school.org';
