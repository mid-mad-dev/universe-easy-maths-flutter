-- Restore admin delete privileges for chapters and courses.
-- RLS policies still restrict these operations to staff users.
-- Safe to run more than once.

grant select, insert, update, delete on public.chapters to authenticated;
grant select, insert, update, delete on public.courses to authenticated;
grant select, insert, update, delete on public.course_chapters to authenticated;
