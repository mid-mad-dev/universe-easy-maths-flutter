import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/course.dart';
import '../services/database_service.dart';
import 'course_detail_screen.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});
  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final db = DatabaseService();
  List<Map<String, dynamic>> purchases = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await db.getMyPurchases();
      if (mounted) {
        setState(() {
          purchases = r;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'MY LEARNING',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : purchases.isEmpty
          ? const Center(
              child: Text(
                'Your purchased courses will appear here.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            )
          : RefreshIndicator(
              onRefresh: load,
              color: AppColors.purple,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [for (final row in purchases) _purchaseCard(row)],
              ),
            ),
    );
  }

  Widget _purchaseCard(Map<String, dynamic> row) {
    final courseMap = row['courses'];
    if (courseMap is! Map) return const SizedBox.shrink();
    final course = Course.fromMap(Map<String, dynamic>.from(courseMap));
    final status = '${row['payment_status'] ?? 'SUCCESS'}';
    final success = status == 'SUCCESS';
    final amount = row['amount'];
    final amountText = amount == null ? '' : '₹${amount.toString()}';
    final dateText = _formatDate(row['purchase_date']);
    final details = [
      if (amountText.isNotEmpty) amountText,
      status,
      if (dateText.isNotEmpty) dateText,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: success
              ? AppColors.lightTeal
              : AppColors.lightPurple,
          child: Icon(
            success ? Icons.check : Icons.hourglass_top,
            color: success ? AppColors.teal : AppColors.warning,
            size: 20,
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          details,
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
        ),
      ),
    );
  }
}
