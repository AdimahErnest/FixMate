create or replace function public.lookup_profile_user_by_phone(p_phone text)
returns table (user_id uuid)
language sql
security definer
set search_path = public
as $$
  with supplied as (
    select regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g') as digits
  ),
  target as (
    select case
      when digits like '237%' and length(digits) = 12 then right(digits, 9)
      when digits like '0%' and length(digits) = 10 then right(digits, 9)
      when length(digits) = 9 then digits
      else null
    end as phone
    from supplied
  ),
  matches as (
    select p.id
    from public.profiles p
    cross join lateral (
      select regexp_replace(coalesce(p.phone, ''), '[^0-9]', '', 'g') as digits
    ) stored
    cross join lateral (
      select case
        when stored.digits like '237%' and length(stored.digits) = 12 then right(stored.digits, 9)
        when stored.digits like '0%' and length(stored.digits) = 10 then right(stored.digits, 9)
        when length(stored.digits) = 9 then stored.digits
        else null
      end as phone
    ) normalized
    cross join target
    where target.phone is not null
      and normalized.phone = target.phone
    limit 2
  )
  select id from matches;
$$;

revoke all on function public.lookup_profile_user_by_phone(text) from public, anon, authenticated;
grant execute on function public.lookup_profile_user_by_phone(text) to service_role;

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('Technician', 'Supplier')),
  plan text not null check (plan in ('monthly', 'yearly')),
  amount integer not null check (amount >= 100),
  usd_amount numeric(10, 2) not null check (usd_amount > 0),
  usd_to_xaf_rate numeric(14, 6) not null check (usd_to_xaf_rate > 0),
  external_id text not null unique,
  fapshi_trans_id text not null unique,
  status text not null default 'pending'
    check (status in ('pending', 'active', 'failed', 'expired')),
  started_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.subscriptions
  add column if not exists usd_amount numeric(10, 2),
  add column if not exists usd_to_xaf_rate numeric(14, 6);

create index if not exists subscriptions_user_status_idx
  on public.subscriptions(user_id, status, expires_at desc);

alter table public.subscriptions enable row level security;
grant select on table public.subscriptions to authenticated;
grant all on table public.subscriptions to service_role;

drop policy if exists "Users can read their subscriptions" on public.subscriptions;
create policy "Users can read their subscriptions"
  on public.subscriptions
  for select
  to authenticated
  using (auth.uid() = user_id);

create or replace function public.activate_subscription(p_trans_id text)
returns setof public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  payment public.subscriptions%rowtype;
  extension_days integer;
  renewal_start timestamptz;
begin
  select * into payment
  from public.subscriptions
  where fapshi_trans_id = p_trans_id
  for update;

  if not found then
    raise exception 'Subscription transaction not found';
  end if;

  if payment.status = 'active' then
    return next payment;
    return;
  end if;

  if payment.status <> 'pending' then
    raise exception 'Subscription transaction is not pending';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(payment.user_id::text, 0));

  select greatest(now(), coalesce(max(expires_at), now()))
  into renewal_start
  from public.subscriptions
  where user_id = payment.user_id
    and status = 'active';

  extension_days := case payment.plan when 'yearly' then 365 else 30 end;

  update public.subscriptions
  set status = 'active',
      started_at = renewal_start,
      expires_at = renewal_start + make_interval(days => extension_days)
  where id = payment.id
  returning * into payment;

  return next payment;
end;
$$;

revoke all on function public.activate_subscription(text) from public, anon, authenticated;
grant execute on function public.activate_subscription(text) to service_role;
