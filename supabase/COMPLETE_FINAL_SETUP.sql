-- UNIVERSE EASY MATHS - COMPLETE FINAL SETUP
-- Run this in Supabase SQL Editor on the existing project.
-- Does not contain passwords or secret API keys.

create extension if not exists pgcrypto;

-- Roles
alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('student','admin','owner'));

alter table public.profiles
  add column if not exists profile_photo text;

alter table public.chapters
  add column if not exists premium boolean not null default false;

-- Notifications
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null default 'general',
  title text not null,
  message text not null,
  question_id uuid references public.questions(id) on delete cascade,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_created
  on public.notifications(user_id, created_at desc);

-- Helper functions
create schema if not exists private;

create or replace function private.is_staff()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and (role in ('admin','owner') or is_admin = true)
  );
$$;

create or replace function private.is_owner()
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'owner'
  );
$$;

create or replace function private.user_has_lesson_access(p_lesson_id uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and (role in ('admin','owner') or is_admin = true)
  )
  or exists (
    select 1
    from public.lessons l
    join public.course_chapters cc on cc.chapter_id = l.chapter_id
    join public.purchases p on p.course_id = cc.course_id
    where l.id = p_lesson_id
      and p.user_id = (select auth.uid())
      and p.payment_status = 'SUCCESS'
  );
$$;

-- Protect role/admin fields from student edits
create or replace function public.protect_profile_admin_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not (select private.is_staff()) then
    new.role := old.role;
    new.is_admin := old.is_admin;
    new.total_progress := old.total_progress;
    new.subscription_active := old.subscription_active;
    new.email := old.email;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_admin_fields_trigger
  on public.profiles;

create trigger protect_profile_admin_fields_trigger
before update on public.profiles
for each row
execute function public.protect_profile_admin_fields();

-- Profile progress
create or replace function public.refresh_profile_progress(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  total_count integer;
  complete_count integer;
begin
  select count(*)
    into total_count
    from public.lessons
    where published = true;

  select count(*)
    into complete_count
    from public.progress
    where user_id = p_user
      and seen = true;

  update public.profiles
  set total_progress =
    case
      when total_count = 0 then 0
      else round(
        (complete_count::numeric / total_count::numeric) * 100,
        2
      )
    end
  where id = p_user;
end;
$$;

create or replace function public.on_progress_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.refresh_profile_progress(
    coalesce(new.user_id, old.user_id)
  );
  return coalesce(new, old);
end;
$$;

drop trigger if exists progress_refresh_trigger
  on public.progress;

create trigger progress_refresh_trigger
after insert or update or delete
on public.progress
for each row
execute function public.on_progress_change();

-- New-doubt notifications
create or replace function public.notify_new_question()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notifications(
    user_id,
    type,
    title,
    message,
    question_id
  )
  select
    id,
    'new_doubt',
    'New student doubt',
    'A student has submitted a new doubt.',
    new.id
  from public.profiles
  where role in ('admin','owner')
     or is_admin = true;

  return new;
end;
$$;

drop trigger if exists question_new_notification
  on public.questions;

create trigger question_new_notification
after insert on public.questions
for each row
execute function public.notify_new_question();

-- Answer notifications
create or replace function public.notify_answered_question()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.answered = true
     and (
       old.answered = false
       or old.answer is distinct from new.answer
     ) then

    insert into public.notifications(
      user_id,
      type,
      title,
      message,
      question_id
    )
    values (
      new.user_id,
      'doubt_answered',
      'Your doubt has been answered',
      'An Admin/Owner has answered your question.',
      new.id
    );
  end if;

  return new;
end;
$$;

drop trigger if exists question_answer_notification
  on public.questions;

create trigger question_answer_notification
after update on public.questions
for each row
execute function public.notify_answered_question();

-- RLS
alter table public.profiles enable row level security;
alter table public.chapters enable row level security;
alter table public.lessons enable row level security;
alter table public.progress enable row level security;
alter table public.questions enable row level security;
alter table public.courses enable row level security;
alter table public.course_chapters enable row level security;
alter table public.purchases enable row level security;
alter table public.notifications enable row level security;

-- Profiles
drop policy if exists profiles_self_select on public.profiles;
drop policy if exists profiles_staff_select on public.profiles;
drop policy if exists profiles_self_update on public.profiles;

create policy profiles_self_select
on public.profiles
for select to authenticated
using (id = (select auth.uid()));

create policy profiles_staff_select
on public.profiles
for select to authenticated
using ((select private.is_staff()));

create policy profiles_self_update
on public.profiles
for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- Chapters
drop policy if exists chapters_public_select on public.chapters;
drop policy if exists chapters_staff_all on public.chapters;

create policy chapters_public_select
on public.chapters
for select to anon, authenticated
using (
  published = true
  or (select private.is_staff())
);

create policy chapters_staff_all
on public.chapters
for all to authenticated
using ((select private.is_staff()))
with check ((select private.is_staff()));

-- Lessons
drop policy if exists lessons_select on public.lessons;
drop policy if exists lessons_staff_all on public.lessons;

create policy lessons_select
on public.lessons
for select to anon, authenticated
using (
  (
    published = true
    and (
      premium = false
      or (select private.user_has_lesson_access(id))
    )
  )
  or (select private.is_staff())
);

create policy lessons_staff_all
on public.lessons
for all to authenticated
using ((select private.is_staff()))
with check ((select private.is_staff()));

-- Progress
drop policy if exists progress_self_select on public.progress;
drop policy if exists progress_self_insert on public.progress;
drop policy if exists progress_self_update on public.progress;
drop policy if exists progress_self_delete on public.progress;
drop policy if exists progress_staff_all on public.progress;

create policy progress_self_select
on public.progress
for select to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_staff())
);

