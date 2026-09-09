-- STORAGE DELETE COMPATIBILITY FOR EXISTING PROJECTS
-- The original project uses private.is_admin() for staff checks.
-- Run this once if lesson video objects remain after lesson deletion.

 drop policy if exists lesson_videos_delete_admin on storage.objects;
create policy lesson_videos_delete_admin
on storage.objects for delete to authenticated
using (
  bucket_id = 'lesson-videos'
  and (select private.is_admin())
);

grant delete on table storage.objects to authenticated;
