alter table public.products
  add column if not exists is_listed boolean not null default true;

alter table public.profiles
  add column if not exists account_status text not null default 'active';

alter table public.profiles
  drop constraint if exists profiles_account_status_check;
alter table public.profiles
  add constraint profiles_account_status_check
  check (account_status in ('active', 'suspended'));

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  supplier_id uuid not null references auth.users(id) on delete cascade,
  image_url text not null,
  storage_path text not null unique,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now()
);

create index if not exists product_images_product_order_idx
  on public.product_images(product_id, sort_order, created_at);
alter table public.product_images enable row level security;
grant select on public.product_images to anon, authenticated;
grant insert, delete on public.product_images to authenticated;
revoke update on public.product_images
  from public, anon, authenticated;

drop policy if exists "Active suppliers can view their product images"
  on public.product_images;
create policy "Active suppliers can view their product images"
  on public.product_images
  for select
  to authenticated
  using (
    supplier_id = auth.uid()
    or exists (
      select 1
      from public.products p
      join public.subscriptions s on s.user_id = p.supplier_id
      where p.id = product_id
        and p.is_listed
        and s.role = 'Supplier'
        and s.status = 'active'
        and s.expires_at > now()
    )
  );

drop policy if exists "Active suppliers can add product images"
  on public.product_images;
create policy "Active suppliers can add product images"
  on public.product_images
  for insert
  to authenticated
  with check (
    supplier_id = auth.uid()
    and exists (
      select 1
      from public.products p
      join public.subscriptions s on s.user_id = p.supplier_id
      where p.id = product_id
        and p.supplier_id = auth.uid()
        and s.role = 'Supplier'
        and s.status = 'active'
        and s.expires_at > now()
    )
  );

drop policy if exists "Suppliers can delete their product images"
  on public.product_images;
create policy "Suppliers can delete their product images"
  on public.product_images
  for delete
  to authenticated
  using (supplier_id = auth.uid());

create or replace function public.get_public_product_gallery(p_product_ids uuid[])
returns table (product_id uuid, image_urls text[], is_listed boolean)
language sql
stable
security definer
set search_path = public
as $$
  select p.id,
    coalesce(
      array_agg(pi.image_url order by pi.sort_order, pi.created_at)
        filter (where pi.image_url is not null),
      case
        when p.image_url is not null then array[p.image_url]
        else '{}'::text[]
      end
    ) as image_urls,
    p.is_listed
  from public.products p
  left join public.product_images pi on pi.product_id = p.id
  where p.id = any(coalesce(p_product_ids, '{}'::uuid[]))
    and (
      (
        p.is_listed
        and exists (
          select 1
          from public.subscriptions s
          where s.user_id = p.supplier_id
            and s.role = 'Supplier'
            and s.status = 'active'
            and s.expires_at > now()
        )
      )
      or p.supplier_id = auth.uid()
    )
  group by p.id, p.image_url, p.is_listed;
$$;

revoke all on function public.get_public_product_gallery(uuid[])
  from public, anon, authenticated;
grant execute on function public.get_public_product_gallery(uuid[])
  to anon, authenticated;

create or replace function public.enforce_orderable_product_listing()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.products p
    join public.subscriptions s on s.user_id = p.supplier_id
    where p.id = new.product_id
      and p.is_listed
      and s.role = 'Supplier'
      and s.status = 'active'
      and s.expires_at > now()
  ) then
    raise exception 'Product is not available for sale';
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_orderable_product_listing()
  from public, anon, authenticated;

drop trigger if exists enforce_orderable_product_listing
  on public.order_items;
create trigger enforce_orderable_product_listing
  before insert on public.order_items
  for each row
  execute function public.enforce_orderable_product_listing();

create table if not exists public.product_reports (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (char_length(btrim(reason)) between 3 and 1000),
  status text not null default 'open'
    check (status in ('open', 'reviewed', 'dismissed')),
  admin_note text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (product_id, reporter_id)
);

