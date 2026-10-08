alter table public.products
  add column if not exists stock_quantity integer;

update public.products
set stock_quantity = case when coalesce(in_stock, true) then 1 else 0 end
where stock_quantity is null;

alter table public.products
  alter column stock_quantity set default 1,
  alter column stock_quantity set not null;

alter table public.products
  drop constraint if exists products_stock_quantity_nonnegative;
alter table public.products
  add constraint products_stock_quantity_nonnegative
  check (stock_quantity >= 0);

update public.products
set in_stock = (stock_quantity > 0)
where in_stock is distinct from (stock_quantity > 0);

alter table public.orders
  add column if not exists checkout_external_id text;

create unique index if not exists orders_checkout_external_id_idx
  on public.orders(checkout_external_id)
  where checkout_external_id is not null;

alter table public.orders
  add column if not exists currency text not null default 'XAF';

create table if not exists public.product_order_payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  customer_id uuid not null references auth.users(id) on delete cascade,
  amount integer not null check (amount >= 100),
  external_id text not null unique,
  fapshi_trans_id text unique,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed')),
  reservation_expires_at timestamptz not null default (now() + interval '24 hours'),
  inventory_released_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.product_order_payments
  add column if not exists checkout_link text;

alter table public.product_order_payments enable row level security;
grant select on public.product_order_payments to authenticated;
drop policy if exists "Customers can read their product order payments"
  on public.product_order_payments;
create policy "Customers can read their product order payments"
  on public.product_order_payments
  for select
  to authenticated
  using (auth.uid() = customer_id);
revoke insert, update, delete on public.product_order_payments
  from public, anon, authenticated;
grant all on public.product_order_payments to service_role;

