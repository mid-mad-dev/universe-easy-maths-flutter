import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class DoubtsScreen extends StatefulWidget {
  const DoubtsScreen({super.key});
  @override
  State<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtsScreenState extends State<DoubtsScreen> {
  final db = DatabaseService();
  final storage = StorageService();
  List<Map<String, dynamic>> questions = [];
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { final r = await db.getMyQuestions(); if (mounted) setState(() { questions = r; loading = false; }); }
    catch (e) { if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load doubts: $e'))); } }
  }

  Future<void> ask() async {
    final text = TextEditingController();
    XFile? image;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('ASK A DOUBT'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: text, maxLines: 5, decoration: const InputDecoration(hintText: 'Write your question...')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text(image == null ? 'No image attached.' : image!.name, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: () async { final picked = await ImagePicker().pickImage(source: ImageSource.gallery); if (picked != null) setDialog(() => image = picked); }, icon: const Icon(Icons.image_outlined)),
            ]),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('SUBMIT'))],
        ),
      ),
    );
    if (result != true || text.text.trim().isEmpty) return;
    try {
      String? imagePath;
      if (image != null) imagePath = await storage.uploadDoubtImage(image!);
      await db.createQuestion(text: text.text, imagePath: imagePath);
      await load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doubt submitted.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit doubt: $e'))); }
  }

  Future<void> deleteQuestion(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete question?'), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE'))]));
    if (ok != true) return;
    try { await db.deleteOwnQuestion(id); await load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('DOUBT CORNER', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: ask, icon: const Icon(Icons.add_circle_outline))]),
      body: loading ? const Center(child: CircularProgressIndicator(color: AppColors.purple)) : RefreshIndicator(
        onRefresh: load, color: AppColors.purple,
        child: questions.isEmpty ? ListView(children: const [SizedBox(height: 170), Icon(Icons.help_outline, size: 55, color: AppColors.teal), SizedBox(height: 12), Center(child: Text('No doubts yet.', style: TextStyle(fontWeight: FontWeight.w800)))]) : ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: questions.length,
          itemBuilder: (_, i) {
            final q = questions[i];
            final answered = q['answered'] == true;
            return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('${q['question'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), IconButton(onPressed: () => deleteQuestion('${q['id']}'), icon: const Icon(Icons.delete_outline, color: AppColors.error))]),
              const SizedBox(height: 10),
              Text(answered ? 'ANSWERED' : 'WAITING FOR ANSWER', style: TextStyle(color: answered ? AppColors.teal : AppColors.warning, fontWeight: FontWeight.w800, fontSize: 11)),
              if (answered) ...[const SizedBox(height: 10), Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppColors.lightTeal, borderRadius: BorderRadius.circular(12)), child: Text('${q['answer'] ?? ''}'))],
            ])));
          },
        ),
      ),
    );
  }
}
