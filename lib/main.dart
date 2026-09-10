import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_colors.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'services/push_service.dart';
import 'screens/splash_screen.dart';
import 'screens/first_run_config_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  Widget? screen;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    setState(() => screen = null);
    try {
      final config = await AppConstants.load().timeout(
        const Duration(seconds: 10),
      );

      if (!config.isConfigured) {
        if (mounted) setState(() => screen = const _FirstRunApp());
        return;
      }

      await Supabase.initialize(
        url: config.url,
        publishableKey: config.publishableKey,
      ).timeout(const Duration(seconds: 15));

      // Fire-and-forget: push must never block or break app startup.
      // No-op on web/desktop or when the build has no Firebase config.
      unawaited(PushService.instance.initialize());

      if (mounted) setState(() => screen = const UniverseEasyMathsApp());
    } catch (_) {
      if (mounted) {
        setState(() => screen = _StartupErrorApp(onRetry: initialize));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return screen ?? const _LoadingApp();
  }
}

class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const Scaffold(
        backgroundColor: Color(0xFF070C20),
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      ),
    );
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
      home: FirstRunConfigScreen(
        onConfigurationSaved: () => runApp(const _BootstrapApp()),
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupErrorApp({required this.onRetry});

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: AppColors.warning, size: 52),
                const SizedBox(height: 16),
                const Text(
                  'We could not connect right now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('TRY AGAIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
