import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = AppColors.cardBackground,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}
