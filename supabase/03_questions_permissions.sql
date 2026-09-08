-- Restore client privileges for doubt operations.
-- Run this once in the Supabase SQL Editor for the existing project.
-- RLS policies still decide which authenticated users may access each row.

grant select, insert, update, delete
on table public.questions
to authenticated;
