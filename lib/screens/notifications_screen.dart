import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final service = NotificationService();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await service.listMine();
      if (!mounted) return;
      setState(() {
        rows = result;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Notifications are temporarily unavailable.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: () async { await service.markAllRead(); await load(); }, icon: const Icon(Icons.done_all))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : error != null
          ? Center(child: Text(error!))
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.streamMine(),
        builder: (context, snapshot) {
          final data = snapshot.hasData ? snapshot.data! : rows;
          if (data.isEmpty) return const Center(child: Text('No notifications yet.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final n = data[i];
              final read = n['read'] == true;
              return Card(
                color: read ? AppColors.cardBackground : AppColors.cardBackgroundSecondary,
                child: ListTile(
                  leading: Icon(read ? Icons.notifications_none : Icons.notifications_active, color: AppColors.teal),
                  title: Text('${n['title'] ?? 'Notification'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${n['message'] ?? ''}'),
                  onTap: () async { await service.markRead('${n['id']}'); await load(); },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
