begin;

-- Ürün fiyat listesi PDF olarak yüklenebilsin diye belgeye amaç bilgisi
-- eklenir. Ayrı bir tablo ve ayrı bir yükleme hattı kurulmaz: karantina,
-- imza doğrulaması, ClamAV taraması ve saklama süresi zaten `documents`
-- üzerinde çalışıyor. Fiyat listesi bunların hepsine ihtiyaç duyar.
alter table public.documents add column if not exists purpose text
  not null default 'general'
  check (purpose in ('general', 'price_list'));

comment on column public.documents.purpose is
  'price_list = ürün ve fiyatlar ekranında listelenen fiyat listesi. '
  'Sahada salt okunurdur; yükleme web çalışma alanında yapılır.';

create index if not exists documents_workspace_purpose_idx
  on public.documents(workspace_id, purpose, created_at desc);

commit;
