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

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(text, style: AppTextStyles.titleMedium.copyWith(
                color: isOutlined ? AppColors.primary : AppColors.onPrimary,
              )),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(onPressed: isLoading ? null : onPressed, child: child)
        : ElevatedButton(onPressed: isLoading ? null : onPressed, child: child);

    return SizedBox(width: width ?? double.infinity, height: 50, child: button);
  }
}
