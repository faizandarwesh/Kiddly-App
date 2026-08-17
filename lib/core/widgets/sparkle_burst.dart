import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A quick little particle burst at a point on screen, for individual taps
/// (a flower opening, a balloon popping, a letter revealing). Small and fast so
/// interaction stays snappy (~tap → reaction under 200ms).
class SparkleBurst {
  SparkleBurst._();

  static void at(
    BuildContext context,
    Offset globalPosition, {
    Color color = Colors.amber,
    int count = 10,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Burst(
        origin: globalPosition,
        color: color,
        count: count,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _Burst extends StatefulWidget {
  final Offset origin;
  final Color color;
  final int count;
  final VoidCallback onDone;
  const _Burst({
    required this.origin,
    required this.color,
    required this.count,
    required this.onDone,
  });

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _sparks = List.generate(widget.count, (i) {
      final angle = (i / widget.count) * 2 * math.pi + rng.nextDouble();
      final dist = 40 + rng.nextDouble() * 60;
      return _Spark(
        angle: angle,
        distance: dist,
        size: 8 + rng.nextDouble() * 10,
      );
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _BurstPainter(
              _sparks, _c.value, widget.origin, widget.color),
        ),
      ),
    );
  }
}

class _Spark {
  final double angle, distance, size;
  _Spark({required this.angle, required this.distance, required this.size});
}

class _BurstPainter extends CustomPainter {
  final List<_Spark> sparks;
  final double t;
  final Offset origin;
  final Color color;
  _BurstPainter(this.sparks, this.t, this.origin, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOut.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withValues(alpha: fade);
    for (final s in sparks) {
      final r = s.distance * eased;
      final p = origin + Offset(math.cos(s.angle) * r, math.sin(s.angle) * r);
      canvas.drawCircle(p, s.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
