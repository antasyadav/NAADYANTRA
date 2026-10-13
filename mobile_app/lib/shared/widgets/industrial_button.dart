import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum IndustrialButtonVariant { primary, secondary, danger, ghost }

class IndustrialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final IndustrialButtonVariant variant;
  final double? width;
  final double height;

  const IndustrialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = IndustrialButtonVariant.primary,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border;

    switch (variant) {
      case IndustrialButtonVariant.primary:
        bg = AppColors.burntOrange;
        fg = AppColors.pureWhite;
        border = BorderSide.none;
        break;
      case IndustrialButtonVariant.secondary:
        bg = isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.carbon;
        border = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.warmStone,
          width: 1.5,
        );
        break;
      case IndustrialButtonVariant.danger:
        bg = AppColors.alertDanger.withValues(alpha: 0.1);
        fg = AppColors.alertDanger;
        border = const BorderSide(color: AppColors.alertDanger, width: 1);
        break;
      case IndustrialButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextSecondary : AppColors.warmGraphite;
        border = BorderSide.none;
        break;
    }

    final childWidget = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: onPressed == null ? bg.withValues(alpha: 0.4) : bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: border,
        ),
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          splashColor: variant == IndustrialButtonVariant.primary
              ? AppColors.darkBurntOrange
              : AppColors.burntOrange.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(child: childWidget),
          ),
        ),
      ),
    );
  }
}
