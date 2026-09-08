import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import 'student_details_screen.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  final service = AdminService();
  List<Map<String, dynamic>> users = [];
  bool owner = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final userRows = await service.getUsers();
      final ownerValue = await service.isOwner();

      if (!mounted) return;

      setState(() {
        users = userRows;
        owner = ownerValue;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load users: $error')),
      );
    }
  }

  Future<bool> confirmAction(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('CONFIRM'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> removeStudent(String id) async {
    if (!await confirmAction('Remove this student account?')) {
      return;
    }

    try {
      await service.removeStudent(id);
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove student: $error')),
      );
    }
  }

  Future<void> manageAdmin(Map<String, dynamic> user) async {
    if (!owner) return;

    final isAdmin = user['role']?.toString() == 'admin';
    final message = isAdmin
        ? 'Remove admin role from this user?'
        : 'Make this user an admin?';

    if (!await confirmAction(message)) {
      return;
    }

    try {
      if (isAdmin) {
        await service.removeAdmin(user['id'].toString());
      } else {
        await service.addAdmin(user['id'].toString());
      }
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change role: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'MANAGE USERS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.lime,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final role = user['role']?.toString() ?? 'student';
                final subscription =
                    user['subscription_active'] == true;
                final progress = user['total_progress'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      user['name']?.toString() ?? 'Student',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${user['email'] ?? ''}\n'
                      'Role: $role\n'
                      'Subscription: ${subscription ? 'ACTIVE' : 'INACTIVE'}\n'
                      'Progress: $progress%',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentDetailsScreen(
                            user: user,
                          ),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'remove') {
                          await removeStudent(user['id'].toString());
                        } else if (value == 'admin') {
                          await manageAdmin(user);
                        }
                      },
                      itemBuilder: (context) {
                        final items = <PopupMenuEntry<String>>[];

                        if (role == 'student') {
                          items.add(
                            const PopupMenuItem<String>(
                              value: 'remove',
                              child: Text('Remove student'),
                            ),
                          );
                        }

                        if (owner && role != 'owner') {
                          items.add(
                            PopupMenuItem<String>(
                              value: 'admin',
                              child: Text(
                                role == 'admin'
                                    ? 'Remove admin'
                                    : 'Make admin',
                              ),
                            ),
                          );
                        }

                        return items;
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
