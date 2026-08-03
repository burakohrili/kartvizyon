begin;

alter table public.privacy_requests add column if not exists resolution_note text;

alter table public.workspaces drop constraint workspaces_owner_user_id_fkey;
alter table public.workspaces add constraint workspaces_owner_user_id_fkey foreign key (owner_user_id) references public.profiles(id) on delete cascade;

alter table public.audit_logs alter column workspace_id drop not null;
alter table public.audit_logs drop constraint audit_logs_workspace_id_fkey;
alter table public.audit_logs add constraint audit_logs_workspace_id_fkey foreign key (workspace_id) references public.workspaces(id) on delete set null;
alter table public.audit_logs drop constraint audit_logs_organization_id_fkey;
alter table public.audit_logs add constraint audit_logs_organization_id_fkey foreign key (organization_id) references public.organizations(id) on delete set null;

alter table public.invitations alter column invited_by drop not null;
alter table public.invitations drop constraint invitations_invited_by_fkey;
alter table public.invitations add constraint invitations_invited_by_fkey foreign key (invited_by) references public.profiles(id) on delete set null;
alter table public.invitations drop constraint invitations_accepted_by_fkey;
alter table public.invitations add constraint invitations_accepted_by_fkey foreign key (accepted_by) references public.profiles(id) on delete set null;

alter table public.companies alter column created_by drop not null;
alter table public.companies drop constraint companies_assigned_to_fkey;
alter table public.companies add constraint companies_assigned_to_fkey foreign key (assigned_to) references public.profiles(id) on delete set null;
alter table public.companies drop constraint companies_created_by_fkey;
alter table public.companies add constraint companies_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;

alter table public.contacts alter column created_by drop not null;
alter table public.contacts drop constraint contacts_created_by_fkey;
alter table public.contacts add constraint contacts_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;

alter table public.visits alter column representative_id drop not null;
alter table public.visits drop constraint visits_representative_id_fkey;
alter table public.visits add constraint visits_representative_id_fkey foreign key (representative_id) references public.profiles(id) on delete set null;
alter table public.visits drop constraint visits_approved_by_fkey;
alter table public.visits add constraint visits_approved_by_fkey foreign key (approved_by) references public.profiles(id) on delete set null;

alter table public.tasks alter column created_by drop not null;
alter table public.tasks drop constraint tasks_assigned_to_fkey;
alter table public.tasks add constraint tasks_assigned_to_fkey foreign key (assigned_to) references public.profiles(id) on delete set null;
alter table public.tasks drop constraint tasks_created_by_fkey;
alter table public.tasks add constraint tasks_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;

alter table public.import_jobs alter column created_by drop not null;
alter table public.import_jobs drop constraint import_jobs_created_by_fkey;
alter table public.import_jobs add constraint import_jobs_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;

alter table public.visit_audio_assets drop constraint visit_audio_assets_owner_id_fkey;
alter table public.visit_audio_assets add constraint visit_audio_assets_owner_id_fkey foreign key (owner_id) references public.profiles(id) on delete cascade;
alter table public.visit_transcripts drop constraint visit_transcripts_owner_id_fkey;
alter table public.visit_transcripts add constraint visit_transcripts_owner_id_fkey foreign key (owner_id) references public.profiles(id) on delete cascade;
alter table public.ai_jobs drop constraint ai_jobs_user_id_fkey;
alter table public.ai_jobs add constraint ai_jobs_user_id_fkey foreign key (user_id) references public.profiles(id) on delete cascade;
alter table public.debrief_submissions drop constraint debrief_submissions_user_id_fkey;
alter table public.debrief_submissions add constraint debrief_submissions_user_id_fkey foreign key (user_id) references public.profiles(id) on delete cascade;
alter table public.usage_records alter column user_id drop not null;
alter table public.usage_records drop constraint usage_records_user_id_fkey;
alter table public.usage_records add constraint usage_records_user_id_fkey foreign key (user_id) references public.profiles(id) on delete set null;

alter table public.report_shares alter column created_by drop not null;
alter table public.report_shares drop constraint report_shares_created_by_fkey;
alter table public.report_shares add constraint report_shares_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;

alter table public.regions alter column created_by drop not null;
alter table public.regions drop constraint regions_created_by_fkey;
alter table public.regions add constraint regions_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;
alter table public.teams alter column created_by drop not null;
alter table public.teams drop constraint teams_created_by_fkey;
alter table public.teams add constraint teams_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;

alter table public.opportunities alter column created_by drop not null;
alter table public.opportunities drop constraint opportunities_created_by_fkey;
alter table public.opportunities add constraint opportunities_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;
alter table public.products alter column created_by drop not null;
alter table public.products drop constraint products_created_by_fkey;
alter table public.products add constraint products_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;
alter table public.price_lists alter column created_by drop not null;
alter table public.price_lists drop constraint price_lists_created_by_fkey;
alter table public.price_lists add constraint price_lists_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;
alter table public.order_drafts alter column created_by drop not null;
alter table public.order_drafts drop constraint order_drafts_created_by_fkey;
alter table public.order_drafts add constraint order_drafts_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;
alter table public.order_drafts drop constraint order_drafts_approved_by_fkey;
alter table public.order_drafts add constraint order_drafts_approved_by_fkey foreign key (approved_by) references public.profiles(id) on delete set null;

alter table public.activity_comments alter column author_id drop not null;
alter table public.activity_comments drop constraint activity_comments_author_id_fkey;
alter table public.activity_comments add constraint activity_comments_author_id_fkey foreign key (author_id) references public.profiles(id) on delete set null;
alter table public.documents alter column owner_id drop not null;
alter table public.documents drop constraint documents_owner_id_fkey;
alter table public.documents add constraint documents_owner_id_fkey foreign key (owner_id) references public.profiles(id) on delete set null;
alter table public.form_templates alter column created_by drop not null;
alter table public.form_templates drop constraint form_templates_created_by_fkey;
alter table public.form_templates add constraint form_templates_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;
alter table public.form_submissions alter column submitted_by drop not null;
alter table public.form_submissions drop constraint form_submissions_submitted_by_fkey;
alter table public.form_submissions add constraint form_submissions_submitted_by_fkey foreign key (submitted_by) references public.profiles(id) on delete set null;

alter table public.api_credentials alter column created_by drop not null;
alter table public.api_credentials drop constraint api_credentials_created_by_fkey;
alter table public.api_credentials add constraint api_credentials_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;
alter table public.webhook_endpoints alter column created_by drop not null;
alter table public.webhook_endpoints drop constraint webhook_endpoints_created_by_fkey;
alter table public.webhook_endpoints add constraint webhook_endpoints_created_by_fkey foreign key (created_by) references public.profiles(id) on delete set null;

commit;
