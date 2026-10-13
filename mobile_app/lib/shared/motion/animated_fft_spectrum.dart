import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/motion_tokens.dart';

/// Animated 16-Band Ultrasonic FFT Spectrum Analyzer
/// Simulates live discrete frequency bands from 12 kHz to 48 kHz
class AnimatedFftSpectrum extends StatefulWidget {
  final bool isAnomalous;
  final double height;

  const AnimatedFftSpectrum({
    super.key,
    this.isAnomalous = false,
    this.height = 42.0,
  });

  @override
  State<AnimatedFftSpectrum> createState() => _AnimatedFftSpectrumState();
}

class _AnimatedFftSpectrumState extends State<AnimatedFftSpectrum>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random(42);
  late List<double> _baseHeights;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _baseHeights = List.generate(16, (i) {
      if (i >= 8 && i <= 13) {
        return 0.35 + _random.nextDouble() * 0.3; // ultrasound window
      }
      return 0.15 + _random.nextDouble() * 0.25;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = MotionTokens.isReducedMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            height: widget.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(16, (index) {
                final isLeakBand = index >= 8 && index <= 13;
                double factor = _baseHeights[index];

                if (!isReduced) {
                  final wobble = math.sin(_controller.value * math.pi * 2 + index * 0.5) * 0.18;
                  factor = (factor + wobble).clamp(0.08, 1.0);
                  if (widget.isAnomalous && isLeakBand) {
                    factor = (factor * 1.6 + 0.2).clamp(0.3, 1.0);
                  }
                }

                Color barColor;
                if (widget.isAnomalous && isLeakBand) {
                  barColor = AppColors.darkBurntOrange;
                } else if (isLeakBand) {
                  barColor = AppColors.burntOrange;
                } else {
                  barColor = isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                      : AppColors.warmStone;
                }

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    height: widget.height * factor,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      boxShadow: (widget.isAnomalous && isLeakBand)
                          ? [
                              BoxShadow(
                                color: AppColors.burntOrange.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, -1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
