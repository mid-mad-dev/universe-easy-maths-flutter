import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppProgressBar extends StatelessWidget {
  final double value;
  final double height;
  const AppProgressBar({super.key, required this.value, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: AppColors.lightPurple,
        valueColor: const AlwaysStoppedAnimation(AppColors.purple),
      ),
    );
  }
}
