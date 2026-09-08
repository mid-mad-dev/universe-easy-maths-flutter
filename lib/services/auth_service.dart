import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({required String name, required String email, required String password}) {
    return client.auth.signUp(email: email.trim(), password: password, data: {'name': name.trim()});
  }

  Future<AuthResponse> signIn({required String email, required String password}) {
    return client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => client.auth.signOut();

  Future<void> sendResetEmail(String email) => client.auth.resetPasswordForEmail(email.trim());
}
