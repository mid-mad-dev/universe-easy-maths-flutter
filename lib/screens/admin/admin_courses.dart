import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/admin_service.dart';

class AdminCourses extends StatefulWidget {
  const AdminCourses({super.key});
  @override
  State<AdminCourses> createState() => _AdminCoursesState();
}

class _AdminCoursesState extends State<AdminCourses> {
  final service = AdminService();
  List<Map<String, dynamic>> courses = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = await service.getCourses();
      if (mounted) {
        setState(() {
          courses = rows;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load courses: $e')));
      }
    }
  }

  Future<void> edit([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: '${row?['course_name'] ?? ''}');
    final description = TextEditingController(
      text: '${row?['description'] ?? ''}',
    );
    final price = TextEditingController(text: '${row?['price'] ?? 0}');
    bool premium = row?['premium'] == true;
    bool published = row?['published'] != false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(row == null ? 'ADD COURSE' : 'EDIT COURSE'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Course name'),
                ),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                SwitchListTile(
                  value: premium,
                  onChanged: (v) => setDialog(() => premium = v),
                  title: const Text('Premium'),
                ),
                SwitchListTile(
                  value: published,
                  onChanged: (v) => setDialog(() => published = v),
                  title: const Text('Published'),
                ),
              ],
            ),
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
      ),
    );

    if (ok != true || name.text.trim().isEmpty) return;
    final value = double.tryParse(price.text.trim()) ?? 0;
    if (row == null) {
      await service.createCourse(
        name: name.text,
        description: description.text,
        price: value,
        premium: premium,
        published: published,
      );
    } else {
      await service.updateCourse(
        id: '${row['id']}',
        name: name.text,
        description: description.text,
        price: value,
        premium: premium,
        published: published,
      );
    }
    await load();
  }

  Future<void> assignChapters(Map<String, dynamic> course) async {
    final all = await service.getChapters();
    final selected = (await service.getCourseChapterIds('${course['id']}'))
        .toSet();
    if (!mounted) return;
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final local = {...selected};
        return StatefulBuilder(
          builder: (context, setDialog) => AlertDialog(
            title: const Text('ASSIGN CHAPTERS'),
            content: SizedBox(
              width: 450,
              child: all.isEmpty
                  ? const Text('Create chapters first.')
                  : SingleChildScrollView(
                      child: Column(
                        children: all.map((c) {
                          final id = '${c['id']}';
                          return CheckboxListTile(
                            value: local.contains(id),
                            onChanged: (v) => setDialog(() {
                              if (v == true) {
                                local.add(id);
                              } else {
                                local.remove(id);
                              }
                            }),
                            title: Text(
                              '${c['chapter_number']}. ${c['chapter_name']}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, local.toList()),
                child: const Text('SAVE'),
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    await service.setCourseChapters('${course['id']}', result);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Course chapters updated.')));
    }
  }

  Future<void> remove(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('DELETE COURSE?'),
        content: const Text(
          'This removes the course and its chapter assignments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await service.deleteCourse(id);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'MANAGE COURSES',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: () => edit(), icon: const Icon(Icons.add)),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (_, i) {
                final c = courses[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${c['course_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '₹${c['price'] ?? 0} • ${c['premium'] == true ? 'Premium' : 'Free'}',
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          onPressed: () => assignChapters(c),
                          icon: const Icon(
                            Icons.account_tree_outlined,
                            color: AppColors.teal,
                          ),
                        ),
                        IconButton(
                          onPressed: () => edit(c),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => remove('${c['id']}'),
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
    );
  }
}
