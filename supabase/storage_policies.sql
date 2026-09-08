drop policy if exists "staff_upload_lesson_videos" on storage.objects;
drop policy if exists "staff_update_lesson_videos" on storage.objects;
drop policy if exists "staff_delete_lesson_videos" on storage.objects;
drop policy if exists "student_upload_own_profile_photo" on storage.objects;
drop policy if exists "student_read_own_profile_photo" on storage.objects;
drop policy if exists "student_delete_own_profile_photo" on storage.objects;
drop policy if exists "student_upload_own_doubt_image" on storage.objects;
drop policy if exists "student_read_doubt_image" on storage.objects;
drop policy if exists "student_delete_own_doubt_image" on storage.objects;

-- Private storage buckets and policies for Universe Easy Maths.
-- Create these buckets in Dashboard first if they do not exist:
-- profile-photos, doubt-images, lesson-videos

create policy "staff_upload_lesson_videos"
on storage.objects for insert to authenticated
with check (bucket_id = 'lesson-videos' and (select private.is_staff()));

create policy "staff_update_lesson_videos"
on storage.objects for update to authenticated
using (bucket_id = 'lesson-videos' and (select private.is_staff()))
with check (bucket_id = 'lesson-videos' and (select private.is_staff()));

create policy "staff_delete_lesson_videos"
on storage.objects for delete to authenticated
using (bucket_id = 'lesson-videos' and (select private.is_staff()));

create policy "student_upload_own_profile_photo"
on storage.objects for insert to authenticated
with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "student_read_own_profile_photo"
on storage.objects for select to authenticated
using (bucket_id = 'profile-photos' and ((storage.foldername(name))[1] = (select auth.uid())::text or (select private.is_staff())));

create policy "student_delete_own_profile_photo"
on storage.objects for delete to authenticated
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "student_upload_own_doubt_image"
on storage.objects for insert to authenticated
with check (bucket_id = 'doubt-images' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "student_read_doubt_image"
on storage.objects for select to authenticated
using (bucket_id = 'doubt-images' and ((storage.foldername(name))[1] = (select auth.uid())::text or (select private.is_staff())));

create policy "student_delete_own_doubt_image"
on storage.objects for delete to authenticated
using (bucket_id = 'doubt-images' and (storage.foldername(name))[1] = (select auth.uid())::text);
