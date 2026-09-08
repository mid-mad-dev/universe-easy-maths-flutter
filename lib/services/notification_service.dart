import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  SupabaseClient get supabase => Supabase.instance.client;
  String? get uid => supabase.auth.currentUser?.id;

  Stream<List<Map<String, dynamic>>> streamMine() {
    final id = uid;
    if (id == null) return const Stream.empty();
    return supabase.from('notifications').stream(primaryKey: ['id']).eq('user_id', id).order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> listMine() async {
    final id = uid;
    if (id == null) return [];
    final rows = await supabase.from('notifications').select().eq('user_id', id).order('created_at', ascending: false).limit(100);
    return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<int> unreadCount() async {
    final id = uid;
    if (id == null) return 0;
    final rows = await supabase.from('notifications').select('id').eq('user_id', id).eq('read', false);
    return (rows as List).length;
  }

  Future<void> markRead(String id) async {
    final user = uid;
    if (user == null) return;
    await supabase.from('notifications').update({'read': true}).eq('id', id).eq('user_id', user);
  }

  Future<void> markAllRead() async {
    final user = uid;
    if (user == null) return;
    await supabase.from('notifications').update({'read': true}).eq('user_id', user).eq('read', false);
  }
}
