-- ============================================================================
-- STORAGE — bucket para as fotos das peças (referência visual, campo foto_url)
-- Rodar no SQL Editor do Supabase depois do schema.sql
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('fotos-pecas', 'fotos-pecas', true)
on conflict (id) do nothing;

-- Leitura pública (as fotos aparecem na ficha de produção/orçamento, não tem
-- dado sensível nelas — só a peça em si). Upload e exclusão só por quem
-- estiver logado no app.
create policy "leitura publica fotos-pecas"
  on storage.objects for select
  using (bucket_id = 'fotos-pecas');

create policy "upload autenticado fotos-pecas"
  on storage.objects for insert
  with check (bucket_id = 'fotos-pecas' and auth.role() = 'authenticated');

create policy "exclusao autenticada fotos-pecas"
  on storage.objects for delete
  using (bucket_id = 'fotos-pecas' and auth.role() = 'authenticated');
