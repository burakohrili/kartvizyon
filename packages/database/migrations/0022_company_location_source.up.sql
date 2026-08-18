begin;

-- Elle girilen müşterinin koordinatı yoktu; `/api/geofence/candidates`
-- `latitude is not null` filtresi uyguladığı için bu müşteriler yakınlık
-- önerilerinde hiç görünmüyordu. Konumun nereden geldiğini ayırt edebilmek
-- için kaynak bilgisi tutulur: sahada sabitlenen konum, adresten tahmin
-- edilen konumu her zaman ezer.
alter table public.companies add column if not exists location_source text
  check (location_source is null or location_source in ('geocoded', 'pinned'));
alter table public.companies add column if not exists location_updated_at timestamptz;

comment on column public.companies.location_source is
  'pinned = saha çalışanı müşterinin kapısında sabitledi (kesin). '
  'geocoded = adres metninden tahmin edildi. pinned, geocoded''i ezer.';

-- Konumu olan mevcut kayıtlar içe aktarmadan geldiği için tahmin sayılır.
update public.companies
set location_source = 'geocoded'
where latitude is not null and longitude is not null and location_source is null;

create index if not exists companies_workspace_location_idx
  on public.companies(workspace_id)
  where latitude is not null and longitude is not null;

commit;
