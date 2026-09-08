import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_background.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StudentDetailsScreen({
    super.key,
    required this.user,
  });

  @override
  State<StudentDetailsScreen> createState() =>
      _StudentDetailsScreenState();
}

class _StudentDetailsScreenState
    extends State<StudentDetailsScreen> {
  final service = AdminService();

  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> progress = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final id = widget.user['id'].toString();
      final questionRows =
          await service.studentQuestions(id);
      final progressRows =
          await service.studentProgress(id);

      if (!mounted) return;

      setState(() {
        questions = questionRows;
        progress = progressRows;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load student details: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'STUDENT DETAILS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AppBackground(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.lime,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    widget.user['name']?.toString() ??
                        'Student',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.user['email']?.toString() ?? '',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Subscription: ${widget.user['subscription_active'] == true ? 'ACTIVE' : 'INACTIVE'}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    'Overall progress: ${widget.user['total_progress'] ?? 0}%',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'COMPLETED / VIEWED LESSONS',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (progress.isEmpty)
                    const Text(
                      'No lesson progress yet.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                      ),
                    )
                  else
                    ...progress.map(
                      (row) => Card(
                        child: ListTile(
                          title: Text(
                            row['lesson_id']?.toString() ??
                                'Lesson',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'Watched: ${row['watched_percentage'] ?? 0}%',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          trailing: row['seen'] == true
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.cyan,
                                )
                              : null,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'QUESTIONS ASKED',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (questions.isEmpty)
                    const Text(
                      'No questions asked.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                      ),
                    )
                  else
                    ...questions.map(
                      (question) => Card(
                        child: ListTile(
                          title: Text(
                            question['question']?.toString() ??
                                '',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            question['answered'] == true
                                ? 'ANSWERED\n${question['answer'] ?? ''}'
                                : 'WAITING',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
