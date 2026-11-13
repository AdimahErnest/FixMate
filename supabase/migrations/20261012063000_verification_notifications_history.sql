create table if not exists public.business_verification_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null check (
    event_type in ('submitted', 'approved', 'rejected')
  ),
  note text,
  actor_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists business_verification_history_user_created_idx
  on public.business_verification_history(user_id, created_at desc);

alter table public.business_verification_history enable row level security;
revoke all on public.business_verification_history from anon, authenticated;
grant select on public.business_verification_history to authenticated;

drop policy if exists "Users and admins read verification history"
  on public.business_verification_history;
create policy "Users and admins read verification history"
  on public.business_verification_history for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'Admin'
        and p.account_status = 'active'
    )
  );

create or replace function public.log_business_verification_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  event_note text;
begin
  if new.status is not distinct from old.status
    or new.status not in ('submitted', 'approved', 'rejected')
  then
    return new;
  end if;

  event_note := case
    when new.status = 'rejected' then new.review_note
    else null
  end;

  insert into public.business_verification_history (
    user_id, event_type, note, actor_id, created_at
  )
  values (
    new.user_id,
    new.status,
    event_note,
    case when new.status = 'submitted' then auth.uid() else new.reviewed_by end,
    coalesce(
      case when new.status = 'submitted' then new.submitted_at else new.reviewed_at end,
      now()
    )
  );
  if new.status in ('approved', 'rejected') then
    insert into public.user_notifications (
      user_id, notification_type, title, body, entity_id
    )
    values (
      new.user_id,
      'business_verification_' || new.status,
      case when new.status = 'approved'
        then 'Verification documents approved'
        else 'Verification changes requested'
      end,
      case when new.status = 'approved'
        then 'Your business documents were approved. An active subscription is required to display your verified badge.'
        else 'Please update and resubmit your documents. Admin note: ' || coalesce(new.review_note, 'Review your submitted documents.')
      end,
      new.user_id
    );
  end if;

  return new;
end;
$$;

revoke all on function public.log_business_verification_event()
  from public, anon, authenticated;

drop trigger if exists log_business_verification_event
  on public.business_verifications;
create trigger log_business_verification_event
  after update of status on public.business_verifications
  for each row execute function public.log_business_verification_event();

insert into public.business_verification_history (
  user_id, event_type, note, actor_id, created_at
)
select user_id, 'submitted', null, user_id, submitted_at
from public.business_verifications
where submitted_at is not null
  and not exists (
    select 1 from public.business_verification_history h
    where h.user_id = business_verifications.user_id
      and h.event_type = 'submitted'
      and h.created_at = business_verifications.submitted_at
  );

insert into public.business_verification_history (
  user_id, event_type, note, actor_id, created_at
)
select user_id, status, review_note, reviewed_by, reviewed_at
from public.business_verifications
where status in ('approved', 'rejected')
  and reviewed_at is not null
  and not exists (
    select 1 from public.business_verification_history h
    where h.user_id = business_verifications.user_id
      and h.event_type = business_verifications.status
      and h.created_at = business_verifications.reviewed_at
  );

create table if not exists public.subscription_reminders (
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  reminder_type text not null check (
    reminder_type in ('seven_day', 'one_day', 'expired')
  ),
  notified_at timestamptz not null default now(),
  primary key (subscription_id, reminder_type)
);

alter table public.subscription_reminders enable row level security;
revoke all on public.subscription_reminders from public, anon, authenticated;

create or replace function public.enqueue_subscription_expiry_reminders(
  p_user_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  item record;
  inserted_count integer := 0;
  reminder_value text;
  notification_title text;
  notification_body text;
begin
  for item in
    select candidate.id, candidate.role, candidate.expires_at
    from public.subscriptions candidate
    where candidate.user_id = p_user_id
      and candidate.status = 'active'
      and candidate.expires_at is not null
      and candidate.expires_at <= now() + interval '7 days'
      and candidate.expires_at = (
        select max(current_plan.expires_at)
        from public.subscriptions current_plan
        where current_plan.user_id = p_user_id
        and current_plan.role = candidate.role
          and current_plan.status = 'active'
      )
  loop
    if item.expires_at <= now() then
      reminder_value := 'expired';
      notification_title := 'Subscription expired';
      notification_body := 'Your ' || lower(item.role) ||
        ' subscription has expired. Renew your plan to restore access and listing eligibility.';
    elsif item.expires_at <= now() + interval '1 day' then
      reminder_value := 'one_day';
      notification_title := 'Subscription expires soon';
      notification_body := 'Your ' || lower(item.role) ||
        ' subscription expires within 24 hours. Renew to avoid losing access or listing eligibility.';
    else
      reminder_value := 'seven_day';
      notification_title := 'Subscription renewal reminder';
      notification_body := 'Your ' || lower(item.role) ||
        ' subscription expires within 7 days. Renew to avoid losing access or listing eligibility.';
    end if;

    insert into public.subscription_reminders(subscription_id, reminder_type)
    values (item.id, reminder_value)
    on conflict do nothing;

    if found then
      inserted_count := inserted_count + 1;
      insert into public.user_notifications (
        user_id, notification_type, title, body, entity_id
      )
      values (
        p_user_id,
        'subscription_' || reminder_value,
        notification_title,
        notification_body,
        item.id
      );
    end if;
  end loop;
  return inserted_count;
end;
$$;

revoke all on function public.enqueue_subscription_expiry_reminders(uuid)
  from public, anon, authenticated;
grant execute on function public.enqueue_subscription_expiry_reminders(uuid)
  to service_role;

create or replace function public.create_subscription_expiry_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sign in to check subscription reminders';
  end if;
  return public.enqueue_subscription_expiry_reminders(auth.uid());
end;
$$;

revoke all on function public.create_subscription_expiry_reminders()
  from public, anon;
grant execute on function public.create_subscription_expiry_reminders()
  to authenticated;
