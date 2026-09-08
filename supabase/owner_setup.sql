-- Run after the owner account has been created in Supabase Auth.
update public.profiles
set role = 'owner', is_admin = true
where lower(email) = lower('midhunmadhuorg@gmail.com');

select id, name, email, role, is_admin, subscription_active, total_progress
from public.profiles
where lower(email) = lower('midhunmadhuorg@gmail.com');
