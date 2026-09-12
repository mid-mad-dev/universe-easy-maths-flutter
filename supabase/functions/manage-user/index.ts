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

  const admin = createClient(Deno.env.get('SUPABASE_URL')!, serviceKey());
  const token = authHeader.replace(/^Bearer\s+/i, '');
  const { data: callerData, error: callerError } = await admin.auth.getUser(token);
  if (callerError || !callerData.user) return json({ error: 'Invalid session.' }, 401);

  const { data: callerProfile } = await admin
    .from('profiles')
    .select('role,is_admin')
    .eq('id', callerData.user.id)
    .maybeSingle();

  const role = callerProfile?.role?.toString() ?? 'student';
  const staff = role === 'admin' || role === 'owner' || callerProfile?.is_admin === true;
  const owner = role === 'owner';
  if (!staff) return json({ error: 'Admin permission required.' }, 403);

  const body = await req.json().catch(() => ({}));
  const action = body?.action?.toString();
  const userId = body?.user_id?.toString();
  if (!action || !userId) return json({ error: 'action and user_id are required.' }, 400);

  if (action === 'set_admin' || action === 'remove_admin') {
    if (!owner) return json({ error: 'Owner permission required.' }, 403);
    if (userId === callerData.user.id) return json({ error: 'The Owner cannot change their own role.' }, 400);

    const { data: targetProfile, error: targetError } = await admin
      .from('profiles')
      .select('id,role')
      .eq('id', userId)
      .maybeSingle();

    if (targetError) return json({ error: targetError.message }, 500);
    if (!targetProfile) return json({ error: 'User not found.' }, 404);
    if (targetProfile.role === 'owner') {
      return json({ error: 'Owner accounts cannot be changed here.' }, 403);
    }

    const newRole = action === 'set_admin' ? 'admin' : 'student';
    const { error: updateError } = await admin
      .from('profiles')
      .update({ role: newRole, is_admin: newRole === 'admin' })
      .eq('id', userId);

    if (updateError) return json({ error: updateError.message }, 500);
    return json({ success: true });
  }

  if (action === 'delete_student') {
    const { data: target } = await admin
      .from('profiles')
      .select('id,role')
      .eq('id', userId)
      .maybeSingle();

    if (!target) return json({ error: 'User not found.' }, 404);
    if (target.role !== 'student') return json({ error: 'Only student accounts can be removed here.' }, 400);

    for (const table of ['notifications', 'purchases', 'progress', 'questions']) {
      const { error: cleanupError } = await admin
        .from(table)
        .delete()
        .eq('user_id', userId);
      if (cleanupError) {
        return json({
          error: `Could not clean up ${table}: ${cleanupError.message}`,
        }, 500);
      }
    }

    const { error } = await admin.auth.admin.deleteUser(userId);
    if (error) return json({ error: error.message }, 500);

    return json({ success: true });
  }

  return json({ error: 'Unknown action.' }, 400);
});
