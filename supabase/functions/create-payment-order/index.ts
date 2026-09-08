import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function serviceKey(): string {
  const legacy = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (legacy) return legacy;

  const raw = Deno.env.get('SUPABASE_SECRET_KEYS');
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      if (typeof parsed?.default === 'string') return parsed.default;
    } catch (_) {}
  }

  throw new Error('Supabase server key is not configured.');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'Authentication required.' }, 401);

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const admin = createClient(supabaseUrl!, serviceKey());
  const userClient = createClient(supabaseUrl!, Deno.env.get('SUPABASE_ANON_KEY') ?? '');

  const token = authHeader.replace(/^Bearer\s+/i, '');
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) return json({ error: 'Invalid session.' }, 401);

  const body = await req.json().catch(() => ({}));
  const courseId = body?.course_id?.toString();
  if (!courseId) return json({ error: 'course_id is required.' }, 400);

  const { data: profile } = await admin
    .from('profiles')
    .select('role,is_admin,email')
    .eq('id', userData.user.id)
    .maybeSingle();

  if (!profile) return json({ error: 'Profile not found.' }, 403);

  const staff = profile.role === 'admin' || profile.role === 'owner' || profile.is_admin === true;

  const { data: course, error: courseError } = await admin
    .from('courses')
    .select('id,course_name,price,premium,published')
    .eq('id', courseId)
    .maybeSingle();

  if (courseError || !course || course.published !== true) {
    return json({ error: 'Course not found.' }, 404);
  }

  if (course.premium !== true || staff || Number(course.price ?? 0) <= 0) {
    return json({
      free: true,
      course_id: course.id,
      message: 'No payment is required for this account/course.',
    });
  }

  const { data: existingPurchase } = await admin
    .from('purchases')
    .select('id')
    .eq('user_id', userData.user.id)
    .eq('course_id', course.id)
    .eq('payment_status', 'SUCCESS')
    .maybeSingle();

  if (existingPurchase) {
    return json({
      free: true,
      already_purchased: true,
      course_id: course.id,
    });
  }

  const keyId = Deno.env.get('RAZORPAY_KEY_ID');
  const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET');
  if (!keyId || !keySecret) {
    return json({ error: 'Razorpay keys are not configured on the server.' }, 500);
  }

  const amountPaise = Math.round(Number(course.price) * 100);
  if (amountPaise < 1000) {
    return json({ error: 'Course amount must be at least ₹10.' }, 400);
  }

  const receipt = `uem_${userData.user.id.slice(0, 8)}_${Date.now()}`;
  const credentials = btoa(`${keyId}:${keySecret}`);

  const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${credentials}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount: amountPaise,
      currency: 'INR',
      receipt,
      notes: {
        course_id: course.id,
        user_id: userData.user.id,
      },
    }),
  });

  const razorpay = await razorpayResponse.json();
  if (!razorpayResponse.ok) {
    return json({ error: razorpay?.error?.description ?? 'Razorpay order creation failed.' }, 502);
  }

  await admin.from('purchases').insert({
    user_id: userData.user.id,
    course_id: course.id,
    amount: Number(course.price),
    payment_status: 'PENDING',
    payment_gateway: 'Razorpay',
    razorpay_order_id: razorpay.id,
    gateway_payment_status: 'created',
  });

  return json({
    free: false,
    order_id: razorpay.id,
    amount: amountPaise,
    currency: 'INR',
    key_id: keyId,
    course_id: course.id,
  });
});
