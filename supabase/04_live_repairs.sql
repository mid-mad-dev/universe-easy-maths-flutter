-- LIVE REPAIRS FOR LESSON DELETION AND NOTIFICATIONS
-- Run this once in the Supabase SQL Editor on the production project.
-- Safe to run more than once.

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

alter table public.notifications enable row level security;

-- PostgREST privileges required by the authenticated Flutter clients.
grant select, insert, update, delete on public.lessons to authenticated;
grant select, insert, update, delete on public.questions to authenticated;
grant select, update on public.notifications to authenticated;

-- Deleting a doubt must not be blocked by its notification history.
alter table public.notifications
drop constraint if exists notifications_question_id_fkey;

alter table public.notifications
add constraint notifications_question_id_fkey
foreign key (question_id) references public.questions(id) on delete cascade;

-- Keep notification rows available to their owner and writable only by them.
drop policy if exists notifications_self_select on public.notifications;
drop policy if exists notifications_self_update on public.notifications;

create policy notifications_self_select
on public.notifications for select to authenticated
using (user_id = (select auth.uid()));

create policy notifications_self_update
on public.notifications for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- Recreate the database-side events so notifications are generated for every
-- client, including web, without relying on a particular app instance.
create or replace function public.notify_new_question()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notifications(user_id, type, title, message, question_id)
  select id, 'new_doubt', 'New student doubt',
         'A student has submitted a new doubt.', new.id
  from public.profiles
  where role in ('admin', 'owner') or is_admin = true;
  return new;
end;
$$;

drop trigger if exists question_new_notification on public.questions;
create trigger question_new_notification
after insert on public.questions
for each row execute function public.notify_new_question();

create or replace function public.notify_answered_question()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.answered = true
     and (coalesce(old.answered, false) = false
          or old.answer is distinct from new.answer) then
    insert into public.notifications(user_id, type, title, message, question_id)
    values (new.user_id, 'doubt_answered', 'Your doubt has been answered',
            'An Admin/Owner has answered your question.', new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists question_answer_notification on public.questions;
create trigger question_answer_notification
after update on public.questions
for each row execute function public.notify_answered_question();

-- Enable realtime for the notification list when the publication exists.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
exception when undefined_object then
  null;
end;
$$;
