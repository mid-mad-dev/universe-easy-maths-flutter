import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mobile = constraints.maxWidth < 700;
              final pad = mobile ? 28.0 : 60.0;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.purple, AppColors.teal])),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 25),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(text: 'Maths, but in ', style: TextStyle(color: AppColors.text, fontSize: 42, height: 1.05, fontWeight: FontWeight.w900)),
                              TextSpan(text: '60-second', style: TextStyle(color: AppColors.purple, fontSize: 42, height: 1.05, fontWeight: FontWeight.w900)),
                              TextSpan(text: '\nbites.', style: TextStyle(color: AppColors.text, fontSize: 42, height: 1.05, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(AppConstants.supportText, style: TextStyle(color: AppColors.secondaryText, fontSize: 16, height: 1.55)),
                        const SizedBox(height: 25),
                        Flex(
                          direction: mobile ? Axis.vertical : Axis.horizontal,
                          children: [
                            Expanded(flex: mobile ? 0 : 1, child: AppButton(label: 'START LEARNING FREE', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())))),
                            if (!mobile) const SizedBox(width: 12) else const SizedBox(height: 12),
                            Expanded(flex: mobile ? 0 : 1, child: AppButton(label: 'I ALREADY HAVE AN ACCOUNT', secondary: true, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())))),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Flex(
                          direction: mobile ? Axis.vertical : Axis.horizontal,
                          children: [
                            Expanded(flex: mobile ? 0 : 1, child: const _Feature(icon: Icons.play_circle_outline, title: 'Short-form lessons', text: 'Vertical, snappy videos designed for tiny attention spans.')),
                            if (!mobile) const SizedBox(width: 14) else const SizedBox(height: 14),
                            Expanded(flex: mobile ? 0 : 1, child: const _Feature(icon: Icons.bar_chart_outlined, title: 'Progress per chapter', text: 'Watched videos are marked Seen and remain replayable.')),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Flex(
                          direction: mobile ? Axis.vertical : Axis.horizontal,
                          children: [
                            Expanded(flex: mobile ? 0 : 1, child: const _Feature(icon: Icons.question_answer_outlined, title: 'Doubt corner', text: 'Ask questions and receive teacher/admin answers.')),
                            if (!mobile) const SizedBox(width: 14) else const SizedBox(height: 14),
                            Expanded(flex: mobile ? 0 : 1, child: const _Feature(icon: Icons.shield_outlined, title: 'Safe & private', text: 'Student data stays private from other students.')),
                          ],
                        ),
                        const SizedBox(height: 35),
                        const Text(AppConstants.companyName, style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        const Text(AppConstants.location, style: TextStyle(color: AppColors.mutedText)),
                        const SizedBox(height: 8),
                        Text('${AppConstants.founder} — Founder', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                        Text('${AppConstants.coFounder} — Co-Founder', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Feature({required this.icon, required this.title, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.teal), const SizedBox(height: 11), Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(text, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, height: 1.4))]),
    );
  }
}
