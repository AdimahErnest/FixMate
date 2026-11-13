create table if not exists public.business_verification_audit (
  id uuid primary key default gen_random_uuid(),
  target_user_id uuid not null,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null check (
    event_type in (
      'submitted',
      'approved',
      'rejected',
      'document_access',
      'retention_delete'
    )
  ),
  document_key text,
  created_at timestamptz not null default now()
);

create index if not exists business_verification_audit_target_created_idx
  on public.business_verification_audit(target_user_id, created_at desc);

alter table public.business_verification_audit enable row level security;
revoke all on public.business_verification_audit from public, anon, authenticated;
grant select on public.business_verification_audit to authenticated;
grant all on public.business_verification_audit to service_role;

drop policy if exists "Active admins read verification audit"
  on public.business_verification_audit;
create policy "Active admins read verification audit"
  on public.business_verification_audit for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'Admin'
        and p.account_status = 'active'
    )
  );

create or replace function public.log_business_verification_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is not distinct from old.status
    or new.status not in ('submitted', 'approved', 'rejected')
  then
    return new;
  end if;

  insert into public.business_verification_audit (
    target_user_id, actor_id, event_type, created_at
  )
  values (
    new.user_id,
    case when new.status = 'submitted' then auth.uid() else new.reviewed_by end,
    new.status,
    coalesce(
      case when new.status = 'submitted' then new.submitted_at else new.reviewed_at end,
      now()
    )
  );
  return new;
end;
$$;

revoke all on function public.log_business_verification_audit()
  from public, anon, authenticated;

drop trigger if exists log_business_verification_audit
  on public.business_verifications;
create trigger log_business_verification_audit
  after update of status on public.business_verifications
  for each row execute function public.log_business_verification_audit();

insert into public.business_verification_audit (
  target_user_id, actor_id, event_type, created_at
)
select user_id,
       case when status = 'submitted' then user_id else reviewed_by end,
       status,
       case when status = 'submitted' then submitted_at else reviewed_at end
from public.business_verifications v
where status in ('submitted', 'approved', 'rejected')
  and case when status = 'submitted' then submitted_at else reviewed_at end is not null
  and not exists (
    select 1 from public.business_verification_audit a
    where a.target_user_id = v.user_id
      and a.event_type = v.status
      and a.created_at = case
        when v.status = 'submitted' then v.submitted_at
        else v.reviewed_at
      end
  );

create or replace function public.audit_business_verification_document_access(
  p_storage_path text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  document_owner uuid;
  document_key_value text;
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = actor and p.role = 'Admin' and p.account_status = 'active'
  ) then
    raise exception 'Active admin access required';
  end if;

  select d.user_id, d.document_key
    into document_owner, document_key_value
  from public.business_verification_documents d
  where d.storage_path = p_storage_path;
  if not found then
    raise exception 'Verification document not found';
  end if;

  insert into public.business_verification_audit (
    target_user_id, actor_id, event_type, document_key
  )
  values (document_owner, actor, 'document_access', document_key_value);
end;
$$;

revoke all on function public.audit_business_verification_document_access(text)
  from public, anon;
grant execute on function public.audit_business_verification_document_access(text)
  to authenticated;

create or replace function public.admin_list_business_verification_audit()
returns table (
  target_user_id uuid,
  target_name text,
  actor_id uuid,
  actor_name text,
  event_type text,
  document_key text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'Admin'
      and p.account_status = 'active'
  ) then
    raise exception 'Active admin access required';
  end if;

  return query
  select a.target_user_id, target.full_name, a.actor_id, actor.full_name,
         a.event_type, a.document_key, a.created_at
  from public.business_verification_audit a
  left join public.profiles target on target.id = a.target_user_id
  left join public.profiles actor on actor.id = a.actor_id
  order by a.created_at desc
  limit 200;
end;
$$;

revoke all on function public.admin_list_business_verification_audit()
  from public, anon;
grant execute on function public.admin_list_business_verification_audit()
  to authenticated;

create or replace function public.list_business_verification_documents_for_retention(
  p_reviewed_before timestamptz,
  p_limit integer default 500
)
returns table (
  id uuid,
  user_id uuid,
  document_key text,
  storage_path text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_limit < 1 or p_limit > 1000 then
    raise exception 'Retention batch size must be between 1 and 1000';
  end if;

  return query
  select d.id, d.user_id, d.document_key, d.storage_path
  from public.business_verification_documents d
  join public.business_verifications v on v.user_id = d.user_id
  where v.status in ('approved', 'rejected')
    and v.reviewed_at < p_reviewed_before
  order by d.id
  limit p_limit;
end;
$$;

revoke all on function public.list_business_verification_documents_for_retention(
  timestamptz, integer
) from public, anon, authenticated;
grant execute on function public.list_business_verification_documents_for_retention(
  timestamptz, integer
) to service_role;

create or replace function public.run_subscription_expiry_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  account record;
  inserted_count integer := 0;
begin
  for account in
    select distinct user_id
    from public.subscriptions
    where status = 'active'
      and expires_at is not null
      and expires_at <= now() + interval '7 days'
  loop
    inserted_count := inserted_count +
      public.enqueue_subscription_expiry_reminders(account.user_id);
  end loop;
  return inserted_count;
end;
$$;

revoke all on function public.run_subscription_expiry_reminders()
  from public, anon, authenticated;
grant execute on function public.run_subscription_expiry_reminders()
  to service_role;

create extension if not exists pg_cron;

do $$
declare
  existing_job record;
begin
  for existing_job in
    select jobid from cron.job
    where jobname = 'fixmate-subscription-expiry-reminders'
  loop
    perform cron.unschedule(existing_job.jobid);
  end loop;
  perform cron.schedule(
    'fixmate-subscription-expiry-reminders',
    '0 8 * * *',
    'select public.run_subscription_expiry_reminders();'
  );
end;
$$;
