import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';

class StorageService {
  SupabaseClient get supabase => Supabase.instance.client;

  static const _contentTypes = <String, String>{
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'm4v': 'video/x-m4v',
    'webm': 'video/webm',
    'mkv': 'video/x-matroska',
    '3gp': 'video/3gpp',
    'avi': 'video/x-msvideo',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'bmp': 'image/bmp',
  };

  String _contentTypeFor(String ext) =>
      _contentTypes[ext] ?? 'application/octet-stream';

  Future<String> uploadXFile({
    required String bucket,
    required String folder,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'bin';
    final id = DateTime.now().microsecondsSinceEpoch;
    final path = '$folder/$id.$ext';
    await supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeFor(ext),
            upsert: false,
          ),
        );
    return path;
  }

  Future<String> uploadProfilePhoto(XFile file) => uploadXFile(
    bucket: AppConstants.profileBucket,
    folder: supabase.auth.currentUser!.id,
    file: file,
  );

  Future<String> uploadDoubtImage(XFile file) => uploadXFile(
    bucket: AppConstants.doubtBucket,
    folder: supabase.auth.currentUser!.id,
    file: file,
  );

  Future<String> uploadLessonVideo(XFile file, String lessonId) => uploadXFile(
    bucket: AppConstants.lessonBucket,
    folder: lessonId,
    file: file,
  );

  Future<String> signedUrl(
    String bucket,
    String path, {
    int expiresIn = 3600,
  }) => supabase.storage.from(bucket).createSignedUrl(path, expiresIn);

  Future<void> remove(String bucket, String path) async {
    if (path.trim().isEmpty) return;
    await supabase.storage.from(bucket).remove([path]);
  }
}