alter table public.product_reports enable row level security;
grant select, insert on public.product_reports to authenticated;
revoke update, delete on public.product_reports from public, anon, authenticated;
grant all on public.product_reports to service_role;
drop policy if exists "Customers can report products" on public.product_reports;
create policy "Customers can report products"
  on public.product_reports
  for insert
  to authenticated
  with check (
    auth.uid() = reporter_id
    and exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'Customer'
        and account_status = 'active'
    )
    and exists (
      select 1
      from public.products p
      join public.subscriptions s on s.user_id = p.supplier_id
      where p.id = product_id
        and p.is_listed
        and s.role = 'Supplier'
        and s.status = 'active'
        and s.expires_at > now()
    )
  );
drop policy if exists "Users can read their product reports"
  on public.product_reports;
create policy "Users can read their product reports"
  on public.product_reports
  for select
  to authenticated
  using (auth.uid() = reporter_id);

create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text not null,
  entity_id uuid,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists user_notifications_user_created_idx
  on public.user_notifications(user_id, created_at desc);
alter table public.user_notifications enable row level security;
grant select on public.user_notifications to authenticated;
revoke insert, update, delete on public.user_notifications
  from public, anon, authenticated;
grant all on public.user_notifications to service_role;
drop policy if exists "Users can read their notifications"
  on public.user_notifications;
create policy "Users can read their notifications"
  on public.user_notifications
  for select
  to authenticated
  using (auth.uid() = user_id);

