begin;

create extension if not exists pg_trgm;

alter table public.companies add column client_mutation_id uuid;
create unique index companies_idempotency_idx on public.companies(created_by, client_mutation_id) where client_mutation_id is not null;

create or replace function public.find_company_duplicates(target_workspace_id uuid, candidate_name text, candidate_email text default null, candidate_phone text default null)
returns table (id uuid, name text, email citext, phone text, similarity_score real, match_reason text)
language sql stable security definer set search_path = '' as $$
  select c.id, c.name, c.email, c.phone,
    greatest(extensions.similarity(c.normalized_name, lower(regexp_replace(candidate_name, '[^[:alnum:]]', '', 'g'))),
      case when candidate_email is not null and lower(c.email::text) = lower(candidate_email) then 1 else 0 end,
      case when candidate_phone is not null and regexp_replace(c.phone, '[^0-9]', '', 'g') = regexp_replace(candidate_phone, '[^0-9]', '', 'g') then 1 else 0 end)::real,
    case
      when candidate_email is not null and lower(c.email::text) = lower(candidate_email) then 'email'
      when candidate_phone is not null and regexp_replace(c.phone, '[^0-9]', '', 'g') = regexp_replace(candidate_phone, '[^0-9]', '', 'g') then 'phone'
      else 'name'
    end
  from public.companies c
  where c.workspace_id = target_workspace_id
    and c.archived_at is null
    and public.can_access_workspace(target_workspace_id)
    and (
      extensions.similarity(c.normalized_name, lower(regexp_replace(candidate_name, '[^[:alnum:]]', '', 'g'))) >= 0.55
      or (candidate_email is not null and lower(c.email::text) = lower(candidate_email))
      or (candidate_phone is not null and regexp_replace(c.phone, '[^0-9]', '', 'g') = regexp_replace(candidate_phone, '[^0-9]', '', 'g'))
    )
  order by 5 desc
  limit 5;
$$;

grant execute on function public.find_company_duplicates(uuid, text, text, text) to authenticated;

commit;
