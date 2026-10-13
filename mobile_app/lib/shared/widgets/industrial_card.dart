import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Industrial Surface Card
/// Clean, elevated container with crisp borders, subtle header badge,
/// and tactile feedback.
class IndustrialCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leadingIcon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;

  const IndustrialCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.leadingIcon,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? AppColors.darkSurface : AppColors.pureWhite;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.warmStone;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || leadingIcon != null || trailing != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  leadingIcon!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: defaultBorder),
        ],
        Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
      ],
    );

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? defaultBorder, width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.carbon.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                splashColor: AppColors.burntOrange.withValues(alpha: 0.08),
                highlightColor: AppColors.burntOrange.withValues(alpha: 0.04),
                child: content,
              ),
            )
          : content,
    );
  }
}
