import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kinds of gentle, never-ending idle motion used to make everything on
/// screen feel alive (per the "the home screen should feel alive" brief).
enum FloatyStyle { bob, sway, pulse, wiggle, spin, twinkle }

/// Wraps a child in a looping, low-amplitude animation. Cheap enough to sprinkle
/// across a whole scene. Each instance can be given a [delay] and [period] so a
/// group of them drift out of sync and look organic.
class Floaty extends StatefulWidget {
  final Widget child;
  final FloatyStyle style;
  final Duration period;
  final Duration delay;
  final double amplitude;

  const Floaty({
    super.key,
    required this.child,
    this.style = FloatyStyle.bob,
    this.period = const Duration(seconds: 3),
    this.delay = Duration.zero,
    this.amplitude = 1,
  });

  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value; // 0..1
        final wave = math.sin(t * 2 * math.pi);
        switch (widget.style) {
          case FloatyStyle.bob:
            return Transform.translate(
              offset: Offset(0, wave * 8 * widget.amplitude),
              child: child,
            );
          case FloatyStyle.sway:
            return Transform.translate(
              offset: Offset(wave * 10 * widget.amplitude, 0),
              child: child,
            );
          case FloatyStyle.pulse:
            return Transform.scale(
              scale: 1 + wave * 0.06 * widget.amplitude,
              child: child,
            );
          case FloatyStyle.wiggle:
            return Transform.rotate(
              angle: wave * 0.08 * widget.amplitude,
              child: child,
            );
          case FloatyStyle.spin:
            return Transform.rotate(angle: t * 2 * math.pi, child: child);
          case FloatyStyle.twinkle:
            return Opacity(
              opacity: 0.55 + 0.45 * (0.5 + 0.5 * wave),
              child: Transform.scale(
                scale: 0.9 + 0.2 * (0.5 + 0.5 * wave),
                child: child,
              ),
            );
        }
      },
      child: widget.child,
    );
  }
}
