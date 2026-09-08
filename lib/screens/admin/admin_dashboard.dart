import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import 'admin_chapters.dart';
import 'admin_lessons.dart';
import 'admin_courses.dart';
import 'admin_questions.dart';
import 'admin_users.dart';
import 'admin_payments.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final service = AdminService();
  Map<String, int> counts = {};
  bool owner = false;
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final users = await service.getUsers();
      final chapters = await service.getChapters();
      final lessons = await service.getLessons();
      final courses = await service.getCourses();
      final questions = await service.getQuestions();
      owner = await service.isOwner();
      if (mounted) setState(() { counts = {'Students': users.where((u) => u['role'] == 'student').length, 'Chapters': chapters.length, 'Lessons': lessons.length, 'Courses': courses.length, 'Questions': questions.length}; loading = false; });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ADMIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900))),
      body: loading ? const Center(child: CircularProgressIndicator(color: AppColors.purple)) : ListView(padding: const EdgeInsets.all(18), children: [
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6, children: counts.entries.map((e) => Card(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${e.value}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.purple)), Text(e.key, style: const TextStyle(color: AppColors.secondaryText))])))).toList()),
        const SizedBox(height: 20),
        _go('MANAGE CHAPTERS', Icons.menu_book, const AdminChapters()),
        _go('MANAGE LESSONS / VIDEOS', Icons.play_circle, const AdminLessons()),
        _go('MANAGE COURSES', Icons.workspace_premium, const AdminCourses()),
        _go('MANAGE QUESTIONS', Icons.question_answer, const AdminQuestions()),
        _go('MANAGE USERS', Icons.people, const AdminUsers()),
        _go('PAYMENTS', Icons.payments, const AdminPayments()),
        if (owner) const Padding(padding: EdgeInsets.only(top: 20), child: Text('OWNER: You can add/remove admins.', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  Widget _go(String title, IconData icon, Widget page) => Card(child: ListTile(leading: Icon(icon, color: AppColors.teal), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => load())));
}
