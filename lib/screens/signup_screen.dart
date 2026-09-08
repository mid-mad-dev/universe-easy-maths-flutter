import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final auth = AuthService();
  bool loading = false;

  Future<void> submit() async {
    if ([name, email, password, confirm].any((c) => c.text.trim().isEmpty)) {
      _message('Complete all fields.');
      return;
    }
    if (password.text != confirm.text) {
      _message('Passwords do not match.');
      return;
    }
    if (password.text.length < 6) {
      _message('Password must be at least 6 characters.');
      return;
    }
    setState(() => loading = true);
    try {
      final result = await auth.signUp(name: name.text, email: email.text, password: password.text);
      if (!mounted) return;
      if (result.session == null) {
        _message('Account created. Verify your email before logging in.');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthGate()), (_) => false);
      }
    } on AuthException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('Could not create account: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  void dispose() {
    name.dispose(); email.dispose(); password.dispose(); confirm.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('CREATE YOUR ACCOUNT', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Start learning mathematics in short, focused lessons.', style: TextStyle(color: AppColors.secondaryText)),
                  const SizedBox(height: 28),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 14),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
                  const SizedBox(height: 14),
                  TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline))),
                  const SizedBox(height: 22),
                  AppButton(label: 'CREATE ACCOUNT', loading: loading, onPressed: submit),
                  const SizedBox(height: 15),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Already have an account?', style: TextStyle(color: AppColors.secondaryText)), TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('LOGIN'))]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
