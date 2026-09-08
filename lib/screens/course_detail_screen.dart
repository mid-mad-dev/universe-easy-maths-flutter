import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_colors.dart';
import '../models/chapter.dart';
import '../models/course.dart';
import '../services/database_service.dart';
import '../services/payment_service.dart';
import '../widgets/app_background.dart';
import 'chapter_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final database = DatabaseService();

  List<Chapter> chapters = [];
  bool loading = true;
  bool buying = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = await database.getCourseChapters(widget.course.id);

      final result = <Chapter>[];
      for (final row in rows) {
        final rawChapter = row['chapters'];
        if (rawChapter is Map) {
          result.add(Chapter.fromMap(Map<String, dynamic>.from(rawChapter)));
        }
      }

      if (!mounted) return;

      setState(() {
        chapters = result;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load course: $error')));
    }
  }

  Future<void> _buy() async {
    if (buying) return;
    setState(() => buying = true);
    try {
      final profile = await database.getMyProfile();
      final email = profile?.email.trim().isNotEmpty == true
          ? profile!.email
          : (Supabase.instance.client.auth.currentUser?.email ?? '');

      final paid = await PaymentService().startCoursePayment(
        courseId: widget.course.id,
        courseName: widget.course.name,
        amount: widget.course.price,
        email: email,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paid
                ? 'Payment successful! The course is now in My Learning.'
                : 'This course is already in My Learning.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => buying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.course.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              widget.course.name,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.course.description,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                widget.course.premium
                    ? 'PREMIUM • ₹${widget.course.price.toStringAsFixed(0)}'
                    : 'FREE',
                style: TextStyle(
                  color: widget.course.premium
                      ? AppColors.lime
                      : AppColors.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (widget.course.premium) ...[
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: buying ? null : _buy,
                child: buying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF08120A),
                        ),
                      )
                    : Text(
                        'BUY NOW • ₹${widget.course.price.toStringAsFixed(0)}',
                      ),
              ),
            ],
            const SizedBox(height: 25),
            const Text(
              'CHAPTERS',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              )
            else if (chapters.isEmpty)
              const Text(
                'No chapters assigned to this course yet.',
                style: TextStyle(color: AppColors.secondaryText),
              )
            else
              ...chapters.map(
                (chapter) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      '${chapter.number}. ${chapter.name}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${chapter.totalLessons} lessons',
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.mutedText,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChapterDetailScreen(chapter: chapter),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
