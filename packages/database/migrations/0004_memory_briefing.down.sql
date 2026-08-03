begin;

drop trigger if exists visit_approved_refresh_memory on public.visits;
drop function if exists public.on_visit_approved_refresh_memory();
drop function if exists public.refresh_customer_memory_card(uuid);

commit;
