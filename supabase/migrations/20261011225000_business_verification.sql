create table if not exists public.business_verifications (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('Technician', 'Supplier')),
  status text not null default 'not_started'
    check (status in ('not_started', 'submitted', 'approved', 'rejected')),
  required_services text[] not null default '{}',
  created_at timestamptz not null default now(),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  review_note text
);

create table if not exists public.business_verification_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  document_key text not null,
  document_type text not null check (document_type in (
    'technician_license',
    'criminal_record',
    'government_id_front',
    'government_id_back',
    'government_id_holding',
    'location_plan',
    'registration_certificate',
    'tax_identification'
  )),
  service_name text,
  storage_path text not null,
  created_at timestamptz not null default now(),
  unique (user_id, document_key),
  foreign key (user_id) references public.business_verifications(user_id)
    on delete cascade,
  check (split_part(storage_path, '/', 1) = user_id::text)
);

insert into public.business_verifications (
  user_id, role, created_at, required_services
)
select p.id, p.role, u.created_at,
       coalesce(array(
         select jsonb_array_elements_text(
           case
             when jsonb_typeof(u.raw_user_meta_data -> 'services') = 'array'
               then u.raw_user_meta_data -> 'services'
             else '[]'::jsonb
           end
         )
       ), '{}')
from public.profiles p
join auth.users u on u.id = p.id
where p.role in ('Technician', 'Supplier')
on conflict (user_id) do nothing;

alter table public.business_verifications enable row level security;
alter table public.business_verifications
  add column if not exists tax_identification_number text;
alter table public.business_verification_documents enable row level security;

revoke all on public.business_verifications from anon, authenticated;
revoke all on public.business_verification_documents from anon, authenticated;
grant select on public.business_verifications to authenticated;
grant select, insert, update on public.business_verification_documents
  to authenticated;

drop policy if exists "Owners read own business verification"
  on public.business_verifications;
create policy "Owners read own business verification"
  on public.business_verifications for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "Owners read own verification documents"
  on public.business_verification_documents;
create policy "Owners read own verification documents"
  on public.business_verification_documents for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "Owners add verification documents before review"
  on public.business_verification_documents;
create policy "Owners add verification documents before review"
  on public.business_verification_documents for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.business_verifications v
      where v.user_id = auth.uid()
        and v.status in ('not_started', 'rejected')
    )
  );

drop policy if exists "Owners update verification documents before review"
  on public.business_verification_documents;
create policy "Owners update verification documents before review"
  on public.business_verification_documents for update to authenticated
  using (
    user_id = auth.uid()
    and exists (
      select 1 from public.business_verifications v
      where v.user_id = auth.uid()
        and v.status in ('not_started', 'rejected')
    )
  )
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.business_verifications v
      where v.user_id = auth.uid()
        and v.status in ('not_started', 'rejected')
    )
    and split_part(storage_path, '/', 1) = auth.uid()::text
  );

create or replace function public.validate_business_verification_document()
returns trigger
language plpgsql
security definer
set search_path = public, storage
as $$
begin
  if new.document_type = 'technician_license' then
    if new.document_key <> 'technician_license|' || coalesce(new.service_name, '') then
      raise exception 'Technician license document must match its registered service';
    end if;
  elsif new.document_key <> new.document_type or new.service_name is not null then
    raise exception 'Verification document key does not match its document type';
  end if;

  if not exists (
    select 1 from storage.objects o
    where o.bucket_id = 'business-verification'
      and o.name = new.storage_path
      and (storage.foldername(o.name))[1] = new.user_id::text
  ) then
    raise exception 'Upload the private verification file before registering it';
  end if;

  return new;
end;
$$;

drop trigger if exists validate_business_verification_document
  on public.business_verification_documents;
create trigger validate_business_verification_document
before insert or update on public.business_verification_documents
for each row execute function public.validate_business_verification_document();

revoke all on function public.validate_business_verification_document()
  from public, anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'business-verification',
  'business-verification',
  false,
  15728640,
  array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Owners and admins read verification files"
  on storage.objects;
create policy "Owners and admins read verification files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'business-verification'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.role = 'Admin'
      )
    )
  );

drop policy if exists "Owners upload verification files before review"
  on storage.objects;
