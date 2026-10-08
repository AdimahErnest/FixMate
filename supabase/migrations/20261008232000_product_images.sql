alter table public.products
  add column if not exists image_url text;

create or replace function public.get_public_product_images(
  p_product_ids uuid[]
)
returns table (product_id uuid, image_url text)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.image_url
  from public.products p
  where p.id = any(coalesce(p_product_ids, '{}'::uuid[]))
    and p.image_url is not null
    and exists (
      select 1
      from public.subscriptions s
      where s.user_id = p.supplier_id
        and s.role = 'Supplier'
        and s.status = 'active'
        and s.expires_at > now()
    );
$$;

revoke all on function public.get_public_product_images(uuid[])
  from public, anon, authenticated;
grant execute on function public.get_public_product_images(uuid[])
  to anon, authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view product images"
  on storage.objects;
create policy "Public can view product images"
  on storage.objects
  for select
  to public
  using (bucket_id = 'product-images');

drop policy if exists "Active suppliers can upload product images"
  on storage.objects;
create policy "Active suppliers can upload product images"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1
      from public.profiles p
      join public.subscriptions s on s.user_id = p.id
      where p.id = auth.uid()
        and p.role = 'Supplier'
        and s.role = 'Supplier'
        and s.status = 'active'
        and s.expires_at > now()
    )
  );

drop policy if exists "Suppliers can update their product images"
  on storage.objects;
create policy "Suppliers can update their product images"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1
      from public.profiles p
      join public.subscriptions s on s.user_id = p.id
      where p.id = auth.uid()
        and p.role = 'Supplier'
        and s.role = 'Supplier'
        and s.status = 'active'
        and s.expires_at > now()
    )
  );

drop policy if exists "Suppliers can delete their product images"
  on storage.objects;
create policy "Suppliers can delete their product images"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'Supplier'
    )
  );
