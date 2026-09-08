import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'about_screen.dart';
import 'admin/admin_gate.dart';
import 'auth_gate.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onSelectTab;
  const ProfileScreen({super.key, this.onSelectTab});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final db = DatabaseService();
  final auth = AuthService();
  Profile? profile;
  String? photoUrl;
  bool loading = true;
  bool savingPhoto = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final p = await db.getMyProfile();
      String? url;
      final photoPath = p?.profilePhoto?.trim();
      if (photoPath != null && photoPath.isNotEmpty) {
        try {
          url = await Supabase.instance.client.storage
              .from(AppConstants.profileBucket)
              .createSignedUrl(photoPath, 3600);
        } catch (_) {
          // Fall back to the placeholder icon if the photo cannot be read.
        }
      }
      if (!mounted) return;
      setState(() {
        profile = p;
        photoUrl = url;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load profile: $e';
      });
    }
  }

  Future<void> retry() async {
    setState(() {
      loading = true;
      error = null;
    });
    await load();
  }

  void goToTab(int index) => widget.onSelectTab?.call(index);

  Future<void> editName() async {
    final c = TextEditingController(text: profile?.name ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('EDIT NAME'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (ok != true || c.text.trim().isEmpty) {
      c.dispose();
      return;
    }
    try {
      await db.updateProfileName(c.text);
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save name: $e')));
    } finally {
      c.dispose();
    }
  }

  Future<void> changePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => savingPhoto = true);
    try {
      final storage = StorageService();
      final oldPath = profile?.profilePhoto?.trim();
      final newPath = await storage.uploadProfilePhoto(picked);
      await db.updateProfilePhoto(newPath);

      if (oldPath != null && oldPath.isNotEmpty && oldPath != newPath) {
        try {
          await storage.remove(AppConstants.profileBucket, oldPath);
        } catch (_) {
          // Old photo cleanup is best-effort.
        }
      }
      await load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update photo: $e')));
    } finally {
      if (mounted) setState(() => savingPhoto = false);
    }
  }

  Future<void> logout() async {
    await auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (loading) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    } else if (error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: AppColors.mutedText,
              ),
              const SizedBox(height: 14),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: retry, child: const Text('RETRY')),
            ],
          ),
        ),
      );
    } else {
      final p = profile;
      body = ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 43,
                  backgroundColor: AppColors.lightPurple,
                  backgroundImage: photoUrl == null
                      ? null
                      : NetworkImage(photoUrl!),
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 42,
                          color: AppColors.purple,
                        )
                      : null,
                ),
                if (savingPhoto)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 86,
                        height: 86,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: AppColors.purple,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: changePhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.photo_camera,
                            size: 16,
                            color: Color(0xFF08120A),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              p?.name.trim().isNotEmpty == true ? p!.name : 'Student',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              p?.email ?? '',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          const SizedBox(height: 26),
          _item(
            Icons.rocket_launch_outlined,
            'Continue Learning',
            () => goToTab(0),
          ),
          _item(Icons.school_outlined, 'My Learning', () => goToTab(3)),
          _item(Icons.question_answer_outlined, 'My Doubts', () => goToTab(2)),
          _item(
            Icons.info_outline,
            'About Universe Easy Maths',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          if (p?.isStaff == true)
            _item(
              Icons.admin_panel_settings_outlined,
              'Admin Dashboard',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminGate()),
              ),
            ),
          const SizedBox(height: 8),
          _item(Icons.logout, 'Logout', logout, color: AppColors.error),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (profile != null)
            IconButton(
              onPressed: editName,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _item(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = AppColors.purple,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
