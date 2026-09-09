import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};

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
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'Missing authorization.' }, 401);
    }

    const token = authHeader.replace(/^Bearer\s+/i, '');
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      serviceKey(),
      { auth: { persistSession: false } },
    );

    const { data: authData, error: authError } =
      await supabase.auth.getUser(token);

    if (authError || !authData.user) {
      return json({ error: 'Invalid session.' }, 401);
    }

    const body = await req.json();
    const lessonId = body?.lesson_id?.toString();
    if (!lessonId) {
      return json({ error: 'lesson_id is required.' }, 400);
    }

    const { data: lesson, error: lessonError } = await supabase
      .from('lessons')
      .select('id,chapter_id,video_url,premium,published')
      .eq('id', lessonId)
      .maybeSingle();

    if (lessonError || !lesson) {
      return json({ error: 'Lesson not found.' }, 404);
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role,is_admin')
      .eq('id', authData.user.id)
      .maybeSingle();

    const staff = profile != null && (
      profile.role === 'admin' ||
      profile.role === 'owner' ||
      profile.is_admin === true
    );

    let allowed = staff;

    if (!allowed && lesson.published === true && lesson.premium !== true) {
      allowed = true;
    }

    if (!allowed && lesson.published === true && lesson.premium === true) {
      const { data: links } = await supabase
        .from('course_chapters')
        .select('course_id')
        .eq('chapter_id', lesson.chapter_id);

      const courseIds = (links ?? [])
        .map((row: { course_id?: string }) => row.course_id)
        .filter((id: string | undefined): id is string => Boolean(id));

      if (courseIds.length > 0) {
        const { data: purchases } = await supabase
          .from('purchases')
          .select('course_id')
          .eq('user_id', authData.user.id)
          .eq('payment_status', 'SUCCESS')
          .in('course_id', courseIds)
          .limit(1);

        allowed = (purchases ?? []).length > 0;
      }
    }

    if (!allowed) {
      return json({ error: 'Lesson access denied.' }, 403);
    }

    const stored = lesson.video_url?.toString().trim() ?? '';
    if (!stored) return json({ url: null });

    // Lesson videos must stay in the private bucket. Never proxy arbitrary
    // public URLs because that would bypass access checks and expiry.
    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      return json({ error: 'Lesson video must use private storage.' }, 400);
    }

    const { data, error } = await supabase.storage
      .from('lesson-videos')
      .createSignedUrl(stored, 300);

    if (error) throw error;

    return json({ url: data.signedUrl });
  } catch (error) {
    return json({
      error: error instanceof Error ? error.message : String(error),
    }, 500);
  }
});
