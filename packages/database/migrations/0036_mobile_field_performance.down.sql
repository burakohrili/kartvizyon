begin;

-- Keep the corrected rate-limit function on rollback: restoring the old
-- ambiguous function would reintroduce a production outage. The index is
-- independently reversible.
drop index if exists public.tasks_workspace_due_id_idx;

commit;
