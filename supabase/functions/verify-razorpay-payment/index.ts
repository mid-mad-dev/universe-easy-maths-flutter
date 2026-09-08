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

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

async function hmacHex(message: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(message),
  );
  return [...new Uint8Array(signature)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'Authentication required.' }, 401);

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, serviceKey());
  const token = authHeader.replace(/^Bearer\s+/i, '');
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) return json({ error: 'Invalid session.' }, 401);

  const body = await req.json().catch(() => ({}));
  const courseId = body?.course_id?.toString();
  const orderId = body?.razorpay_order_id?.toString();
  const paymentId = body?.razorpay_payment_id?.toString();
  const signature = body?.razorpay_signature?.toString();

  if (!courseId || !orderId || !paymentId || !signature) {
    return json({ error: 'Incomplete payment verification payload.' }, 400);
  }

  const { data: purchase, error: purchaseError } = await admin
    .from('purchases')
    .select('id,user_id,course_id,amount,payment_status,razorpay_order_id')
    .eq('user_id', userData.user.id)
    .eq('course_id', courseId)
    .eq('razorpay_order_id', orderId)
    .maybeSingle();

  if (purchaseError || !purchase) return json({ error: 'Payment order not found.' }, 404);

  const { data: course } = await admin
    .from('courses')
    .select('id,price,premium')
    .eq('id', courseId)
    .maybeSingle();

  if (!course || course.premium !== true) {
    return json({ error: 'Invalid premium course.' }, 400);
  }

  const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET');
  const keyId = Deno.env.get('RAZORPAY_KEY_ID');
  if (!keySecret || !keyId) return json({ error: 'Razorpay server keys are not configured.' }, 500);

  const generated = await hmacHex(`${orderId}|${paymentId}`, keySecret);
  if (!timingSafeEqual(generated, signature)) {
    return json({ error: 'Invalid Razorpay signature.' }, 400);
  }

  // Verify payment details with Razorpay as a second server-side check.
  const credentials = btoa(`${keyId}:${keySecret}`);
  const paymentResponse = await fetch(
    `https://api.razorpay.com/v1/payments/${encodeURIComponent(paymentId)}`,
    {
      headers: { 'Authorization': `Basic ${credentials}` },
    },
  );
  const payment = await paymentResponse.json();

  if (!paymentResponse.ok) {
    return json({ error: 'Could not verify payment with Razorpay.' }, 502);
  }

  const expectedAmount = Math.round(Number(course.price) * 100);
  if (
    payment.order_id !== orderId ||
    Number(payment.amount) !== expectedAmount
  ) {
    return json({ error: 'Payment amount or order does not match.' }, 400);
  }

  if (payment.status !== 'captured') {
    return json({ error: `Payment status is ${payment.status}.` }, 400);
  }

  await admin
    .from('purchases')
    .update({
      payment_id: paymentId,
      payment_status: 'SUCCESS',
      payment_gateway: 'Razorpay',
      payment_date: new Date().toISOString(),
      razorpay_signature: signature,
      gateway_payment_status: payment.status,
    })
    .eq('id', purchase.id);

  return json({
    success: true,
    course_id: courseId,
    payment_id: paymentId,
  });
});
