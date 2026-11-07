-- ============================================================================
-- S2S People Portal v6.13.0 - company-format requisition + vendor invoice
-- Run once in Supabase: SQL Editor -> New query -> paste -> Run.
-- Safe to run more than once. Without it the feature still works on each
-- device; this file lets requisitions and invoices follow staff to any device.
-- ============================================================================

-- the full company-format requisition (team, department, signatories, invoice list)
alter table public.requisitions add column if not exists doc jsonb;

-- private storage for vendor invoices (one folder per requisition id)
insert into storage.buckets (id, name, public)
values ('requisition-invoices', 'requisition-invoices', false)
on conflict (id) do nothing;

drop policy if exists inv_insert on storage.objects;
create policy inv_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'requisition-invoices'
    and exists (select 1 from public.requisitions r
                where r.id = (storage.foldername(name))[1]
                  and r.requester_email = public.my_email())
  );

drop policy if exists inv_update on storage.objects;
create policy inv_update on storage.objects for update to authenticated
  using (
    bucket_id = 'requisition-invoices'
    and exists (select 1 from public.requisitions r
                where r.id = (storage.foldername(name))[1]
                  and r.requester_email = public.my_email())
  );

drop policy if exists inv_select on storage.objects;
create policy inv_select on storage.objects for select to authenticated
  using (
    bucket_id = 'requisition-invoices'
    and exists (select 1 from public.requisitions r
                where r.id = (storage.foldername(name))[1]
                  and (r.requester_email = public.my_email()
                       or public.is_admin() or public.can_view_payroll()))
  );

drop policy if exists inv_delete on storage.objects;
create policy inv_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'requisition-invoices'
    and exists (select 1 from public.requisitions r
                where r.id = (storage.foldername(name))[1]
                  and (r.requester_email = public.my_email()
                       or public.is_admin() or public.can_view_payroll()))
  );
