create table if not exists public.business_ratings (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references auth.users(id) on delete cascade,
  provider_role text not null check (provider_role in ('Technician', 'Supplier')),
  reviewer_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null check (source_type in ('service_request', 'order_item')),
  source_id uuid not null,
  rating integer not null check (rating between 1 and 5),
  comment text check (comment is null or char_length(comment) <= 1000),
  created_at timestamptz not null default now(),
  unique (source_type, source_id)
);

alter table public.business_ratings enable row level security;
grant select on table public.business_ratings to anon, authenticated;
revoke insert, update, delete on table public.business_ratings
  from public, anon, authenticated;

drop policy if exists "Business ratings are publicly readable"
  on public.business_ratings;
create policy "Business ratings are publicly readable"
  on public.business_ratings
  for select
  to anon, authenticated
  using (true);

create or replace view public.business_rating_summary
with (security_invoker = true)
as
select
  provider_id,
  provider_role,
  round(avg(rating)::numeric, 1) as average_rating,
  count(*)::integer as rating_count
from public.business_ratings
group by provider_id, provider_role;

grant select on public.business_rating_summary to anon, authenticated;

create or replace view public.active_business_profiles
with (security_barrier = true)
as
select distinct user_id as provider_id, role
from public.subscriptions
where status = 'active'
  and expires_at > now();

grant select on public.active_business_profiles to anon, authenticated;

create or replace function public.submit_business_rating(
  p_provider_id uuid,
  p_source_type text,
  p_source_id uuid,
  p_rating integer,
  p_comment text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  reviewer uuid := auth.uid();
  provider_role_value text;
  eligible boolean := false;
  inserted_id uuid;
begin
  if reviewer is null then
    raise exception 'Sign in to submit a rating';
  end if;
  if p_rating < 1 or p_rating > 5 then
    raise exception 'Rating must be between 1 and 5';
  end if;
  if p_comment is not null and char_length(p_comment) > 1000 then
    raise exception 'Review comment is too long';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = reviewer and role = 'Customer'
  ) then
    raise exception 'Only customers can submit ratings';
  end if;

  if p_source_type = 'service_request' then
    select p.role, exists (
      select 1 from public.service_requests sr
      where sr.id = p_source_id
        and sr.customer_id = reviewer
        and sr.technician_id = p_provider_id
        and sr.status = 'completed'
    )
    into provider_role_value, eligible
    from public.profiles p
    where p.id = p_provider_id;
    if provider_role_value <> 'Technician' then
      raise exception 'Service ratings must be for a technician';
    end if;
  elsif p_source_type = 'order_item' then
    select p.role, exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      join public.products product on product.id = oi.product_id
      where oi.id = p_source_id
        and o.customer_id = reviewer
        and product.supplier_id = p_provider_id
        and oi.fulfillment_status = 'delivered'
    )
    into provider_role_value, eligible
    from public.profiles p
    where p.id = p_provider_id;
    if provider_role_value <> 'Supplier' then
      raise exception 'Product ratings must be for a supplier';
    end if;
  else
    raise exception 'Unsupported rating source';
  end if;

  if not coalesce(eligible, false) then
    raise exception 'A completed transaction is required to rate this business';
  end if;

  insert into public.business_ratings (
    provider_id, provider_role, reviewer_id, source_type, source_id, rating, comment
  )
  values (
    p_provider_id,
    provider_role_value,
    reviewer,
    p_source_type,
    p_source_id,
    p_rating,
    nullif(btrim(p_comment), '')
  )
  returning id into inserted_id;

  return inserted_id;
end;
$$;

revoke all on function public.submit_business_rating(uuid, text, uuid, integer, text)
  from public, anon;
grant execute on function public.submit_business_rating(uuid, text, uuid, integer, text)
  to authenticated;

create or replace function public.enforce_business_subscription()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  acting_user uuid := auth.uid();
  acting_role text;
  supplier_id_value uuid;
begin
  if acting_user is null then
    return new;
  end if;

  select role into acting_role
  from public.profiles
  where id = acting_user;

  if tg_table_name = 'products' then
    if acting_role = 'Supplier' and not exists (
      select 1
      from public.subscriptions s
      where s.user_id = acting_user
        and s.role = 'Supplier'
        and s.status = 'active'
        and s.expires_at > now()
    ) then
      raise exception 'An active supplier subscription is required';
    end if;
  elsif tg_table_name = 'service_requests' then
    if tg_op = 'INSERT' and not exists (
      select 1
      from public.subscriptions s
      where s.user_id = new.technician_id
        and s.role = 'Technician'
        and s.status = 'active'
        and s.expires_at > now()
    ) then
      raise exception 'An active technician subscription is required';
    end if;
    if tg_op = 'UPDATE'
      and acting_role = 'Technician'
      and new.technician_id = acting_user
      and new.status in ('accepted', 'completed')
      and not exists (
        select 1
        from public.subscriptions s
        where s.user_id = acting_user
          and s.role = 'Technician'
          and s.status = 'active'
          and s.expires_at > now()
      )
    then
      raise exception 'An active technician subscription is required';
    end if;
  elsif tg_table_name = 'order_items' then
    select p.supplier_id into supplier_id_value
    from public.products p
    where p.id = new.product_id;
    if acting_role = 'Supplier'
      and supplier_id_value = acting_user
      and new.fulfillment_status is distinct from old.fulfillment_status
      and not exists (
        select 1
        from public.subscriptions s
        where s.user_id = acting_user
          and s.role = 'Supplier'
          and s.status = 'active'
          and s.expires_at > now()
      )
    then
      raise exception 'An active supplier subscription is required';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_supplier_product_subscription on public.products;
create trigger enforce_supplier_product_subscription
before insert or update on public.products
for each row execute function public.enforce_business_subscription();

drop trigger if exists enforce_technician_request_subscription on public.service_requests;
create trigger enforce_technician_request_subscription
before insert or update of status on public.service_requests
for each row execute function public.enforce_business_subscription();

drop trigger if exists enforce_supplier_order_subscription on public.order_items;
create trigger enforce_supplier_order_subscription
before update of fulfillment_status on public.order_items
for each row execute function public.enforce_business_subscription();

revoke all on function public.enforce_business_subscription() from public, anon, authenticated;
