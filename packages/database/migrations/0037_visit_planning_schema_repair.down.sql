begin;

-- Intentionally irreversible: removing these columns after production visits
-- have started using them would discard user-authored planning metadata.
-- Roll forward with a corrective migration instead of deleting live data.

commit;