create policy "Owners upload verification files before review"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'business-verification'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.business_verifications v
      where v.user_id = auth.uid()
        and v.status in ('not_started', 'rejected')
    )
  );

drop policy if exists "Owners update verification files before review"
  on storage.objects;
create policy "Owners update verification files before review"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'business-verification'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.business_verifications v
      where v.user_id = auth.uid()
        and v.status in ('not_started', 'rejected')
    )
  )
  with check (
    bucket_id = 'business-verification'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.business_verifications v
      where v.user_id = auth.uid()
        and v.status in ('not_started', 'rejected')
    )
  );

drop policy if exists "Owners delete verification files before review"
  on storage.objects;
create policy "Owners delete verification files before review"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'business-verification'
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.business_verifications v
      where v.user_id = auth.uid()
        and v.status in ('not_started', 'rejected')
    )
  );

create or replace function public.initialize_business_verification()
returns public.business_verifications
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  actor_role text;
  created timestamptz;
  services text[];
  result public.business_verifications%rowtype;
begin
  if actor is null then
    raise exception 'Sign in to load business verification';
  end if;

  select coalesce(
    (select p.role from public.profiles p where p.id = actor),
    (select u.raw_user_meta_data ->> 'role' from auth.users u where u.id = actor)
  ), (select u.created_at from auth.users u where u.id = actor),
  coalesce(array(
    select jsonb_array_elements_text(
      case
        when jsonb_typeof((
          select u.raw_user_meta_data -> 'services'
          from auth.users u where u.id = actor
        )) = 'array'
          then (
            select u.raw_user_meta_data -> 'services'
            from auth.users u where u.id = actor
          )
        else '[]'::jsonb
      end
    )
  ), '{}')
  into actor_role, created, services;

  if actor_role not in ('Technician', 'Supplier') then
    return null;
  end if;

  insert into public.business_verifications (
    user_id, role, created_at, required_services
  )
  values (actor, actor_role, coalesce(created, now()), services)
  on conflict (user_id) do nothing;

  select * into result
  from public.business_verifications
  where user_id = actor;
  return result;
end;
$$;

revoke all on function public.initialize_business_verification()
  from public, anon;
grant execute on function public.initialize_business_verification()
  to authenticated;

