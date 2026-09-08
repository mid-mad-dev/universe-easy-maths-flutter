import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_constants.dart';

class AdminService {
  SupabaseClient get supabase => Supabase.instance.client;

  Future<bool> isStaff() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await supabase.from('profiles').select('role,is_admin').eq('id', uid).maybeSingle();
    if (row == null) return false;
    final role = '${row['role'] ?? 'student'}';
    return role == 'admin' || role == 'owner' || row['is_admin'] == true;
  }

  Future<bool> isOwner() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await supabase.from('profiles').select('role').eq('id', uid).maybeSingle();
    return row?['role'] == 'owner';
  }

  Future<List<Map<String, dynamic>>> getQuestions() async {
    // Do NOT embed profiles here: questions has two profile foreign keys.
    final data = await supabase.from('questions').select('*, chapters(*), lessons(*)').order('created_at', ascending: false);
    final rows = (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    final userIds = rows.map((e) => e['user_id']?.toString()).whereType<String>().toSet().toList();
    final adminIds = rows.map((e) => e['teacher_admin_id']?.toString()).whereType<String>().toSet().toList();
    final allIds = {...userIds, ...adminIds}.toList();
    if (allIds.isEmpty) return rows;
    final profiles = await supabase.from('profiles').select('id,name,email,profile_photo,role').inFilter('id', allIds);
    final map = <String, Map<String, dynamic>>{};
    for (final p in profiles as List) {
      final m = Map<String, dynamic>.from(p);
      map[m['id'].toString()] = m;
    }
    for (final row in rows) {
      row['student'] = map[row['user_id']?.toString()];
      row['teacher'] = map[row['teacher_admin_id']?.toString()];
    }
    return rows;
  }

  Future<void> answerQuestion({required String questionId, required String answer}) async {
    await supabase.from('questions').update({
      'answer': answer.trim(),
      'answered': true,
      'teacher_admin_id': supabase.auth.currentUser?.id,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', questionId);
  }

  Future<void> deleteQuestion(String questionId) async {
    await supabase.from('questions').delete().eq('id', questionId);
  }

  Future<List<Map<String, dynamic>>> getChapters() async {
    final data = await supabase.from('chapters').select().order('chapter_number');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createChapter({required String name, required int number, required String description, required bool premium, required bool published}) async {
    await supabase.from('chapters').insert({
      'chapter_name': name.trim(),
      'chapter_number': number,
      'description': description.trim(),
      'premium': premium,
      'published': published,
    });
  }

  Future<void> updateChapter({required String id, required String name, required int number, required String description, required bool premium, required bool published}) async {
    await supabase.from('chapters').update({
      'chapter_name': name.trim(),
      'chapter_number': number,
      'description': description.trim(),
      'premium': premium,
      'published': published,
    }).eq('id', id);
  }

  Future<void> deleteChapter(String chapterId) async {
    final lessons = await supabase.from('lessons').select('id,video_url,thumbnail_url').eq('chapter_id', chapterId);
    for (final item in lessons as List) {
      await _removeStorageValue(AppConstants.lessonBucket, item['video_url']);
      await _removeStorageValue(AppConstants.lessonBucket, item['thumbnail_url']);
    }
    await supabase.from('chapters').delete().eq('id', chapterId);
  }

  Future<List<Map<String, dynamic>>> getLessons() async {
    final data = await supabase.from('lessons').select('*, chapters(chapter_name,chapter_number)').order('created_at', ascending: false);
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createLesson({required String chapterId, required int lessonNumber, required String title, required String description, required String? videoPath, required String? thumbnailPath, required int durationSeconds, required bool published, required bool premium}) async {
    await supabase.from('lessons').insert({
      'chapter_id': chapterId,
      'lesson_number': lessonNumber,
      'title': title.trim(),
      'description': description.trim(),
      'video_url': videoPath,
      'thumbnail_url': thumbnailPath,
      'duration_seconds': durationSeconds,
      'published': published,
      'premium': premium,
    });
  }

  Future<void> updateLesson({required String id, required String chapterId, required int lessonNumber, required String title, required String description, required String? videoPath, required String? thumbnailPath, required int durationSeconds, required bool published, required bool premium}) async {
    final old = await supabase.from('lessons').select('video_url,thumbnail_url').eq('id', id).maybeSingle();
    final oldVideo = old?['video_url']?.toString();
    final oldThumb = old?['thumbnail_url']?.toString();
    if (oldVideo != null && oldVideo.isNotEmpty && videoPath != null && videoPath != oldVideo) {
      await _removeStorageValue(AppConstants.lessonBucket, oldVideo);
    }
    if (oldThumb != null && oldThumb.isNotEmpty && thumbnailPath != null && thumbnailPath != oldThumb) {
      await _removeStorageValue(AppConstants.lessonBucket, oldThumb);
    }
    await supabase.from('lessons').update({
      'chapter_id': chapterId,
      'lesson_number': lessonNumber,
      'title': title.trim(),
      'description': description.trim(),
      'video_url': videoPath,
      'thumbnail_url': thumbnailPath,
      'duration_seconds': durationSeconds,
      'published': published,
      'premium': premium,
    }).eq('id', id);
  }

  Future<void> setCourseChapters(String courseId, List<String> chapterIds) async {
    await supabase.from('course_chapters').delete().eq('course_id', courseId);
    if (chapterIds.isEmpty) return;
    await supabase.from('course_chapters').insert([
      for (var i = 0; i < chapterIds.length; i++)
        {'course_id': courseId, 'chapter_id': chapterIds[i], 'sort_order': i}
    ]);
  }

  Future<List<String>> getCourseChapterIds(String courseId) async {
    final rows = await supabase.from('course_chapters').select('chapter_id').eq('course_id', courseId).order('sort_order');
    return (rows as List).map((e) => '${e['chapter_id']}').toList();
  }

  Future<void> deleteLesson(String lessonId) async {
    final row = await supabase.from('lessons').select('video_url,thumbnail_url').eq('id', lessonId).maybeSingle();
    if (row != null) {
      await _removeStorageValue(AppConstants.lessonBucket, row['video_url']);
      await _removeStorageValue(AppConstants.lessonBucket, row['thumbnail_url']);
    }
    await supabase.from('lessons').delete().eq('id', lessonId);
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    final data = await supabase.from('courses').select().order('created_at', ascending: false);
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createCourse({required String name, required String description, required double price, required bool premium, required bool published}) async {
    await supabase.from('courses').insert({'course_name': name.trim(), 'description': description.trim(), 'price': price, 'premium': premium, 'published': published});
  }

  Future<void> updateCourse({required String id, required String name, required String description, required double price, required bool premium, required bool published}) async {
    await supabase.from('courses').update({'course_name': name.trim(), 'description': description.trim(), 'price': price, 'premium': premium, 'published': published}).eq('id', id);
  }

  Future<void> deleteCourse(String id) async {
    final links = await supabase.from('course_chapters').select('id').eq('course_id', id);
    if ((links as List).isNotEmpty) {
      await supabase.from('course_chapters').delete().eq('course_id', id);
    }
    await supabase.from('courses').delete().eq('id', id);
  }


  Future<List<Map<String, dynamic>>> studentQuestions(String userId) async {
    final data = await supabase
        .from('questions')
        .select('id,user_id,question,image_url,answer,answered,chapter_id,lesson_id,teacher_admin_id,created_at,updated_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> studentProgress(String userId) async {
    final data = await supabase
        .from('progress')
        .select('id,user_id,lesson_id,chapter_id,seen,watched_percentage,last_watched')
        .eq('user_id', userId)
        .order('last_watched', ascending: false);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final data = await supabase.from('profiles').select().order('created_at', ascending: false);
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> removeStudent(String userId) async {
    await _invokeUserFunction({'action': 'delete_student', 'user_id': userId});
  }

  Future<void> addAdmin(String userId) async {
    await _invokeUserFunction({'action': 'set_admin', 'user_id': userId});
  }

  Future<void> removeAdmin(String userId) async {
    await _invokeUserFunction({'action': 'remove_admin', 'user_id': userId});
  }

  Future<void> _invokeUserFunction(Map<String, dynamic> body) async {
    final response = await supabase.functions.invoke('manage-user', body: body);
    if (response.status >= 400) throw Exception(response.data?.toString() ?? 'Server operation failed.');
  }

  Future<void> _removeStorageValue(String bucket, dynamic value) async {
    if (value == null) return;
    final path = _extractPath(value.toString(), bucket);
    if (path == null || path.isEmpty) return;
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (_) {}
  }

  String? _extractPath(String raw, String bucket) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (!value.contains('/storage/v1/')) return value.startsWith('$bucket/') ? value.substring(bucket.length + 1) : value;
    final marker = '/object/';
    final index = value.indexOf(marker);
    if (index < 0) return null;
    var path = value.substring(index + marker.length);
    final bucketSlash = '$bucket/';
    if (path.startsWith('public/$bucketSlash')) path = path.substring('public/$bucketSlash'.length);
    if (path.startsWith('sign/$bucketSlash')) path = path.substring('sign/$bucketSlash'.length);
    if (path.startsWith('authenticated/$bucketSlash')) path = path.substring('authenticated/$bucketSlash'.length);
    return path;
  }
}
