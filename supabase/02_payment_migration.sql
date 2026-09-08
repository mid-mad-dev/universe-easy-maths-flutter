-- UNIVERSE EASY MATHS - PAYMENT MIGRATION
-- Run after 01_schema_permissions_notifications.sql.

alter table public.purchases
  add column if not exists razorpay_order_id text,
  add column if not exists razorpay_signature text,
  add column if not exists gateway_payment_status text,
  add column if not exists payment_date timestamptz;

create unique index if not exists purchases_razorpay_order_id_uidx
  on public.purchases(razorpay_order_id)
  where razorpay_order_id is not null;

-- Never allow the mobile/browser client to manufacture a purchase.
drop policy if exists purchases_self_insert on public.purchases;
drop policy if exists purchases_self_update on public.purchases;

revoke insert, update, delete on public.purchases from authenticated;
grant select on public.purchases to authenticated;
