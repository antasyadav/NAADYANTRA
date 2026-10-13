import 'package:flutter/material.dart';

/// Centralized Motion & Animation Tokens for NAADYANTRA
///
/// Ensures cinematic consistency across transitions, micro-interactions,
/// background loops, and entrance choreographies while strictly adhering
/// to accessibility and reduced-motion standards.
class MotionTokens {
  MotionTokens._();

  // Durations
  static const Duration durationInstant = Duration(milliseconds: 120);
  static const Duration durationFast = Duration(milliseconds: 240);
  static const Duration durationMedium = Duration(milliseconds: 420);
  static const Duration durationSlow = Duration(milliseconds: 720);
  static const Duration durationSweep = Duration(milliseconds: 3200);
  static const Duration durationWave = Duration(milliseconds: 5500);
  static const Duration durationAmbient = Duration(milliseconds: 8000);

  // Easing Curves
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveAccelerate = Curves.easeInCubic;
  static const Curve curveSnappy = Curves.easeOutQuart;
  static const Curve curveTactile = Curves.easeOutBack;

  /// Determines if the user has requested reduced motion at system level.
  static bool isReducedMotion(BuildContext context) {
    try {
      return MediaQuery.disableAnimationsOf(context);
    } catch (_) {
      return false;
    }
  }

  /// Calculates staggered delay based on list item index with an upper cap.
  static Duration staggerDelay(
    int index, {
    int stepMs = 50,
    int maxDelayMs = 400,
  }) {
    final ms = (index * stepMs).clamp(0, maxDelayMs);
    return Duration(milliseconds: ms);
  }
}
