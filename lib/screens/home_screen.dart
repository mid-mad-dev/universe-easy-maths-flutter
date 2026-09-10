import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/chapter.dart';
import '../services/database_service.dart';
import '../services/progress_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/progress_bar.dart';
import 'chapter_detail_screen.dart';
import 'chapters_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'main_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const MainShell();
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});
  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final db = DatabaseService();
  final progress = ProgressService();
  String name = 'Student';
  List<Chapter> chapters = [];
  double overall = 0;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final profile = await db.getMyProfile();
      final chapterData = await db.getChapters();
      final p = await progress.getOverallProgress();
      if (!mounted) return;
      setState(() {
        name = profile?.name.trim().isNotEmpty == true
            ? profile!.name
            : 'Student';
        chapters = chapterData;
        overall = p;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load home: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'UNIVERSE EASY MATHS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: AppBackground(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              )
            : error != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: load,
                color: AppColors.purple,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    Text(
                      'Hi, $name 👋',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to learn?',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CONTINUE LEARNING',
                            style: TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Keep building your mathematics skills.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 15),
                          AppProgressBar(value: overall, height: 9),
                          const SizedBox(height: 8),
                          Text(
                            '${(overall * 100).round()}% Complete',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: chapters.isEmpty
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ChaptersScreen(),
                                    ),
                                  ),
                            child: const Text('CONTINUE'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CHAPTERS',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChaptersScreen(),
                            ),
                          ),
                          child: const Text('VIEW ALL'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (chapters.isEmpty) _buildEmptyState(),
                    ...chapters.take(5).map(_chapterCard),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 14),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: load, child: const Text('RETRY')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 18),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 42,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: 12),
          const Text(
            'No chapters published yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: load, child: const Text('REFRESH')),
        ],
      ),
    );
  }

  Widget _chapterCard(Chapter chapter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChapterDetailScreen(chapter: chapter),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.lightPurple,
                child: Text(
                  chapter.number.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${chapter.totalLessons} Lessons',
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
