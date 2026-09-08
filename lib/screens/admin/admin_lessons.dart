import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_background.dart';

class AdminLessons extends StatefulWidget {
  const AdminLessons({super.key});

  @override
  State<AdminLessons> createState() => _AdminLessonsState();
}

class _AdminLessonsState extends State<AdminLessons> {
  final service = AdminService();
  final storage = StorageService();
  final picker = ImagePicker();

  List<Map<String, dynamic>> lessons = [];
  List<Map<String, dynamic>> chapters = [];
  bool loading = true;
  bool saving = false;

  // Uploading a video buffers it fully in memory, so cap the file size to
  // avoid the app freezing or being killed on low-memory phones.
  static const maxVideoBytes = 150 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    load();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<XFile?> _pickVideoFile() async {
    try {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return null;
      final size = await picked.length();
      if (size > maxVideoBytes) {
        _message(
          'That video is ${(size / (1024 * 1024)).round()} MB. '
          'Keep lesson clips under 150 MB - short 60-second videos work best.',
        );
        return null;
      }
      return picked;
    } catch (error) {
      _message('Could not open the gallery: $error');
      return null;
    }
  }

  Future<XFile?> _pickImageFile() async {
    try {
      return await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 85,
      );
    } catch (error) {
      _message('Could not open the gallery: $error');
      return null;
    }
  }

  Future<void> load() async {
    try {
      final lessonRows = await service.getLessons();
      final chapterRows = await service.getChapters();

      if (!mounted) return;

      setState(() {
        lessons = lessonRows;
        chapters = chapterRows;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load lessons: $error')));
    }
  }

  Future<bool> confirmDelete(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('CONFIRM'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    if (saving) return;
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Create a chapter first.')));
      return;
    }

    final title = TextEditingController(text: row?['title']?.toString() ?? '');
    final description = TextEditingController(
      text: row?['description']?.toString() ?? '',
    );
    final lessonNumber = TextEditingController(
      text: row?['lesson_number']?.toString() ?? '1',
    );
    final duration = TextEditingController(
      text: row?['duration_seconds']?.toString() ?? '60',
    );

    String chapterId =
        row?['chapter_id']?.toString() ?? chapters.first['id'].toString();
    bool premium = row?['premium'] == true;
    bool published = row?['published'] != false;
    XFile? video;
    XFile? thumbnail;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(row == null ? 'ADD LESSON' : 'EDIT LESSON'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: description,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: chapterId,
                        isExpanded: true,
                        items: chapters.map((chapter) {
                          return DropdownMenuItem<String>(
                            value: chapter['id'].toString(),
                            child: Text(
                              '${chapter['chapter_number']}. ${chapter['chapter_name']}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setLocal(() => chapterId = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Chapter'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: lessonNumber,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Lesson Number',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: duration,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (seconds)',
                        ),
                      ),
                      SwitchListTile(
                        value: premium,
                        title: const Text('Premium'),
                        onChanged: (value) {
                          setLocal(() => premium = value);
                        },
                      ),
                      SwitchListTile(
                        value: published,
                        title: const Text('Published'),
                        onChanged: (value) {
                          setLocal(() => published = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _pickVideoFile();
                          if (picked != null) {
                            setLocal(() => video = picked);
                          }
                        },
                        icon: const Icon(Icons.video_library_outlined),
                        label: Text(
                          video == null
                              ? 'SELECT VIDEO'
                              : 'VIDEO: ${video!.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _pickImageFile();
                          if (picked != null) {
                            setLocal(() => thumbnail = picked);
                          }
                        },
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          thumbnail == null
                              ? 'SELECT THUMBNAIL'
                              : 'THUMBNAIL: ${thumbnail!.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true || title.text.trim().isEmpty) {
      title.dispose();
      description.dispose();
      lessonNumber.dispose();
      duration.dispose();
      return;
    }

    if (!mounted) return;
    setState(() => saving = true);
    // Block the screen while the video uploads so it does not look frozen.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const PopScope(canPop: false, child: _UploadingDialog()),
      ),
    );

    try {
      String? videoPath = row?['video_url']?.toString();
      String? thumbnailPath = row?['thumbnail_url']?.toString();

      final folder =
          'lessons/${row?['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch}';

      if (video != null) {
        videoPath = await storage.uploadXFile(
          bucket: 'lesson-videos',
          folder: folder,
          file: video!,
        );
      }

      if (thumbnail != null) {
        thumbnailPath = await storage.uploadXFile(
          bucket: 'lesson-videos',
          folder: folder,
          file: thumbnail!,
        );
      }

      final number = int.tryParse(lessonNumber.text.trim()) ?? 1;
      final seconds = int.tryParse(duration.text.trim()) ?? 60;

      if (row == null) {
        await service.createLesson(
          chapterId: chapterId,
          lessonNumber: number,
          title: title.text,
          description: description.text,
          videoPath: videoPath,
          thumbnailPath: thumbnailPath,
          durationSeconds: seconds,
          published: published,
          premium: premium,
        );
      } else {
        await service.updateLesson(
          id: row['id'].toString(),
          chapterId: chapterId,
          lessonNumber: number,
          title: title.text,
          description: description.text,
          videoPath: videoPath,
          thumbnailPath: thumbnailPath,
          durationSeconds: seconds,
          published: published,
          premium: premium,
        );
      }

      await load();
      if (!mounted) return;
      _message(row == null ? 'Lesson created.' : 'Lesson updated.');
    } catch (error) {
      if (!mounted) return;
      _message('Save failed: $error');
    } finally {
      if (mounted) {
        setState(() => saving = false);
        Navigator.of(context).pop();
      }
      title.dispose();
      description.dispose();
      lessonNumber.dispose();
      duration.dispose();
    }
  }

  Future<void> remove(String id) async {
    if (saving) return;
    if (!await confirmDelete(
      'Delete this lesson and its stored video/thumbnail?',
    )) {
      return;
    }

    try {
      await service.deleteLesson(id);
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'MANAGE LESSONS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => edit(),
            icon: const Icon(Icons.add, color: AppColors.lime),
          ),
        ],
      ),
      body: AppBackground(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final row = lessons[index];
                  final chapter = row['chapters'];
                  final chapterName = chapter is Map
                      ? chapter['chapter_name']?.toString() ?? 'Chapter'
                      : 'Chapter';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        '${row['lesson_number']}. ${row['title']}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '$chapterName • ${row['published'] == true ? 'Published' : 'Hidden'}',
                        style: const TextStyle(color: AppColors.secondaryText),
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            onPressed: () => edit(row),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.cyan,
                            ),
                          ),
                          IconButton(
                            onPressed: () => remove(row['id'].toString()),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _UploadingDialog extends StatelessWidget {
  const _UploadingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: const [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.lime,
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Text(
              'Uploading lesson... please keep this screen open.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
