begin;

alter table public.privacy_requests drop column if exists resolution_note;

-- Bu geri alma yalnızca henüz hesap silme işlemi çalıştırılmamış ortamlarda uygulanmalıdır.
alter table public.workspaces drop constraint workspaces_owner_user_id_fkey;
alter table public.workspaces add constraint workspaces_owner_user_id_fkey foreign key (owner_user_id) references public.profiles(id);

alter table public.audit_logs drop constraint audit_logs_workspace_id_fkey;
alter table public.audit_logs add constraint audit_logs_workspace_id_fkey foreign key (workspace_id) references public.workspaces(id) on delete restrict;
alter table public.audit_logs alter column workspace_id set not null;
alter table public.audit_logs drop constraint audit_logs_organization_id_fkey;
alter table public.audit_logs add constraint audit_logs_organization_id_fkey foreign key (organization_id) references public.organizations(id) on delete restrict;

-- Kalan atıf kısıtları eski davranışa döner; NULL üretilmişse rollback öncesi veri onarımı gerekir.
do $$
declare
  item record;
begin
  for item in select * from (values
    ('invitations','invited_by',true), ('invitations','accepted_by',false),
    ('companies','assigned_to',false), ('companies','created_by',true),
    ('contacts','created_by',true), ('visits','representative_id',true), ('visits','approved_by',false),
    ('tasks','assigned_to',false), ('tasks','created_by',true), ('import_jobs','created_by',true),
    ('usage_records','user_id',true), ('report_shares','created_by',true), ('regions','created_by',true),
    ('teams','created_by',true), ('opportunities','created_by',true), ('products','created_by',true),
    ('price_lists','created_by',true), ('order_drafts','created_by',true), ('order_drafts','approved_by',false),
    ('activity_comments','author_id',true), ('documents','owner_id',true), ('form_templates','created_by',true),
    ('form_submissions','submitted_by',true), ('api_credentials','created_by',true), ('webhook_endpoints','created_by',true)
  ) as v(table_name,column_name,was_not_null)
  loop
    execute format('alter table public.%I drop constraint %I', item.table_name, item.table_name || '_' || item.column_name || '_fkey');
    execute format('alter table public.%I add constraint %I foreign key (%I) references public.profiles(id)', item.table_name, item.table_name || '_' || item.column_name || '_fkey', item.column_name);
    if item.was_not_null then execute format('alter table public.%I alter column %I set not null', item.table_name, item.column_name); end if;
  end loop;
end $$;

alter table public.visit_audio_assets drop constraint visit_audio_assets_owner_id_fkey;
alter table public.visit_audio_assets add constraint visit_audio_assets_owner_id_fkey foreign key (owner_id) references public.profiles(id);
alter table public.visit_transcripts drop constraint visit_transcripts_owner_id_fkey;
alter table public.visit_transcripts add constraint visit_transcripts_owner_id_fkey foreign key (owner_id) references public.profiles(id);
alter table public.ai_jobs drop constraint ai_jobs_user_id_fkey;
alter table public.ai_jobs add constraint ai_jobs_user_id_fkey foreign key (user_id) references public.profiles(id);
alter table public.debrief_submissions drop constraint debrief_submissions_user_id_fkey;
alter table public.debrief_submissions add constraint debrief_submissions_user_id_fkey foreign key (user_id) references public.profiles(id);

commit;
