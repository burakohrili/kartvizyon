begin;

drop function if exists public.transition_order_draft(uuid, public.order_draft_status, text);
drop function if exists public.recalculate_order_draft(uuid);
drop table if exists public.order_draft_items;
drop table if exists public.order_drafts;
drop table if exists public.price_list_items;
drop table if exists public.price_lists;
drop table if exists public.products;
drop table if exists public.opportunities;
alter table public.visits drop constraint if exists visit_plan_time_valid;
alter table public.visits drop column if exists check_in_type, drop column if exists planned_end_at, drop column if exists planned_start_at;
drop table if exists public.team_members;
drop table if exists public.teams;
alter table public.memberships drop constraint if exists memberships_region_fk;
drop table if exists public.regions;
drop type if exists public.order_draft_status;
drop type if exists public.opportunity_stage;

commit;
