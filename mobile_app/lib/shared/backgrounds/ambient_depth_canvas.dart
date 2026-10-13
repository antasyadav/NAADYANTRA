import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Ambient Depth Canvas
///
/// Encapsulates views with precision industrial corner reticles [ ],
/// subtle ambient lighting gradients, and frame boundary rules.
class AmbientDepthCanvas extends StatelessWidget {
  final Widget child;
  final bool showReticles;
  final EdgeInsets padding;

  const AmbientDepthCanvas({
    super.key,
    required this.child,
    this.showReticles = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomPaint(
      painter: _ReticlePainter(isDark: isDark, showReticles: showReticles),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  final bool isDark;
  final bool showReticles;

  _ReticlePainter({required this.isDark, required this.showReticles});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showReticles) return;

    final reticleColor = isDark
        ? AppColors.burntOrange.withValues(alpha: 0.35)
        : AppColors.burntOrange.withValues(alpha: 0.4);

    final paint = Paint()
      ..color = reticleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const arm = 10.0;
    const inset = 6.0;

    // Top-Left
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset + arm, inset),
      paint,
    );
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset, inset + arm),
      paint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset - arm, inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + arm),
      paint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + arm, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset, size.height - inset - arm),
      paint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset - arm, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset, size.height - inset - arm),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.showReticles != showReticles;
  }
}
