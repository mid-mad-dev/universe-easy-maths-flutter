-- UNIVERSE EASY MATHS - PUSH TOKENS + QUESTION DELETE FIX
-- Run this in the Supabase SQL Editor on the existing project.
-- Safe to re-run: every statement is idempotent.
-- Does not contain passwords or secret API keys.

-- ============================================================
-- 1. FIX DELETION: cascade notifications when a doubt is deleted
-- ============================================================
-- Older "create table if not exists" scripts never altered an existing
-- notifications table, so a pre-existing FK WITHOUT "on delete cascade"
-- blocks every "delete from questions" that an admin was notified about
-- (foreign key violation). Rebuild the constraint to cascade.

alter table public.notifications
  drop constraint if exists notifications_question_id_fkey;

alter table public.notifications
  add constraint notifications_question_id_fkey
  foreign key (question_id) references public.questions(id)
  on delete cascade;

-- Also cascade profile deletions defensively (manage-user edge function
-- deletes profiles + notifications already, but be safe).
alter table public.notifications
  drop constraint if exists notifications_user_id_fkey;

alter table public.notifications
  add constraint notifications_user_id_fkey
  foreign key (user_id) references public.profiles(id)
  on delete cascade;

-- ============================================================
-- 2. PUSH TOKEN REGISTRY
-- ============================================================
create table if not exists public.push_tokens (
  token text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null default 'android',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.push_tokens enable row level security;

drop policy if exists push_tokens_self_select on public.push_tokens;
drop policy if exists push_tokens_self_insert on public.push_tokens;
drop policy if exists push_tokens_self_update on public.push_tokens;
drop policy if exists push_tokens_self_delete on public.push_tokens;

create policy push_tokens_self_select
on public.push_tokens
for select to authenticated
using (user_id = (select auth.uid()));

create policy push_tokens_self_insert
on public.push_tokens
for insert to authenticated
with check (user_id = (select auth.uid()));

create policy push_tokens_self_update
on public.push_tokens
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy push_tokens_self_delete
on public.push_tokens
for delete to authenticated
using (user_id = (select auth.uid()));

grant select, insert, update, delete on public.push_tokens to authenticated;

-- Reassign tokens after a logout/login round-trip so a device always
-- ends up owned by the currently signed-in user. Callable as the
-- caller via the upsert policy above.
create or replace function public.register_push_token(p_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;
  if p_token is null or length(trim(p_token)) = 0 then
    raise exception 'Token is required';
  end if;

  insert into public.push_tokens (token, user_id, platform)
  values (trim(p_token), v_user, coalesce(nullif(trim(p_platform), ''), 'android'))
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

grant execute on function public.register_push_token(text, text) to authenticated;

-- ============================================================
-- 3. Realtime for push_tokens is NOT needed; skip.
-- ============================================================
