import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientTeal, AppColors.gradientNavy, AppColors.gradientPurple],
          stops: [0, 0.58, 1],
        ),
      ),
      child: child,
    );
  }
}
