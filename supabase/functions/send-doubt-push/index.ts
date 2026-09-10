import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Sends FCM pushes for doubt events.
//
// Body: { question_id: string, event: 'answered' | 'new_doubt' }
//   - 'answered'  -> notify the student who asked, on all their devices
//   - 'new_doubt' -> notify every admin/owner, on all their devices
//
// Requires the FIREBASE_ACCESS_TOKEN secret (an FCM v1 OAuth access token,
// minted from the Firebase service account). Set it with:
//   supabase secrets set FIREBASE_ACCESS_TOKEN=...
// See PUSH_SETUP.md for the full one-time setup.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};

const FCM_ENDPOINT = 'https://fcm.googleapis.com/v1/projects/-/messages:send';

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

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

interface TokenRow {
  token: string;
  platform: string;
}

interface ProfileRow {
  id: string;
  role: string;
  is_admin: boolean | null;
}

interface QuestionRow {
  id: string;
  user_id: string;
  question: string;
  answer: string | null;
}

async function sendFcm(
  accessToken: string,
  token: string,
  title: string,
  body: string,
): Promise<{ ok: boolean; permanent: boolean }> {
  const payload = {
    message: {
      token,
      notification: { title, body },
      android: { priority: 'high' as const },
    },
  };

  const response = await fetch(FCM_ENDPOINT, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (response.ok) return { ok: true, permanent: false };

  // 404/410 mean the token is dead (app uninstalled) - prune it.
  const permanent = response.status === 404 || response.status === 410;
  return { ok: false, permanent };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'Missing authorization.' }, 401);
    }

    const accessToken = Deno.env.get('FIREBASE_ACCESS_TOKEN');
    if (!accessToken) {
      return json({ error: 'Push is not configured on the server.' }, 501);
    }

    const token = authHeader.replace(/^Bearer\s+/i, '');
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      serviceKey(),
      { auth: { persistSession: false } },
    );

    const { data: authData, error: authError } = await supabase.auth.getUser(token);
    if (authError || !authData.user) {
      return json({ error: 'Invalid session.' }, 401);
    }

    const body = await req.json().catch(() => null);
    const questionId = body?.question_id?.toString();
    const event = body?.event?.toString();
    if (!questionId || !['answered', 'new_doubt'].includes(event)) {
      return json({ error: 'question_id and a valid event are required.' }, 400);
    }

    const { data: question, error: questionError } = await supabase
      .from('questions')
      .select('id,user_id,question,answer')
      .eq('id', questionId)
      .maybeSingle();

    if (questionError || !question) {
      return json({ error: 'Question not found.' }, 404);
    }

    const callerProfileResult = await supabase
      .from('profiles')
      .select('id,role,is_admin')
      .eq('id', authData.user.id)
      .maybeSingle();
    const caller = callerProfileResult.data as ProfileRow | null;

    const isStaff = caller != null && (
      caller.role === 'admin' ||
      caller.role === 'owner' ||
      caller.is_admin === true
    );

    // Authorization: only staff may trigger notifications for a question.
    if (!isStaff) {
      return json({ error: 'Not allowed.' }, 403);
    }

    const preview = (text: string, max = 140) => {
      const clean = text.replace(/\s+/g, ' ').trim();
      return clean.length > max ? `${clean.slice(0, max - 1)}…` : clean;
    };

    let title: string;
    let message: string;
    let recipients: TokenRow[] = [];

    if (event === 'answered') {
      title = 'Your doubt has been answered';
      message = preview(question.answer ?? preview(question.question));
      const { data: rows } = await supabase
        .from('push_tokens')
        .select('token,platform')
        .eq('user_id', question.user_id);
      recipients = (rows ?? []) as TokenRow[];
    } else {
      title = 'New student doubt';
      message = preview(question.question);
      const { data: staffRows } = await supabase
        .from('profiles')
        .select('id,role,is_admin')
        .or('role.in.(admin,owner),is_admin.eq.true');
      const staffIds = ((staffRows ?? []) as ProfileRow[])
        .map((p) => p.id)
        .filter(Boolean);
      if (staffIds.length > 0) {
        const { data: rows } = await supabase
          .from('push_tokens')
          .select('token,platform')
          .in('user_id', staffIds);
        recipients = (rows ?? []) as TokenRow[];
      }
    }

    if (recipients.length === 0) {
      return json({ sent: 0, pruned: 0 });
    }

    let sent = 0;
    const stale: string[] = [];

    const results = await Promise.all(
      recipients.map(async (recipient) => {
        const result = await sendFcm(accessToken, recipient.token, title, message);
        if (result.ok) sent += 1;
        if (result.permanent) stale.push(recipient.token);
      }),
    );
    void results;

    if (stale.length > 0) {
      await supabase.from('push_tokens').delete().in('token', stale);
    }

    return json({ sent, pruned: stale.length });
  } catch (error) {
    return json({
      error: error instanceof Error ? error.message : String(error),
    }, 500);
  }
});
