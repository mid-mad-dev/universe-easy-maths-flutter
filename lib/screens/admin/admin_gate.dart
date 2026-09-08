import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import 'admin_dashboard.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});
  @override State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final service = AdminService();
  bool loading = true;
  bool allowed = false;
  @override void initState() { super.initState(); check(); }
  Future<void> check() async { allowed = await service.isStaff(); if (mounted) setState(() => loading = false); }
  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.purple)));
    if (!allowed) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: Text('You do not have Admin access.')));
    return const AdminDashboard();
  }
}
