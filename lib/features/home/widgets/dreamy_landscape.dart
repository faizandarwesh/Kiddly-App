import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/floaty.dart';

/// The premium storybook backdrop for the home dashboard: a soft blue sky with
/// drifting clouds and twinkling sparkles, rolling green hills, a peeking sun,
/// toadstools and cute smiling flowers. Entirely painted / emoji — no assets.
class DreamyLandscape extends StatefulWidget {
  const DreamyLandscape({super.key});

  @override
  State<DreamyLandscape> createState() => _DreamyLandscapeState();
}

class _DreamyLandscapeState extends State<DreamyLandscape>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return Stack(
          children: [
            // Sky, clouds, sparkles, hills.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _ScenePainter(_c.value),
                ),
              ),
            ),
            // Peeking sun, top-right.
            Positioned(
              right: -18,
              top: h * 0.05,
              child: const Floaty(
                style: FloatyStyle.pulse,
                period: Duration(seconds: 5),
                child: Text('☀️', style: TextStyle(fontSize: 120)),
              ),
            ),
            // Toadstools on the hills.
            Positioned(
                left: w * 0.02,
                top: h * 0.60,
                child: const Text('🍄', style: TextStyle(fontSize: 46))),
            Positioned(
                right: w * 0.10,
                top: h * 0.66,
                child: const Text('🍄', style: TextStyle(fontSize: 60))),
            Positioned(
                left: w * 0.16,
                top: h * 0.80,
                child: const Text('🍄', style: TextStyle(fontSize: 34))),
            // Smiling flowers along the bottom.
            Positioned(
                left: -14,
                bottom: -10,
                child: Floaty(
                  style: FloatyStyle.sway,
                  period: const Duration(seconds: 6),
                  child: const _Flower(
                      color: Color(0xFFFFA23D), size: 120),
                )),
            Positioned(
                left: w * 0.30,
                bottom: -34,
                child: Floaty(
                  style: FloatyStyle.sway,
                  period: const Duration(seconds: 7),
                  delay: const Duration(milliseconds: 500),
                  child: const _Flower(
                      color: Color(0xFFB07CF0), size: 96),
                )),
            Positioned(
                right: -20,
                bottom: -6,
                child: Floaty(
                  style: FloatyStyle.sway,
                  period: const Duration(seconds: 6),
                  delay: const Duration(milliseconds: 900),
                  child: const _Flower(
                      color: Color(0xFFFF8FC7), size: 132),
                )),
          ],
        );
      },
    );
  }
}

class _ScenePainter extends CustomPainter {
  final double t;
  _ScenePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Sky.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9BD4F5), Color(0xFFBFE6FB), Color(0xFFDDF3EA)],
          stops: [0.0, 0.45, 0.7],
        ).createShader(rect),
    );

    // Drifting clouds.
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final cloudSoft = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final drift = t * w * 0.04;
    void puff(double cx, double cy, double s, Paint p) {
      final x = ((cx + drift) % (w + 200)) - 100;
      canvas.drawCircle(Offset(x, cy), s, p);
      canvas.drawCircle(Offset(x + s * 0.9, cy + s * 0.15), s * 0.8, p);
      canvas.drawCircle(Offset(x - s * 0.9, cy + s * 0.2), s * 0.7, p);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, cy + s * 0.5),
              width: s * 3.4,
              height: s * 1.2),
          p);
    }

    puff(w * 0.18, h * 0.10, 26, cloud);
    puff(w * 0.72, h * 0.16, 30, cloud);
    puff(w * 0.45, h * 0.24, 20, cloudSoft);
    puff(w * 0.88, h * 0.30, 22, cloudSoft);
    puff(w * 0.10, h * 0.34, 18, cloudSoft);

    // Twinkling sparkles.
    _sparkles(canvas, size);

    // Hills (two soft layers).
    final backHill = Paint()..color = const Color(0xFFAEE06A);
    final backPath = Path()
      ..moveTo(0, h * 0.66)
      ..quadraticBezierTo(w * 0.28, h * 0.56, w * 0.58, h * 0.64)
      ..quadraticBezierTo(w * 0.84, h * 0.71, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, backHill);

    final frontHill = Paint()..color = const Color(0xFF88CF52);
    final frontPath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.24, h * 0.70, w * 0.52, h * 0.79)
      ..quadraticBezierTo(w * 0.80, h * 0.88, w, h * 0.78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontPath, frontHill);
    // Soft highlight rim on the front hill.
    canvas.drawPath(
      frontPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
  }

  void _sparkles(Canvas canvas, Size size) {
    const specs = [
      [0.22, 0.08],
      [0.5, 0.05],
      [0.63, 0.12],
      [0.35, 0.18],
      [0.8, 0.09],
      [0.14, 0.2],
      [0.9, 0.22],
      [0.46, 0.32],
      [0.7, 0.4],
      [0.2, 0.44],
      [0.85, 0.5],
      [0.32, 0.52],
    ];
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      final phase = (t + i / specs.length) % 1.0;
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
      final c = Offset(s[0] * size.width, s[1] * size.height);
      final r = (2.0 + (i % 3)) * tw;
      _star4(canvas, c, r + 3,
          Paint()..color = Colors.white.withValues(alpha: 0.9 * tw));
    }
  }

  void _star4(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isEven ? r : r * 0.34;
      final a = -math.pi / 2 + i * math.pi / 4;
      final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.t != t;
}

/// A cute smiling flower drawn with a [CustomPainter].
class _Flower extends StatelessWidget {
  final Color color;
  final double size;
  const _Flower({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FlowerPainter(color)),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  final Color color;
  _FlowerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final petalR = size.width * 0.20;
    final ring = size.width * 0.26;
    final petal = Paint()..color = color;

    // Stem.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(c.dx, size.height * 0.9),
            width: size.width * 0.06,
            height: size.height * 0.4),
        Radius.circular(size.width * 0.03),
      ),
      Paint()..color = const Color(0xFF5EB82E),
    );

    // Petals.
    for (var i = 0; i < 6; i++) {
      final a = i / 6 * 2 * math.pi;
      canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * ring, petalR, petal);
    }
    // Face center.
    canvas.drawCircle(c, size.width * 0.24, Paint()..color = const Color(0xFFFFE7A0));

    // Eyes.
    final eye = Paint()..color = const Color(0xFF3A2E5C);
    canvas.drawCircle(c + Offset(-size.width * 0.08, -size.width * 0.02),
        size.width * 0.028, eye);
    canvas.drawCircle(c + Offset(size.width * 0.08, -size.width * 0.02),
        size.width * 0.028, eye);
    // Blush.
    final blush = Paint()..color = const Color(0xFFFF8FA8).withValues(alpha: 0.6);
    canvas.drawCircle(c + Offset(-size.width * 0.13, size.width * 0.04),
        size.width * 0.035, blush);
    canvas.drawCircle(c + Offset(size.width * 0.13, size.width * 0.04),
        size.width * 0.035, blush);
    // Smile.
    final smile = Path()
      ..moveTo(c.dx - size.width * 0.06, c.dy + size.width * 0.06)
      ..quadraticBezierTo(c.dx, c.dy + size.width * 0.13,
          c.dx + size.width * 0.06, c.dy + size.width * 0.06);
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF3A2E5C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.02
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter old) => old.color != color;
}
