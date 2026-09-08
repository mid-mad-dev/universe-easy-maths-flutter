import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/lesson.dart';
import '../services/database_service.dart';
import 'lesson_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  final db = DatabaseService();
  List<Lesson> results = [];
  bool loading = false;

  Future<void> search(String value) async {
    final term = value.trim();
    if (term.isEmpty) { setState(() => results = []); return; }
    setState(() => loading = true);
    try {
      final r = await db.searchLessons(term);
      if (mounted) setState(() { results = r; loading = false; });
    } catch (e) {
      if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('SEARCH VIDEOS', style: TextStyle(fontWeight: FontWeight.w900))),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          TextField(controller: controller, onSubmitted: search, decoration: InputDecoration(hintText: 'Search lesson or topic...', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () => search(controller.text), icon: const Icon(Icons.arrow_forward)))),
          const SizedBox(height: 16),
          Expanded(child: loading ? const Center(child: CircularProgressIndicator(color: AppColors.purple)) : ListView.builder(itemCount: results.length, itemBuilder: (_, i) => Card(child: ListTile(title: Text(results[i].title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(results[i].description, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.play_arrow), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: results[i], lessons: [results[i]]))))))),
        ]),
      ),
    );
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }
}
