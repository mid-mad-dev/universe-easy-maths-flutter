import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, size: 54, color: AppColors.purple),
            SizedBox(height: 18),
            Text(AppConstants.appName, style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900)),
            SizedBox(height: 7),
            Text(AppConstants.tagline, style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
