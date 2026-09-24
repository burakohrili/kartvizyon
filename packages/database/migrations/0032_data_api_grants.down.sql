begin;

revoke select, insert, update, delete
  on all tables in schema public
  from authenticated;

revoke all privileges
  on all tables in schema public
  from service_role;

revoke usage, select
  on all sequences in schema public
  from authenticated;

revoke all privileges
  on all sequences in schema public
  from service_role;

commit;
