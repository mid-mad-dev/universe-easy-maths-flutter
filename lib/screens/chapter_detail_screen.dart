import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/chapter.dart';
import '../models/lesson.dart';
import '../services/database_service.dart';
import '../services/progress_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/progress_bar.dart';
import 'lesson_screen.dart';

class ChapterDetailScreen extends StatefulWidget {
  final Chapter chapter;
  const ChapterDetailScreen({super.key, required this.chapter});
  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  final db = DatabaseService();
  final progress = ProgressService();
  List<Lesson> lessons = [];
  final Map<String, bool> seen = {};
  double chapterProgress = 0;
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final result = await db.getLessons(widget.chapter.id);
      for (final lesson in result) {
        final p = await progress.getLessonProgress(lesson.id);
        seen[lesson.id] = p?['seen'] == true;
      }
      final value = await progress.getChapterProgress(widget.chapter.id);
      if (!mounted) return;
      setState(() { lessons = result; chapterProgress = value; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load lessons: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.chapter.name, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: AppBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(widget.chapter.name, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(widget.chapter.description, style: const TextStyle(color: AppColors.secondaryText)),
                  const SizedBox(height: 16),
                  AppProgressBar(value: chapterProgress, height: 9),
                  const SizedBox(height: 7),
                  Text('${(chapterProgress * 100).round()}% Complete', style: const TextStyle(color: AppColors.secondaryText)),
                  const SizedBox(height: 18),
                  ...lessons.map((lesson) => _lessonTile(lesson)),
                ],
              ),
      ),
    );
  }

  Widget _lessonTile(Lesson lesson) {
    final complete = seen[lesson.id] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson, lessons: lessons))).then((_) => load()),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(backgroundColor: complete ? AppColors.lightTeal : AppColors.lightPurple, child: complete ? const Icon(Icons.check, color: AppColors.teal) : Text('${lesson.number}', style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w900))),
          title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(complete ? 'Seen • Rewatch anytime' : '${lesson.durationSeconds}s', style: const TextStyle(color: AppColors.secondaryText)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
        ),
      ),
    );
  }
}
