import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  SupabaseClient get supabase => Supabase.instance.client;
  String? get userId => supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>?> getLessonProgress(String lessonId) async {
    final uid = userId;
    if (uid == null) return null;
    final row = await supabase.from('progress').select().eq('user_id', uid).eq('lesson_id', lessonId).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> saveProgress({required String lessonId, required String chapterId, required double watchedPercentage}) async {
    final uid = userId;
    if (uid == null) return;
    final p = watchedPercentage.clamp(0, 100).toDouble();
    await supabase.from('progress').upsert({
      'user_id': uid,
      'lesson_id': lessonId,
      'chapter_id': chapterId,
      'watched_percentage': p,
      'seen': p >= 90,
      'last_watched': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,lesson_id');
  }

  Future<double> getChapterProgress(String chapterId) async {
    final uid = userId;
    if (uid == null) return 0;
    final lessons = await supabase.from('lessons').select('id').eq('chapter_id', chapterId).eq('published', true);
    if (lessons.isEmpty) return 0;
    final ids = (lessons as List).map((e) => e['id']).toList();
    final rows = await supabase.from('progress').select('seen').eq('user_id', uid).inFilter('lesson_id', ids);
    final complete = (rows as List).where((e) => e['seen'] == true).length;
    return complete / lessons.length;
  }

  Future<double> getOverallProgress() async {
    final uid = userId;
    if (uid == null) return 0;
    final lessons = await supabase.from('lessons').select('id').eq('published', true);
    if (lessons.isEmpty) return 0;
    final ids = (lessons as List).map((e) => e['id']).toList();
    final rows = await supabase.from('progress').select('seen').eq('user_id', uid).inFilter('lesson_id', ids);
    final complete = (rows as List).where((e) => e['seen'] == true).length;
    return complete / lessons.length;
  }
}
