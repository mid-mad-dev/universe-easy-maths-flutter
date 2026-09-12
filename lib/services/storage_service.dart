import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';

class StorageService {
  SupabaseClient get supabase => Supabase.instance.client;

  // Keep the binary upload path safe on mobile. Large lesson uploads should
  // eventually move to resumable storage, but rejecting oversized files here
  // prevents an avoidable out-of-memory crash while preserving web support.
  static const _maxUploadBytes = 200 * 1024 * 1024;

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
    final size = await file.length();
    if (size <= 0) {
      throw Exception('The selected file is empty. Choose another file.');
    }
    if (size > _maxUploadBytes) {
      throw Exception('Choose a file smaller than 200 MB.');
    }

    final bytes = await file.readAsBytes();
    final rawExtension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'bin';
    final ext = rawExtension.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final safeExtension = ext.isEmpty ? 'bin' : ext;
    final id = DateTime.now().microsecondsSinceEpoch;
    final path = '$folder/$id.$safeExtension';
    await supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeFor(safeExtension),
            upsert: false,
          ),
        );
    return path;
  }

  String _requireUserId() {
    final id = supabase.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw Exception('Please sign in before uploading a file.');
    }
    return id;
  }

  Future<String> uploadProfilePhoto(XFile file) => uploadXFile(
    bucket: AppConstants.profileBucket,
    folder: _requireUserId(),
    file: file,
  );

  Future<String> uploadDoubtImage(XFile file) => uploadXFile(
    bucket: AppConstants.doubtBucket,
    folder: _requireUserId(),
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

  /// Returns a URL that can be used to display the image in a UI.
  ///
  /// If [path] is already an http(s) URL it is returned as-is. Otherwise the
  /// path is signed so the current user can view it (the bucket policies must
  /// grant read access for the result to work).
  Future<String?> imageUrl(String bucket, String path) async {
    final raw = path.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    try {
      return await supabase.storage.from(bucket).createSignedUrl(raw, 3600);
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String bucket, String path) async {
    if (path.trim().isEmpty) return;
    await supabase.storage.from(bucket).remove([path]);
  }
}
