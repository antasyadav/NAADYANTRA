import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/motion_tokens.dart';

/// Pulsing Beacon for Live Sensor and Hardware Status
///
/// Draws concentric radial wave rings expanding and fading out around a
/// glowing center dot. Fully wrapped in a RepaintBoundary to avoid canvas invalidations.
class PulsingBeacon extends StatefulWidget {
  final Color color;
  final double size;
  final bool isLive;

  const PulsingBeacon({
    super.key,
    this.color = AppColors.alertOk,
    this.size = 18.0,
    this.isLive = true,
  });

  @override
  State<PulsingBeacon> createState() => _PulsingBeaconState();
}

class _PulsingBeaconState extends State<PulsingBeacon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.durationSweep,
    );

    if (widget.isLive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulsingBeacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive != oldWidget.isLive) {
      if (widget.isLive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
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
    if (MotionTokens.isReducedMotion(context) || !widget.isLive) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size * 2.2, widget.size * 2.2),
            painter: _BeaconPainter(
              progress: _controller.value,
              color: widget.color,
              dotRadius: widget.size * 0.35,
            ),
          );
        },
      ),
    );
  }
}

class _BeaconPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double dotRadius;

  _BeaconPainter({
    required this.progress,
    required this.color,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Outer ring 1
    final r1 = dotRadius + (maxRadius - dotRadius) * progress;
    final alpha1 = (1.0 - progress).clamp(0.0, 1.0) * 0.45;
    final paint1 = Paint()
      ..color = color.withValues(alpha: alpha1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, r1, paint1);

    // Outer ring 2 (phase shifted by 0.5)
    final p2 = (progress + 0.5) % 1.0;
    final r2 = dotRadius + (maxRadius - dotRadius) * p2;
    final alpha2 = (1.0 - p2).clamp(0.0, 1.0) * 0.35;
    final paint2 = Paint()
      ..color = color.withValues(alpha: alpha2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, r2, paint2);

    // Solid core dot
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, dotRadius, corePaint);

    // Subtle inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, dotRadius * 0.4, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _BeaconPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