create or replace function public.cancel_product_order_checkout(
  p_order_id uuid,
  p_reason text default 'failed'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  payment public.product_order_payments%rowtype;
  item record;
begin
  select * into payment
  from public.product_order_payments
  where order_id = p_order_id
  for update;

  if not found or payment.status <> 'pending' then
    return;
  end if;

  if payment.inventory_released_at is null then
    for item in
      select product_id, sum(quantity)::integer as quantity
      from public.order_items
      where order_id = p_order_id
      group by product_id
    loop
      update public.products
      set stock_quantity = stock_quantity + item.quantity,
          in_stock = true
      where id = item.product_id;
    end loop;
  end if;

  update public.product_order_payments
  set status = 'failed',
      inventory_released_at = coalesce(inventory_released_at, now())
  where id = payment.id;

  update public.orders
  set status = 'cancelled',
      payment_status = 'failed'
  where id = p_order_id
    and payment_status = 'unpaid';
end;
$$;

create or replace function public.create_product_order_checkout(
  p_customer_id uuid,
  p_items jsonb,
  p_external_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_order public.orders%rowtype;
  created_order_id uuid;
  total_xaf integer;
  requested_count integer;
  matching_count integer;
  item record;
begin
  if p_customer_id is null or p_items is null
    or jsonb_typeof(p_items) <> 'array'
    or jsonb_array_length(p_items) < 1
    or jsonb_array_length(p_items) > 25
    or p_external_id !~ '^order_[a-f0-9-]{36}$'
  then
    raise exception 'Invalid checkout request';
  end if;

  if not exists (
    select 1
    from public.profiles
    where id = p_customer_id and role = 'Customer'
  ) then
    raise exception 'A customer account is required';
  end if;

  for item in
    select order_id
    from public.product_order_payments
    where status = 'pending'
      and inventory_released_at is null
      and reservation_expires_at <= now()
    order by reservation_expires_at
    for update skip locked
  loop
    perform public.cancel_product_order_checkout(item.order_id, 'reservation_expired');
  end loop;

  select * into existing_order
  from public.orders
  where checkout_external_id = p_external_id;
  if found then
    if existing_order.customer_id <> p_customer_id
      or existing_order.payment_status <> 'unpaid'
    then
      raise exception 'Checkout reference cannot be reused';
    end if;
    return jsonb_build_object(
      'order_id', existing_order.id,
      'amount', round(existing_order.total_amount)::integer,
      'created', false
    );
  end if;

  for item in
    select product_id
    from (
      select (entry->>'product_id')::uuid as product_id
      from jsonb_array_elements(p_items) entry
    ) ids
    order by product_id
  loop
    perform 1 from public.products where id = item.product_id for update;
  end loop;

  with requested as (
    select
      (entry->>'product_id')::uuid as product_id,
      sum((entry->>'quantity')::integer)::integer as quantity
    from jsonb_array_elements(p_items) entry
    group by (entry->>'product_id')::uuid
  )
  select count(*), coalesce(round(sum(p.price * requested.quantity)), 0)::integer
  into matching_count, total_xaf
  from requested
  join public.products p on p.id = requested.product_id
  where requested.quantity between 1 and 50
    and p.stock_quantity >= requested.quantity
    and p.in_stock;

  select count(distinct (entry->>'product_id')::uuid)
  into requested_count
  from jsonb_array_elements(p_items) entry;

  if requested_count <> matching_count then
    raise exception 'One or more products are unavailable or quantities are invalid';
  end if;
  if total_xaf < 100 then
    raise exception 'The order total is below the payment minimum';
  end if;

  insert into public.orders (
    customer_id, total_amount, status, payment_status, currency, checkout_external_id
  )
  values (
    p_customer_id, total_xaf, 'pending', 'unpaid', 'XAF', p_external_id
  )
  returning id into created_order_id;

  insert into public.order_items (
    order_id, product_id, product_name, quantity, price, fulfillment_status
  )
  select
    created_order_id,
    p.id,
    p.name,
    requested.quantity,
    p.price,
    'pending'
  from (
    select
      (entry->>'product_id')::uuid as product_id,
      sum((entry->>'quantity')::integer)::integer as quantity
    from jsonb_array_elements(p_items) entry
    group by (entry->>'product_id')::uuid
  ) requested
  join public.products p on p.id = requested.product_id;

  update public.products p
  set stock_quantity = p.stock_quantity - requested.quantity,
      in_stock = (p.stock_quantity - requested.quantity) > 0
  from (
    select
      (entry->>'product_id')::uuid as product_id,
      sum((entry->>'quantity')::integer)::integer as quantity
    from jsonb_array_elements(p_items) entry
    group by (entry->>'product_id')::uuid
  ) requested
  where p.id = requested.product_id;

  insert into public.product_order_payments (
    order_id, customer_id, amount, external_id
  )
  values (created_order_id, p_customer_id, total_xaf, p_external_id);

  return jsonb_build_object(
    'order_id', created_order_id,
    'amount', total_xaf,
    'created', true
  );
end;
$$;

create or replace function public.complete_product_order_payment(p_trans_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  payment public.product_order_payments%rowtype;
begin
  select * into payment
  from public.product_order_payments
  where fapshi_trans_id = p_trans_id
  for update;

  if not found then
    raise exception 'Product order payment not found';
  end if;
  if payment.status = 'paid' then
    return;
  end if;
  if payment.status <> 'pending' then
    raise exception 'Product order payment is not pending';
  end if;
  if payment.inventory_released_at is not null then
    raise exception 'Product reservation has expired';
  end if;

  update public.product_order_payments
  set status = 'paid'
  where id = payment.id;

  update public.orders
  set payment_status = 'paid'
  where id = payment.order_id
    and payment_status = 'unpaid';
end;
$$;

create or replace function public.require_paid_order_before_fulfillment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_role text;
  product_supplier_id uuid;
  order_payment_status text;
begin
  if auth.uid() is null or
    new.fulfillment_status is not distinct from old.fulfillment_status
  then
    return new;
  end if;

  select profile.role, product.supplier_id, customer_order.payment_status
  into actor_role, product_supplier_id, order_payment_status
  from public.orders customer_order
  join public.products product on product.id = new.product_id
  join public.profiles profile on profile.id = auth.uid()
  where customer_order.id = new.order_id;

  if actor_role = 'Supplier'
    and product_supplier_id = auth.uid()
    and order_payment_status is distinct from 'paid'
  then
    raise exception 'A confirmed customer payment is required before fulfillment';
  end if;

  return new;
end;
$$;

drop trigger if exists require_paid_order_before_fulfillment
  on public.order_items;
create trigger require_paid_order_before_fulfillment
  before update on public.order_items
  for each row
  execute function public.require_paid_order_before_fulfillment();

revoke all on function public.create_product_order_checkout(uuid, jsonb, text)
  from public, anon, authenticated;
revoke all on function public.cancel_product_order_checkout(uuid, text)
  from public, anon, authenticated;
revoke all on function public.complete_product_order_payment(text)
  from public, anon, authenticated;
revoke all on function public.require_paid_order_before_fulfillment()
  from public, anon, authenticated;
grant execute on function public.create_product_order_checkout(uuid, jsonb, text)
  to service_role;
grant execute on function public.cancel_product_order_checkout(uuid, text)
  to service_role;
grant execute on function public.complete_product_order_payment(text)
  to service_role;
