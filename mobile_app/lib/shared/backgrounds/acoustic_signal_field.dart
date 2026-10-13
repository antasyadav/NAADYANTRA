import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/motion_tokens.dart';

/// Acoustic Signal Field
///
/// Draws multi-harmonic acoustic frequency waves drifting slowly.
/// Designed for high-impact cinematic screens like Login, Inspection, and Home.
class AcousticSignalField extends StatefulWidget {
  final Widget? child;
  final double height;
  final double opacity;
  final bool animate;

  const AcousticSignalField({
    super.key,
    this.child,
    this.height = 180.0,
    this.opacity = 0.6,
    this.animate = true,
  });

  @override
  State<AcousticSignalField> createState() => _AcousticSignalFieldState();
}

class _AcousticSignalFieldState extends State<AcousticSignalField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.durationWave,
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AcousticSignalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isReduced = MotionTokens.isReducedMotion(context);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _AcousticSignalPainter(
          phase: isReduced || !widget.animate
              ? 0.0
              : _controller.value * 2 * math.pi,
          isDark: isDark,
          opacity: widget.opacity,
        ),
        child: widget.child,
      ),
    );
  }
}

class _AcousticSignalPainter extends CustomPainter {
  final double phase;
  final bool isDark;
  final double opacity;

  _AcousticSignalPainter({
    required this.phase,
    required this.isDark,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Harmonic 1 (Primary Burnt Orange probe frequency)
    final path1 = Path();
    final paint1 = Paint()
      ..color = AppColors.burntOrange.withValues(alpha: 0.45 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Harmonic 2 (Secondary Subharmonic Warm Stone / Graphite)
    final path2 = Path();
    final paint2 = Paint()
      ..color = (isDark ? AppColors.darkTextSecondary : AppColors.warmGraphite)
          .withValues(alpha: 0.25 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Harmonic 3 (Ultra-high frequency acoustic burst carrier)
    final path3 = Path();
    final paint3 = Paint()
      ..color = AppColors.darkBurntOrange.withValues(alpha: 0.3 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const points = 80;
    final step = size.width / points;

    for (int i = 0; i <= points; i++) {
      final x = i * step;
      final normX = x / size.width;

      // Bell envelope (tapered at ends)
      final envelope = math.sin(normX * math.pi);

      // Wave 1
      final y1 =
          centerY +
          math.sin(normX * 4 * math.pi + phase) * 28.0 * envelope +
          math.cos(normX * 2 * math.pi - phase * 0.5) * 12.0 * envelope;

      // Wave 2
      final y2 =
          centerY +
          math.cos(normX * 3 * math.pi - phase * 0.7) * 20.0 * envelope -
          math.sin(normX * 6 * math.pi + phase) * 8.0 * envelope;

      // Wave 3
      final y3 =
          centerY +
          math.sin(normX * 8 * math.pi + phase * 1.3) * 14.0 * envelope;

      if (i == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
        path3.moveTo(x, y3);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
        path3.lineTo(x, y3);
      }
    }

    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
    canvas.drawPath(path1, paint1);
  }

  @override
  bool shouldRepaint(covariant _AcousticSignalPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isDark != isDark ||
        oldDelegate.opacity != opacity;
  }
}
