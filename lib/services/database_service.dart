import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';

import '../models/chapter.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../models/profile.dart';
import '../models/question.dart';
import 'storage_service.dart';

class DatabaseService {
  SupabaseClient get supabase => Supabase.instance.client;
  String? get userId => supabase.auth.currentUser?.id;

  Future<Profile?> getMyProfile() async {
    final id = userId;
    if (id == null) return null;
    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Profile.fromMap(Map<String, dynamic>.from(row));
  }

  Future<Chapter?> getChapter(String id) async {
    final row = await supabase
        .from('chapters')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Chapter.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<Chapter>> getChapters({bool publishedOnly = true}) async {
    var query = supabase.from('chapters').select();
    final data = publishedOnly
        ? await query.eq('published', true).order('chapter_number')
        : await query.order('chapter_number');
    return (data as List)
        .map((e) => Chapter.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Lesson>> getLessons(
    String chapterId, {
    bool publishedOnly = true,
  }) async {
    var query = supabase.from('lessons').select().eq('chapter_id', chapterId);
    final data = publishedOnly
        ? await query.eq('published', true).order('lesson_number')
        : await query.order('lesson_number');
    return (data as List)
        .map((e) => Lesson.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Lesson?> getLesson(String lessonId) async {
    final row = await supabase
        .from('lessons')
        .select()
        .eq('id', lessonId)
        .maybeSingle();
    return row == null ? null : Lesson.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<Lesson>> searchLessons(String term) async {
    final q = term.trim();
    if (q.isEmpty) return [];
    final data = await supabase
        .from('lessons')
        .select()
        .eq('published', true)
        .or('title.ilike.%$q%,description.ilike.%$q%')
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((e) => Lesson.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Course>> getCourses() async {
    final data = await supabase
        .from('courses')
        .select()
        .eq('published', true)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Course.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Course?> getCourse(String id) async {
    final row = await supabase
        .from('courses')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Course.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<Map<String, dynamic>>> getCourseChapters(String courseId) async {
    final data = await supabase
        .from('course_chapters')
        .select('sort_order, chapters(*)')
        .eq('course_id', courseId)
        .order('sort_order');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getMyPurchases() async {
    final id = userId;
    if (id == null) return [];
    final data = await supabase
        .from('purchases')
        .select('*, courses(*)')
        .eq('user_id', id)
        .order('purchase_date', ascending: false);
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getMyQuestions() async {
    final id = userId;
    if (id == null) return [];
    final data = await supabase
        .from('questions')
        .select('*, chapters(*), lessons(*)')
        .eq('user_id', id)
        .order('created_at', ascending: false);
    final rows = (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final storage = StorageService();
    for (final row in rows) {
      final raw = row['image_url']?.toString();
      if (raw != null && raw.isNotEmpty) {
        final url = await storage.imageUrl(AppConstants.doubtBucket, raw);
        if (url != null) row['image_url'] = url;
      }
    }
    return rows;
  }

  Future<void> createQuestion({
    required String text,
    String? chapterId,
    String? lessonId,
    String? imagePath,
  }) async {
    final id = userId;
    if (id == null) throw Exception('Please login first.');
    await supabase.from('questions').insert({
      'user_id': id,
      'question': text.trim().replaceAll(RegExp(r'\s+'), ' '),
      'chapter_id': chapterId,
      'lesson_id': lessonId,
      'image_url': imagePath,
    });
  }

  Future<void> deleteOwnQuestion(String questionId) async {
    final id = userId;
    if (id == null) throw Exception('Please login first.');
    await supabase
        .from('questions')
        .delete()
        .eq('id', questionId)
        .eq('user_id', id);
  }

  Future<void> updateProfileName(String name) async {
    final id = userId;
    if (id == null) throw Exception('Please login first.');
    await supabase.from('profiles').update({'name': name.trim()}).eq('id', id);
  }

  Future<void> updateProfilePhoto(String path) async {
    final id = userId;
    if (id == null) throw Exception('Please login first.');
    await supabase
        .from('profiles')
        .update({'profile_photo': path.trim()})
        .eq('id', id);
  }

  Future<List<Question>> getAnsweredQuestions() async {
    final rows = await getMyQuestions();
    return rows
        .where((e) => e['answered'] == true)
        .map(Question.fromMap)
        .toList();
  }
}
