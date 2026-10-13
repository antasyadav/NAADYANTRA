import 'package:flutter/material.dart';

import '../../core/theme/motion_tokens.dart';

/// Staggered Entrance Animation Wrapper
///
/// Smoothly cascades child elements onto the canvas using subtle vertical
/// translation and alpha fade. Automatically bypasses animation if
/// system reduced-motion is enabled.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? delay;
  final Offset slideOffset;
  final Duration duration;
  final Curve curve;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.slideOffset = const Offset(0.0, 0.08),
    this.duration = MotionTokens.durationMedium,
    this.curve = MotionTokens.curveDecelerate,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    final computedDelay =
        widget.delay ?? MotionTokens.staggerDelay(widget.index);

    if (computedDelay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(computedDelay, () {
        if (!_isDisposed && mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MotionTokens.isReducedMotion(context)) {
      return widget.child;
    }

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(position: _slideAnimation, child: widget.child),
      ),
    );
  }
}
