begin;

-- Hesap silindiğinde `approved_by` FK'si kişisel veriyi anonimleştirmek için
-- NULL olur. Onayın kendisi ve zamanı değişmeden kalır; eski kural bu geçerli
-- durumu reddettiği için auth.users silme işlemini tamamen geri alıyordu.
alter table public.visits drop constraint if exists visit_approval_consistent;
alter table public.visits add constraint visit_approval_consistent check (
  (status = 'approved' and approved_at is not null) or
  (status <> 'approved' and approved_by is null and approved_at is null)
);

comment on constraint visit_approval_consistent on public.visits is
  'Onay zamanı kalıcı denetim izi olarak korunur; hesap silinirse approved_by anonimleşebilir.';

commit;
