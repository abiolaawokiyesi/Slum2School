-- ============================================================================
--  S2S People Portal - v6.11 database update
--  SUPABASE - 08 - salary breakdown, date of birth, compliance settings
--
--  Run in the Supabase SQL editor AFTER 07_v610_login_visibility_proration.sql.
--  Safe to run more than once.
--
--  The NSITF payroll schedule, Group Life schedule and Occupiers' Liability
--  register work without this file (they use the figures already in the app).
--  Run it so that the salary breakdown, dates of birth and the working-day and
--  statutory settings are also saved in the cloud and follow people across devices.
-- ============================================================================

alter table public.salaries  add column if not exists basic       numeric(14,2);
alter table public.salaries  add column if not exists housing     numeric(14,2);
alter table public.salaries  add column if not exists transport   numeric(14,2);
alter table public.salaries  add column if not exists other_allow numeric(14,2);
alter table public.salaries  add column if not exists benefits    numeric(14,2);

alter table public.staff     add column if not exists dob text;               -- date of birth (ISO), for Group Life

-- working week, public holidays, employer pension %, NSITF %, Group Life multiple,
-- default salary split and the NSITF / policy numbers, kept as one JSON document
alter table public.pay_rates add column if not exists settings jsonb;

grant select, insert, update, delete on all tables in schema public to authenticated;