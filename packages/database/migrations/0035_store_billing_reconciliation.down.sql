begin;

-- Billing ledger data and the safer reconciliation projection are retained on
-- rollback so reverting application code cannot revive duplicate access. The
-- transfer RPC is removed because older handlers never call it.
drop function if exists public.transfer_store_billing_ownership(text,text,text,text,uuid,uuid,uuid,uuid,timestamptz);

commit;
