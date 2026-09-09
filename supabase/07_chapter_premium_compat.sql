-- Restore the chapter field used by the admin and student clients.
-- Safe to run more than once.

alter table public.chapters
  add column if not exists premium boolean not null default false;
