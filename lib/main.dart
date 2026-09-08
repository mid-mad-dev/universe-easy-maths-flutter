import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/first_run_config_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConstants.load();

  if (!config.isConfigured) {
    runApp(const _FirstRunApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
    runApp(const UniverseEasyMathsApp());
  } catch (error) {
    runApp(_StartupErrorApp(error: error.toString()));
  }
}

class UniverseEasyMathsApp extends StatelessWidget {
  const UniverseEasyMathsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}

class _FirstRunApp extends StatelessWidget {
  const _FirstRunApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.dark,
      home: const FirstRunConfigScreen(),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  final String error;

  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        backgroundColor: const Color(0xFF070C20),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Supabase startup failed:\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
