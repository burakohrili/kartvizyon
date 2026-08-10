begin;

drop trigger if exists visits_webhook_events on public.visits;
drop trigger if exists tasks_webhook_events on public.tasks;
drop trigger if exists orders_webhook_events on public.order_drafts;
drop function if exists public.enqueue_webhook_event();

commit;