create or replace function public.submit_business_verification(
  p_tax_identification_number text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  verification public.business_verifications%rowtype;
  required_keys text[];
begin
  if actor is null then
    raise exception 'Sign in to submit verification documents';
  end if;

  select * into verification
  from public.business_verifications
  where user_id = actor
  for update;

  if not found or verification.status not in ('not_started', 'rejected') then
    raise exception 'Verification documents cannot be submitted in the current state';
  end if;

  if verification.role = 'Technician' then
    required_keys := array[
      'criminal_record',
      'government_id_front',
      'government_id_back',
      'government_id_holding',
      'location_plan'
    ];
    if coalesce(array_length(verification.required_services, 1), 0) = 0 then
      raise exception 'Registered technician services could not be verified';
    end if;
    if exists (
      select 1
      from unnest(verification.required_services) service_name
      where not exists (
        select 1 from public.business_verification_documents d
        where d.user_id = actor
          and d.document_key = 'technician_license|' || service_name
      )
    ) then
      raise exception 'Provide a certificate or license for every registered service';
    end if;
  else
    if nullif(btrim(p_tax_identification_number), '') is null then
      raise exception 'Enter the company tax identification number';
    end if;
    required_keys := array[
      'registration_certificate',
      'location_plan'
    ];
  end if;

  if exists (
    select 1 from unnest(required_keys) required_key
    where not exists (
      select 1 from public.business_verification_documents d
      where d.user_id = actor and d.document_key = required_key
    )
  ) then
    raise exception 'All required verification documents must be uploaded';
  end if;

  update public.business_verifications
  set status = 'submitted',
      submitted_at = now(),
      reviewed_at = null,
      reviewed_by = null,
      review_note = null,
      tax_identification_number = case
        when role = 'Supplier' then btrim(p_tax_identification_number)
        else tax_identification_number
      end
  where user_id = actor;
end;
$$;

revoke all on function public.submit_business_verification(text)
  from public, anon;
grant execute on function public.submit_business_verification(text)
  to authenticated;

create or replace function public.admin_list_business_verifications()
returns table (
  user_id uuid,
  role text,
  status text,
  full_name text,
  email text,
  submitted_at timestamptz,
  review_note text,
  tax_identification_number text,
  documents jsonb
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'Admin'
  ) then
    raise exception 'Admin access required';
  end if;

  return query
  select v.user_id, v.role, v.status, p.full_name, p.email,
         v.submitted_at, v.review_note, v.tax_identification_number,
         coalesce(
           jsonb_agg(jsonb_build_object(
             'document_key', d.document_key,
             'document_type', d.document_type,
             'service_name', d.service_name,
             'storage_path', d.storage_path
           )) filter (where d.id is not null),
           '[]'::jsonb
         )
  from public.business_verifications v
  join public.profiles p on p.id = v.user_id
  left join public.business_verification_documents d on d.user_id = v.user_id
  where v.status in ('submitted', 'rejected')
  group by v.user_id, v.role, v.status, p.full_name, p.email,
           v.submitted_at, v.review_note, v.tax_identification_number
  order by v.submitted_at nulls last;
end;
$$;

revoke all on function public.admin_list_business_verifications()
  from public, anon;
grant execute on function public.admin_list_business_verifications()
  to authenticated;

create or replace function public.admin_review_business_verification(
  p_user_id uuid,
  p_decision text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'Admin'
  ) then
    raise exception 'Admin access required';
  end if;
  if p_decision not in ('approved', 'rejected') then
    raise exception 'Review decision must be approved or rejected';
  end if;

  update public.business_verifications
  set status = p_decision,
      reviewed_at = now(),
      reviewed_by = auth.uid(),
      review_note = nullif(btrim(p_note), '')
  where user_id = p_user_id and status in ('submitted', 'rejected');

  if not found then
    raise exception 'No reviewable business verification was found';
  end if;
end;
$$;

revoke all on function public.admin_review_business_verification(uuid, text, text)
  from public, anon;
grant execute on function public.admin_review_business_verification(uuid, text, text)
  to authenticated;

create or replace view public.active_business_profiles
with (security_barrier = true)
as
select eligible.provider_id, eligible.role, eligible.verified
from (
  select v.user_id as provider_id,
         v.role,
         (
           v.status = 'approved'
           and exists (
             select 1 from public.subscriptions s
             where s.user_id = v.user_id
               and s.role = v.role
               and s.status = 'active'
               and s.expires_at > now()
           )
         ) as verified
  from public.business_verifications v
  where
    (v.role = 'Technician' and (
      v.created_at > now() - interval '7 days'
      or v.status in ('submitted', 'approved', 'rejected')
      or exists (
        select 1 from public.subscriptions s
        where s.user_id = v.user_id
          and s.role = 'Technician'
          and s.status = 'active'
          and s.expires_at > now()
      )
    ))
    or (
      v.role = 'Supplier'
      and v.status = 'approved'
      and exists (
        select 1 from public.subscriptions s
        where s.user_id = v.user_id
          and s.role = 'Supplier'
          and s.status = 'active'
          and s.expires_at > now()
      )
    )
) eligible;

grant select on public.active_business_profiles to anon, authenticated;

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
      select 1 from public.business_verifications v
      where v.user_id = acting_user and v.role = 'Supplier'
        and v.status = 'approved'
    ) then
      raise exception 'Supplier documents require admin approval';
    end if;
    if acting_role = 'Supplier' and not exists (
      select 1 from public.subscriptions s
      where s.user_id = acting_user
        and s.role = 'Supplier'
        and s.status = 'active'
        and s.expires_at > now()
    ) then
      raise exception 'An active supplier subscription is required';
    end if;
  elsif tg_table_name = 'service_requests' then
    if tg_op = 'INSERT' and not exists (
      select 1 from public.subscriptions s
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
        select 1 from public.subscriptions s
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
    then
      if not exists (
        select 1 from public.business_verifications v
        where v.user_id = acting_user and v.role = 'Supplier'
          and v.status = 'approved'
      ) then
        raise exception 'Supplier documents require admin approval';
      end if;
      if not exists (
        select 1 from public.subscriptions s
        where s.user_id = acting_user
          and s.role = 'Supplier'
          and s.status = 'active'
          and s.expires_at > now()
      ) then
        raise exception 'An active supplier subscription is required';
      end if;
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_business_subscription()
  from public, anon, authenticated;
