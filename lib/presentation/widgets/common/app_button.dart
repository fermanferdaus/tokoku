import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Tombol reusable dengan variant primary dan outlined.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final Color? color;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isOutlined ? Colors.transparent : AppColors.primary);
    final onColor = color != null ? Colors.white : (isOutlined ? AppColors.primary : AppColors.onPrimary);

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: onColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: onColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: AppTextStyles.titleMedium.copyWith(color: onColor),
              ),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color ?? AppColors.primary),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: effectiveColor,
              foregroundColor: onColor,
            ),
            child: child,
          );

    return SizedBox(width: width ?? double.infinity, height: 50, child: button);
  }
}
