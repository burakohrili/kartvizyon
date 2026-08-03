begin;
drop trigger if exists orders_webhook_events on public.order_drafts;
drop trigger if exists tasks_webhook_events on public.tasks;
drop trigger if exists visits_webhook_events on public.visits;
drop function if exists public.enqueue_webhook_event();
drop function if exists public.consume_api_rate_limit(text, integer, integer);
drop table if exists public.api_rate_limits;
commit;
