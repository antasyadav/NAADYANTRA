import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/motion_tokens.dart';

/// Diagnostic Radar Sweep
///
/// Draws a precision concentric circular radar display with a 360-degree
/// sweeping beam and phosphorescent phosphor decay trail.
class DiagnosticRadarSweep extends StatefulWidget {
  final double size;
  final bool isScanning;
  final Widget? centerWidget;

  const DiagnosticRadarSweep({
    super.key,
    this.size = 200.0,
    this.isScanning = true,
    this.centerWidget,
  });

  @override
  State<DiagnosticRadarSweep> createState() => _DiagnosticRadarSweepState();
}

class _DiagnosticRadarSweepState extends State<DiagnosticRadarSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.durationSweep,
    );

    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant DiagnosticRadarSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RadarSweepPainter(
              angle: isReduced || !widget.isScanning
                  ? math.pi * 0.25
                  : _controller.value * 2 * math.pi,
              isDark: isDark,
              isScanning: widget.isScanning && !isReduced,
            ),
          ),
          if (widget.centerWidget != null) widget.centerWidget!,
        ],
      ),
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  final double angle;
  final bool isDark;
  final bool isScanning;

  _RadarSweepPainter({
    required this.angle,
    required this.isDark,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final gridColor = isDark
        ? const Color(0xFF3A3A3A)
        : AppColors.warmStone.withValues(alpha: 0.8);

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Concentric range rings
    canvas.drawCircle(center, radius * 0.33, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);
    canvas.drawCircle(center, radius, gridPaint);

    // Crosshairs
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    // Degree ticks
    final tickPaint = Paint()
      ..color = isDark ? AppColors.darkTextSecondary : AppColors.warmGraphite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int deg = 0; deg < 360; deg += 30) {
      final rad = deg * math.pi / 180;
      final p1 = Offset(
        center.dx + (radius - 5) * math.cos(rad),
        center.dy + (radius - 5) * math.sin(rad),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Sweep beam and phosphor trail
    if (isScanning) {
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: math.pi * 0.5,
          colors: [
            AppColors.burntOrange.withValues(alpha: 0.0),
            AppColors.burntOrange.withValues(alpha: 0.22),
          ],
          transform: GradientRotation(angle - math.pi * 0.5),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, sweepPaint);

      // Leading beam line
      final beamPaint = Paint()
        ..color = AppColors.burntOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final beamEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, beamEnd, beamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isScanning != isScanning;
  }
}
