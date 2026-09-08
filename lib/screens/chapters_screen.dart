import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/chapter.dart';
import '../services/database_service.dart';
import '../services/progress_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/progress_bar.dart';
import 'chapter_detail_screen.dart';

class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key});
  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  final db = DatabaseService();
  final progress = ProgressService();
  List<Chapter> chapters = [];
  final Map<String, double> values = {};
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final result = await db.getChapters();
      for (final c in result) {
        values[c.id] = await progress.getChapterProgress(c.id);
      }
      if (!mounted) return;
      setState(() { chapters = result; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load chapters: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CHAPTERS', style: TextStyle(fontWeight: FontWeight.w900))),
      body: AppBackground(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: chapters.length,
                itemBuilder: (context, i) {
                  final c = chapters[i];
                  final p = values[c.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterDetailScreen(chapter: c))).then((_) => load()),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            CircleAvatar(backgroundColor: AppColors.lightPurple, child: Text(c.number.toString().padLeft(2, '0'), style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w900))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(c.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                            const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.mutedText),
                          ]),
                          const SizedBox(height: 10),
                          Text(c.description, style: const TextStyle(color: AppColors.secondaryText)),
                          const SizedBox(height: 12),
                          AppProgressBar(value: p),
                          const SizedBox(height: 7),
                          Text('${(p * 100).round()}% Complete • ${c.totalLessons} Lessons', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
