import 'package:flutter/material.dart';

/// Plays a one-shot "pop in" when the widget first mounts: fade + scale +
/// a small upward slide, after an optional [delay]. Give grid children an
/// increasing delay to get a delightful staggered cascade.
class Entrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slide;
  final Curve curve;

  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.slide = 24,
    this.curve = Curves.easeOutBack,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: widget.curve);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final v = curved.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.slide),
            child: Transform.scale(scale: 0.6 + 0.4 * v, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
