import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// Widget logo utama aplikasi Tokoku reusable.
class AppLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 88,
    this.iconSize = 48,
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.store_rounded, size: iconSize, color: Colors.white),
    );
  }
}
