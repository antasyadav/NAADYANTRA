import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum StatusType {
  online,
  offline,
  active,
  completed,
  danger,
  caution,
  ok,
  neutral,
}

class StatusPill extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool showDot;

  const StatusPill({
    super.key,
    required this.label,
    this.type = StatusType.neutral,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    Color dot;

    switch (type) {
      case StatusType.online:
      case StatusType.ok:
      case StatusType.active:
        bg = AppColors.alertOk.withValues(alpha: 0.1);
        border = AppColors.alertOk.withValues(alpha: 0.3);
        text = AppColors.alertOk;
        dot = AppColors.alertOk;
        break;
      case StatusType.danger:
        bg = AppColors.alertDanger.withValues(alpha: 0.1);
        border = AppColors.alertDanger.withValues(alpha: 0.3);
        text = AppColors.alertDanger;
        dot = AppColors.alertDanger;
        break;
      case StatusType.caution:
        bg = AppColors.alertCaution.withValues(alpha: 0.12);
        border = AppColors.alertCaution.withValues(alpha: 0.35);
        text = AppColors.alertCaution;
        dot = AppColors.alertCaution;
        break;
      case StatusType.completed:
        bg = AppColors.burntOrange.withValues(alpha: 0.1);
        border = AppColors.burntOrange.withValues(alpha: 0.3);
        text = AppColors.darkBurntOrange;
        dot = AppColors.burntOrange;
        break;
      case StatusType.offline:
      case StatusType.neutral:
        bg = AppColors.softSand.withValues(alpha: 0.3);
        border = AppColors.warmStone;
        text = AppColors.warmGraphite;
        dot = AppColors.warmGraphite;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
