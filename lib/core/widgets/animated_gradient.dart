import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A softly, slowly shifting gradient backdrop. The colors drift between the
/// provided stops on a long loop, so every screen breathes gently without ever
/// being distracting.
class AnimatedGradient extends StatefulWidget {
  final List<List<Color>> palettes;
  final Duration period;
  final Widget? child;

  const AnimatedGradient({
    super.key,
    required this.palettes,
    this.period = const Duration(seconds: 12),
    this.child,
  });

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

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
        final n = widget.palettes.length;
        final pos = _c.value * n;
        final i = pos.floor() % n;
        final j = (i + 1) % n;
        final t = pos - pos.floor();
        final a = widget.palettes[i];
        final b = widget.palettes[j];
        final colors = <Color>[
          for (var k = 0; k < a.length; k++)
            Color.lerp(a[k], b[k % b.length], Curves.easeInOut.transform(t))!,
        ];
        // A gentle rotation of the gradient axis for extra life.
        final angle = math.sin(_c.value * 2 * math.pi) * 0.25;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-math.cos(angle), -1),
              end: Alignment(math.cos(angle), 1),
              colors: colors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
