import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/course.dart';
import '../services/database_service.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});
  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final db = DatabaseService();
  List<Course> courses = [];
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { final r = await db.getCourses(); if (mounted) setState(() { courses = r; loading = false; }); }
    catch (e) { if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load courses: $e'))); } }
  }

  @override
  Widget build(BuildContext context) {
    final free = courses.where((c) => !c.premium).toList();
    final paid = courses.where((c) => c.premium).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('COURSES', style: TextStyle(fontWeight: FontWeight.w900))),
      body: loading ? const Center(child: CircularProgressIndicator(color: AppColors.purple)) : RefreshIndicator(
        onRefresh: load,
        color: AppColors.purple,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          if (free.isNotEmpty) ...[const Text('FREE COURSES', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 10), ...free.map(_card), const SizedBox(height: 20)],
          if (paid.isNotEmpty) ...[const Text('PREMIUM COURSES', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 10), ...paid.map(_card)],
          if (free.isEmpty && paid.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(80), child: Text('No courses published yet.'))),
        ]),
      ),
    );
  }

  Widget _card(Course c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(width: 70, height: 70, decoration: BoxDecoration(color: c.premium ? AppColors.lightPurple : AppColors.lightTeal, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.menu_book_rounded, color: c.premium ? AppColors.purple : AppColors.teal)),
        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(c.premium ? '₹${c.price.toStringAsFixed(0)}' : 'FREE', style: TextStyle(color: c.premium ? AppColors.purple : AppColors.teal, fontWeight: FontWeight.w900)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: c))),
      ),
    );
  }
}
