import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool secondary;
  const AppButton({super.key, required this.label, this.onPressed, this.loading = false, this.secondary = false});

  @override
  Widget build(BuildContext context) {
    final content = loading
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label);
    if (secondary) {
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.cardBackground,
            foregroundColor: AppColors.text,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          child: content,
        ),
      );
    }
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(onPressed: loading ? null : onPressed, child: content),
    );
  }
}
