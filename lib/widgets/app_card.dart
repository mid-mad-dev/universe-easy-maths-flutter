import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color = AppColors.cardBackground});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
