create or replace function public.normalize_cameroon_phone(p_phone text)
returns text
language sql
immutable
parallel safe
as $$
  with digits as (
    select regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g') as value
  ),
  normalized as (
    select case
      when value like '237%' and length(value) = 12 then substr(value, 4)
      when value like '0%' and length(value) = 10 then substr(value, 2)
      when length(value) = 9 then value
      else null
    end as value
    from digits
  )
  select case when value ~ '^[26][0-9]{8}$' then value else null end
  from normalized;
$$;

do $$
begin
  if exists (
    select public.normalize_cameroon_phone(phone)
    from public.profiles
    where public.normalize_cameroon_phone(phone) is not null
    group by public.normalize_cameroon_phone(phone)
    having count(*) > 1
  ) then
    raise exception
      'Duplicate Cameroon phone numbers exist in profiles; resolve duplicates before applying signup phone uniqueness.';
  end if;
end;
$$;

create unique index if not exists profiles_phone_cm_unique_idx
  on public.profiles (public.normalize_cameroon_phone(phone))
  where public.normalize_cameroon_phone(phone) is not null;