create or replace function public.mark_notification_read(p_notification_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.user_notifications
  set read_at = coalesce(read_at, now())
  where id = p_notification_id
    and user_id = auth.uid();
end;
$$;

create or replace function public.notify_paid_product_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  supplier record;
begin
  if old.payment_status is distinct from 'paid'
    and new.payment_status = 'paid'
  then
    for supplier in
      select p.supplier_id,
        string_agg(oi.product_name, ', ' order by oi.product_name) as products
      from public.order_items oi
      join public.products p on p.id = oi.product_id
      where oi.order_id = new.id
      group by p.supplier_id
    loop
      insert into public.user_notifications (
        user_id, notification_type, title, body, entity_id
      )
      values (
        supplier.supplier_id,
        'paid_order',
        'New paid order',
        'A customer paid for: ' || supplier.products,
        new.id
      );
    end loop;
  end if;
  return new;
end;
$$;

revoke all on function public.notify_paid_product_order()
  from public, anon, authenticated;

drop trigger if exists notify_paid_product_order on public.orders;
create trigger notify_paid_product_order
  after update of payment_status on public.orders
  for each row
  execute function public.notify_paid_product_order();

create or replace function public.notify_order_fulfillment_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  customer uuid;
begin
  if new.fulfillment_status is distinct from old.fulfillment_status then
    select customer_id into customer
    from public.orders
    where id = new.order_id and payment_status = 'paid';

    if customer is not null then
      insert into public.user_notifications (
        user_id, notification_type, title, body, entity_id
      )
      values (
        customer,
        'order_status',
        'Order status updated',
        new.product_name || ' is now ' ||
          replace(new.fulfillment_status, '_', ' ') || '.',
        new.order_id
      );
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.notify_order_fulfillment_change()
  from public, anon, authenticated;

drop trigger if exists notify_order_fulfillment_change on public.order_items;
create trigger notify_order_fulfillment_change
  after update of fulfillment_status on public.order_items
  for each row
  execute function public.notify_order_fulfillment_change();

create or replace function public.admin_list_product_moderation()
returns table (
  product_id uuid,
  product_name text,
  supplier_id uuid,
  supplier_name text,
  is_listed boolean,
  stock_quantity integer,
  report_count bigint,
  image_url text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'Admin'
      and account_status = 'active'
  ) then
    raise exception 'Admin access required';
  end if;

  return query
  select p.id, p.name, p.supplier_id, profile.full_name, p.is_listed,
    p.stock_quantity,
    (select count(*) from public.product_reports r
      where r.product_id = p.id and r.status = 'open'),
    p.image_url, p.created_at
  from public.products p
  left join public.profiles profile on profile.id = p.supplier_id
  order by p.created_at desc;
end;
$$;

create or replace function public.admin_list_product_reports()
returns table (
  report_id uuid,
  product_id uuid,
  product_name text,
  reporter_name text,
  reason text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'Admin'
      and account_status = 'active'
  ) then
    raise exception 'Admin access required';
  end if;

  return query
  select r.id, r.product_id, p.name, reporter.full_name,
    r.reason, r.status, r.created_at
  from public.product_reports r
  join public.products p on p.id = r.product_id
  left join public.profiles reporter on reporter.id = r.reporter_id
  order by (r.status = 'open') desc, r.created_at desc;
end;
$$;

create or replace function public.admin_list_accounts()
returns table (
  user_id uuid,
  full_name text,
  email text,
  role text,
  account_status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'Admin'
      and account_status = 'active'
  ) then
    raise exception 'Admin access required';
  end if;

  return query
  select p.id, p.full_name, p.email, p.role, p.account_status,
    u.created_at
  from public.profiles p
  join auth.users u on u.id = p.id
  order by u.created_at desc;
end;
$$;

create or replace function public.admin_set_product_listing(
  p_product_id uuid,
  p_is_listed boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'Admin'
      and account_status = 'active'
  ) then
    raise exception 'Admin access required';
  end if;

  update public.products
  set is_listed = p_is_listed
  where id = p_product_id;
  if not found then raise exception 'Product not found'; end if;
end;
$$;

create or replace function public.admin_review_product_report(
  p_report_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'Admin'
      and account_status = 'active'
  ) then
    raise exception 'Admin access required';
  end if;
  if p_status not in ('reviewed', 'dismissed') then
    raise exception 'Invalid report status';
  end if;

  update public.product_reports
  set status = p_status, reviewed_at = now()
  where id = p_report_id;
  if not found then raise exception 'Report not found'; end if;
end;
$$;

create or replace function public.admin_set_account_status(
  p_user_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'Admin'
      and account_status = 'active'
  ) then
    raise exception 'Admin access required';
  end if;
  if p_status not in ('active', 'suspended') then
    raise exception 'Invalid account status';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'Admins cannot change their own account status';
  end if;

  update public.profiles
  set account_status = p_status
  where id = p_user_id;
  if not found then raise exception 'Account not found'; end if;

  update auth.users
  set banned_until = case
    when p_status = 'suspended' then now() + interval '100 years'
    else null
  end
  where id = p_user_id;
end;
$$;

revoke all on function public.mark_notification_read(uuid)
  from public, anon;
grant execute on function public.mark_notification_read(uuid)
  to authenticated;

revoke all on function public.admin_list_product_moderation()
  from public, anon, authenticated;
revoke all on function public.admin_list_product_reports()
  from public, anon, authenticated;
revoke all on function public.admin_list_accounts()
  from public, anon, authenticated;
revoke all on function public.admin_set_product_listing(uuid, boolean)
  from public, anon, authenticated;
revoke all on function public.admin_review_product_report(uuid, text)
  from public, anon, authenticated;
revoke all on function public.admin_set_account_status(uuid, text)
  from public, anon, authenticated;
grant execute on function public.admin_list_product_moderation()
  to authenticated;
grant execute on function public.admin_list_product_reports()
  to authenticated;
grant execute on function public.admin_list_accounts()
  to authenticated;
grant execute on function public.admin_set_product_listing(uuid, boolean)
  to authenticated;
grant execute on function public.admin_review_product_report(uuid, text)
  to authenticated;
grant execute on function public.admin_set_account_status(uuid, text)
  to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
    and not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'user_notifications'
    )
  then
    alter publication supabase_realtime add table public.user_notifications;
  end if;
end;
$$;
