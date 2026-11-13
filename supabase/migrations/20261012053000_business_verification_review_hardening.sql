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
  if p_decision is null or p_decision not in ('approved', 'rejected') then
    raise exception 'Review decision must be approved or rejected';
  end if;
  if p_note is not null and char_length(p_note) > 500 then
    raise exception 'Review notes must be 500 characters or fewer';
  end if;
  if p_decision = 'rejected' and nullif(btrim(p_note), '') is null then
    raise exception 'Explain which verification documents need correction';
  end if;

  update public.business_verifications
  set status = p_decision,
      reviewed_at = now(),
      reviewed_by = auth.uid(),
      review_note = nullif(btrim(p_note), '')
  where user_id = p_user_id and status = 'submitted';

  if not found then
    raise exception 'Only newly submitted verification documents can be reviewed';
  end if;
end;
$$;

revoke all on function public.admin_review_business_verification(uuid, text, text)
  from public, anon;
grant execute on function public.admin_review_business_verification(uuid, text, text)
  to authenticated;
