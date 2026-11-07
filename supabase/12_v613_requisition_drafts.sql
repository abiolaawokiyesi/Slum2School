-- ============================================================================
-- S2S People Portal v6.13.0 - save a requisition as a draft, edit it later
-- Run once in Supabase: SQL Editor -> New query -> paste -> Run. Safe to re-run.
-- Without it, edits to a requisition that is still "Pending" already work; only
-- drafts need this file (they simply stay on the device until it is run).
-- ============================================================================

-- allow the new "Draft" status
alter table public.requisitions drop constraint if exists requisitions_status_check;
alter table public.requisitions add constraint requisitions_status_check
    check (status in ('Draft','Pending','Approved by Finance','Approved','Rejected','Paid'));

-- the person who raised it may edit or delete it while it is a Draft or Pending
drop policy if exists req_update on public.requisitions;
create policy req_update on public.requisitions
    for update using (public.is_admin() or public.can_view_payroll()
                      or (requester_email = public.my_email() and status in ('Draft','Pending')))
               with check (public.is_admin() or public.can_view_payroll()
                      or requester_email = public.my_email());

drop policy if exists req_delete on public.requisitions;
create policy req_delete on public.requisitions
    for delete using (public.is_admin() or public.can_view_payroll()
                      or (requester_email = public.my_email() and status in ('Draft','Pending')));
