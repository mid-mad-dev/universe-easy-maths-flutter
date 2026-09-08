import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_background.dart';

class AdminQuestions extends StatefulWidget {
  const AdminQuestions({super.key});

  @override
  State<AdminQuestions> createState() => _AdminQuestionsState();
}

class _AdminQuestionsState extends State<AdminQuestions> {
  final service = AdminService();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await service.getQuestions();
      if (!mounted) return;
      setState(() {
        rows = data;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load questions: $error')),
      );
    }
  }

  Future<void> answer(Map<String, dynamic> row) async {
    final controller = TextEditingController(
      text: row['answer']?.toString() ?? '',
    );

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            row['answered'] == true ? 'EDIT ANSWER' : 'ANSWER QUESTION',
          ),
          content: TextField(
            controller: controller,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => Navigator.pop(dialogContext, true),
            decoration: const InputDecoration(labelText: 'Answer'),
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

    if (save != true) {
      controller.dispose();
      return;
    }

    final text = controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    controller.dispose();

    if (text.isEmpty) return;

    try {
      await service.answerQuestion(
        questionId: row['id'].toString(),
        answer: text,
      );
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Answer failed: $error')));
    }
  }

  Future<void> removeQuestion(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('DELETE QUESTION?'),
          content: const Text('Delete this question and its answer?'),
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

    if (confirmed != true) return;

    try {
      await service.deleteQuestion(id);
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  Future<void> removeAnswer(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('DELETE ANSWER?'),
          content: const Text(
            'Remove the admin answer and leave the doubt open?',
          ),
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

    if (confirmed != true) return;

    try {
      await service.deleteAnswer(id);
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Answer delete failed: $error')));
    }
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.topRight,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'MANAGE QUESTIONS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AppBackground(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              )
            : rows.isEmpty
            ? const Center(
                child: Text(
                  'No questions yet.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final student = row['student'] is Map
                      ? Map<String, dynamic>.from(row['student'])
                      : <String, dynamic>{};

                  final answered = row['answered'] == true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['name']?.toString() ?? 'Student',
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student['email']?.toString() ?? '',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            row['question']?.toString() ?? '',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (row['image_url'] != null &&
                              (row['image_url'] as String).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTap: () =>
                                    _showImage(row['image_url'] as String),
                                child: CachedNetworkImage(
                                  imageUrl: row['image_url'] as String,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                  placeholder: (context, url) => const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.lime,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const SizedBox(
                                        height: 200,
                                        child: Center(
                                          child: Text(
                                            'Could not load image.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            answered ? '✓ ANSWERED' : 'WAITING FOR ANSWER',
                            style: TextStyle(
                              color: answered
                                  ? AppColors.cyan
                                  : AppColors.warning,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (answered && row['answer'] != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Answer: ${row['answer']}',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete answer',
                                  onPressed: () =>
                                      removeAnswer(row['id'].toString()),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => answer(row),
                                  child: Text(
                                    answered ? 'EDIT ANSWER' : 'ANSWER',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: () =>
                                    removeQuestion(row['id'].toString()),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
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
