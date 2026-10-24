import 'package:flutter/material.dart';

/// Lightweight tactile feedback for interactive ScoreX cards and buttons.
/// Wrap a tappable widget with ScoreXPressAnimation(onTap: ..., child: ...).
class ScoreXPressAnimation extends StatefulWidget {
  const ScoreXPressAnimation({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<ScoreXPressAnimation> createState() => _ScoreXPressAnimationState();
}

class _ScoreXPressAnimationState extends State<ScoreXPressAnimation> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: reduceMotion || !_pressed ? 1.0 : 0.965,
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