create policy progress_self_insert
on public.progress
for insert to authenticated
with check (user_id = (select auth.uid()));

create policy progress_self_update
on public.progress
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy progress_self_delete
on public.progress
for delete to authenticated
using (user_id = (select auth.uid()));

create policy progress_staff_all
on public.progress
for all to authenticated
using ((select private.is_staff()))
with check ((select private.is_staff()));

-- Questions
drop policy if exists questions_select_private on public.questions;
drop policy if exists questions_insert_self on public.questions;
drop policy if exists questions_update_staff on public.questions;
drop policy if exists questions_delete_self on public.questions;
drop policy if exists questions_staff_all on public.questions;

create policy questions_select_private
on public.questions
for select to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_staff())
);

create policy questions_insert_self
on public.questions
for insert to authenticated
with check (user_id = (select auth.uid()));

create policy questions_update_staff
on public.questions
for update to authenticated
using ((select private.is_staff()))
with check ((select private.is_staff()));

create policy questions_delete_self
on public.questions
for delete to authenticated
using (user_id = (select auth.uid()));

create policy questions_staff_all
on public.questions
for all to authenticated
using ((select private.is_staff()))
with check ((select private.is_staff()));

-- Courses
drop policy if exists courses_select on public.courses;
drop policy if exists courses_staff_all on public.courses;

create policy courses_select
on public.courses
for select to anon, authenticated
using (
  published = true
  or (select private.is_staff())
);

create policy courses_staff_all
on public.courses
for all to authenticated
using ((select private.is_staff()))
with check ((select private.is_staff()));

-- Course chapters
drop policy if exists course_chapters_select on public.course_chapters;
drop policy if exists course_chapters_staff_all on public.course_chapters;

create policy course_chapters_select
on public.course_chapters
for select to anon, authenticated
using (true);

create policy course_chapters_staff_all
on public.course_chapters
for all to authenticated
using ((select private.is_staff()))
with check ((select private.is_staff()));

-- Purchases
drop policy if exists purchases_self_select on public.purchases;
drop policy if exists purchases_staff_all on public.purchases;

create policy purchases_self_select
on public.purchases
for select to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_staff())
);

create policy purchases_staff_all
on public.purchases
for all to authenticated
using ((select private.is_staff()))
with check ((select private.is_staff()));

-- Notifications
drop policy if exists notifications_self_select on public.notifications;
drop policy if exists notifications_self_update on public.notifications;

create policy notifications_self_select
on public.notifications
for select to authenticated
using (user_id = (select auth.uid()));

create policy notifications_self_update
on public.notifications
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- Grants
grant select, update on public.profiles to authenticated;
grant select on public.chapters, public.lessons,
  public.courses, public.course_chapters
  to anon, authenticated;
grant select, insert, update, delete
  on public.progress to authenticated;
grant select, insert, update, delete
  on public.questions to authenticated;
grant select, insert, update, delete
  on public.courses to authenticated;
grant select, insert, update, delete
  on public.chapters to authenticated;
grant select, insert, update, delete
  on public.lessons to authenticated;
grant select, insert, update, delete
  on public.course_chapters to authenticated;
grant select on public.purchases to authenticated;
grant select, update on public.notifications to authenticated;

-- Realtime
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime
      add table public.notifications;
  end if;
exception
  when undefined_object then
    null;
end $$;
