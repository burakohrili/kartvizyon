begin;

-- CLI ile oluşturulan nesnelerde PostgREST rollerine otomatik tablo grant'i
-- uygulanmadı. RLS erişim kapsamını belirlemeye devam eder; bu grant'ler yalnız
-- SQL privilege katmanını açar.
grant usage on schema public to authenticated, service_role;

grant select, insert, update, delete
  on all tables in schema public
  to authenticated;

grant all privileges
  on all tables in schema public
  to service_role;

grant usage, select
  on all sequences in schema public
  to authenticated;

grant all privileges
  on all sequences in schema public
  to service_role;

commit;
