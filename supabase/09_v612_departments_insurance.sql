-- ============================================================================
--  S2S People Portal - v6.12 database update
--  SUPABASE - 09 - departments, outsourced staff, insurance coverage
--
--  Run in the Supabase SQL editor AFTER 08_v611_compliance.sql. Safe to run again.
-- ============================================================================

alter table public.staff add column if not exists dept2            text;      -- second department, if someone works across two
alter table public.staff add column if not exists employment_type  text;      -- 'direct' or 'outsourced'
alter table public.staff add column if not exists employer_company text;      -- the company that employs an outsourced person
alter table public.staff add column if not exists in_nsitf         boolean;   -- on the NSITF schedule?  (null = decided by employment_type)
alter table public.staff add column if not exists in_gli           boolean;   -- on the Group Life schedule?

-- Sort the current roster into the official departments (matched on staff ID).
-- Only fills people who are not already in one of the seven departments, so it never
-- overwrites a change made in the portal.
do $$
declare
  depts text[] := array['External Relations and Partnerships','Finance','Admin, Procurement and Logistics',
                        'Program Management','Media and Communication','Human Resource','Growth and Sustainability'];
begin
  update public.staff set department='External Relations and Partnerships', dept2='Growth and Sustainability'
   where staff_id='S26004' and not (department = any(depts));                    -- Hauwa
  update public.staff set department='Finance'                         where staff_id='S26008' and not (department = any(depts));  -- Hammed
  update public.staff set department='Admin, Procurement and Logistics' where staff_id='S26007' and not (department = any(depts));  -- Ekene
  update public.staff set department='Program Management'              where staff_id in ('S26006','S26005','S26011','S26010','S26009') and not (department = any(depts)); -- Adekunle, Patience, Henry, Michael, Oluyemi
  update public.staff set department='Media and Communication'         where staff_id in ('S26016','S26013') and not (department = any(depts));  -- Praise, Favour
  update public.staff set department='Human Resource'                  where staff_id='S26003' and not (department = any(depts));  -- Abiola
  update public.staff set department='Growth and Sustainability'       where staff_id='S26002' and not (department = any(depts));  -- Lois
end $$;

-- Companies that are paid through payroll but employ their own people (their employer provides the insurance)
update public.staff set employment_type='outsourced', employer_company=full_name, in_nsitf=false, in_gli=false
 where staff_id in ('S26023','S26024') and employment_type is null;

grant select, insert, update, delete on all tables in schema public to authenticated;