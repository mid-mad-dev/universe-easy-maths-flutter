import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_background.dart';

class AdminChapters extends StatefulWidget {
  const AdminChapters({super.key});

  @override
  State<AdminChapters> createState() => _AdminChaptersState();
}

class _AdminChaptersState extends State<AdminChapters> {
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
      final data = await service.getChapters();
      if (!mounted) return;
      setState(() {
        rows = data;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load chapters: $error')),
      );
    }
  }

  Future<bool> confirmDelete(String message) async {
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
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    final name = TextEditingController(
      text: row?['chapter_name']?.toString() ?? '',
    );
    final number = TextEditingController(
      text: row?['chapter_number']?.toString() ?? '${rows.length + 1}',
    );
    final description = TextEditingController(
      text: row?['description']?.toString() ?? '',
    );

    bool published = row?['published'] != false;
    bool premium = row?['premium'] == true;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(row == null ? 'ADD CHAPTER' : 'EDIT CHAPTER'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Chapter Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: number,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Chapter Number',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: description,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    SwitchListTile(
                      value: premium,
                      title: const Text('Premium'),
                      onChanged: (value) {
                        setLocal(() => premium = value);
                      },
                    ),
                    SwitchListTile(
                      value: published,
                      title: const Text('Published'),
                      onChanged: (value) {
                        setLocal(() => published = value);
                      },
                    ),
                  ],
                ),
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
      },
    );

    if (save != true || name.text.trim().isEmpty) {
      name.dispose();
      number.dispose();
      description.dispose();
      return;
    }

    try {
      final chapterNumber = int.tryParse(number.text.trim()) ?? 1;

      if (row == null) {
        await service.createChapter(
          name: name.text,
          number: chapterNumber,
          description: description.text,
          premium: premium,
          published: published,
        );
      } else {
        await service.updateChapter(
          id: row['id'].toString(),
          name: name.text,
          number: chapterNumber,
          description: description.text,
          premium: premium,
          published: published,
        );
      }
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      name.dispose();
      number.dispose();
      description.dispose();
    }
  }

  Future<void> remove(String id) async {
    if (!await confirmDelete('Delete this chapter and its lessons?')) {
      return;
    }

    try {
      await service.deleteChapter(id);
      await load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'MANAGE CHAPTERS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => edit(),
            icon: const Icon(Icons.add, color: AppColors.lime),
          ),
        ],
      ),
      body: AppBackground(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.lime),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        '${row['chapter_number']}. ${row['chapter_name']}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${row['total_lessons'] ?? 0} lessons',
                        style: const TextStyle(color: AppColors.secondaryText),
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            onPressed: () => edit(row),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.cyan,
                            ),
                          ),
                          IconButton(
                            onPressed: () => remove(row['id'].toString()),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
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
