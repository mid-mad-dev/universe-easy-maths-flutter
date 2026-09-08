import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_colors.dart';
import '../../widgets/app_background.dart';

class AdminPayments extends StatefulWidget {
  const AdminPayments({super.key});

  @override
  State<AdminPayments> createState() => _AdminPaymentsState();
}

class _AdminPaymentsState extends State<AdminPayments> {
  final client = Supabase.instance.client;

  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await client
          .from('purchases')
          .select('*, courses(*)')
          .order('purchase_date', ascending: false);

      final list = <Map<String, dynamic>>[];

      for (final raw in data) {
        final row = Map<String, dynamic>.from(raw);
        final user = await client
            .from('profiles')
            .select('name,email')
            .eq('id', row['user_id'].toString())
            .maybeSingle();

        row['student'] = user;
        list.add(row);
      }

      if (!mounted) return;

      setState(() {
        rows = list;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load payments: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'PAYMENTS',
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
            : rows.isEmpty
                ? const Center(
                    child: Text(
                      'No payments yet.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final student = row['student'] is Map
                          ? Map<String, dynamic>.from(
                              row['student'],
                            )
                          : <String, dynamic>{};
                      final course = row['courses'] is Map
                          ? Map<String, dynamic>.from(
                              row['courses'],
                            )
                          : <String, dynamic>{};

                      final email =
                          student['email']?.toString() ?? '';
                      final courseName =
                          course['course_name']?.toString() ??
                              'Course';
                      final amount =
                          row['amount']?.toString() ?? '0';
                      final status =
                          row['payment_status']?.toString() ??
                              'PENDING';

                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            email,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            '$courseName • ₹$amount\nStatus: $status',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
