import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ShapeKind { circle, square, triangle, rectangle, star, heart, oval }

/// A learnable shape plus the real-world object it can magically become.
class ShapeInfo {
  final ShapeKind kind;
  final String name;
  final String becomesEmoji;
  final String becomesName;
  final Color color;
  const ShapeInfo({
    required this.kind,
    required this.name,
    required this.becomesEmoji,
    required this.becomesName,
    required this.color,
  });
}

class Shapes {
  Shapes._();

  static const List<ShapeInfo> all = [
    ShapeInfo(kind: ShapeKind.circle, name: 'Circle', becomesEmoji: '🏀', becomesName: 'Ball', color: Color(0xFFFF9A3D)),
    ShapeInfo(kind: ShapeKind.square, name: 'Square', becomesEmoji: '📦', becomesName: 'Box', color: Color(0xFF3E8EF7)),
    ShapeInfo(kind: ShapeKind.triangle, name: 'Triangle', becomesEmoji: '⛰️', becomesName: 'Mountain', color: Color(0xFF56C860)),
    ShapeInfo(kind: ShapeKind.rectangle, name: 'Rectangle', becomesEmoji: '🚪', becomesName: 'Door', color: Color(0xFFA163E0)),
    ShapeInfo(kind: ShapeKind.star, name: 'Star', becomesEmoji: '⭐', becomesName: 'Star', color: Color(0xFFFFD23F)),
    ShapeInfo(kind: ShapeKind.heart, name: 'Heart', becomesEmoji: '❤️', becomesName: 'Heart', color: Color(0xFFF14B4B)),
    ShapeInfo(kind: ShapeKind.oval, name: 'Oval', becomesEmoji: '🥚', becomesName: 'Egg', color: Color(0xFFFF8FC7)),
  ];
}

/// Paints any [ShapeKind] centered in its box, filled with [color].
///
/// When [glossy] is set, the shape gets a candy-like diagonal gradient plus a
/// soft top highlight — used for the star hero on the Shapes screen. The plain
/// flat fill (glossy off) is used by the puzzle sorter.
class ShapePainter extends CustomPainter {
  final ShapeKind kind;
  final Color color;
  final bool glossy;
  ShapePainter(this.kind, this.color, {this.glossy = false});

  /// Builds the outline path for a shape centered at [c] with radius [r].
  static Path buildPath(ShapeKind kind, Offset c, double r) {
    switch (kind) {
      case ShapeKind.circle:
        return Path()..addOval(Rect.fromCircle(center: c, radius: r));
      case ShapeKind.oval:
        return Path()
          ..addOval(
              Rect.fromCenter(center: c, width: r * 1.5, height: r * 2.1));
      case ShapeKind.square:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: r * 1.8, height: r * 1.8),
              Radius.circular(r * 0.18)));
      case ShapeKind.rectangle:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: r * 2.4, height: r * 1.5),
              Radius.circular(r * 0.16)));
      case ShapeKind.triangle:
        return Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.95, c.dy + r * 0.8)
          ..lineTo(c.dx - r * 0.95, c.dy + r * 0.8)
          ..close();
      case ShapeKind.star:
        return _starPath(c, r, r * 0.45, 5);
      case ShapeKind.heart:
        return _heartPath(c, r * 1.9);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.42;
    final path = buildPath(kind, c, r);
    final bounds = path.getBounds();

    final fill = Paint();
    if (glossy) {
      fill.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.34)!,
          color,
          Color.lerp(color, Colors.black, 0.14)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bounds);
    } else {
      fill.color = color;
    }
    canvas.drawPath(path, fill);

    if (glossy) {
      // Soft glassy highlight in the upper portion, clipped to the shape.
      canvas.save();
      canvas.clipPath(path);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx, bounds.top + bounds.height * 0.26),
          width: bounds.width * 0.72,
          height: bounds.height * 0.30,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.32),
      );
      canvas.restore();
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.055
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static Path _starPath(Offset c, double outer, double inner, int points) {
    final path = Path();
    final step = math.pi / points;
    for (var i = 0; i < points * 2; i++) {
      final rr = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * step;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path _heartPath(Offset c, double size) {
    final w = size, h = size;
    final path = Path();
    final top = c.dy - h * 0.28;
    path.moveTo(c.dx, c.dy + h * 0.35);
    path.cubicTo(c.dx - w * 0.6, c.dy - h * 0.1, c.dx - w * 0.5, top,
        c.dx, c.dy - h * 0.05);
    path.cubicTo(c.dx + w * 0.5, top, c.dx + w * 0.6, c.dy - h * 0.1,
        c.dx, c.dy + h * 0.35);
    return path..close();
  }

  @override
  bool shouldRepaint(covariant ShapePainter old) =>
      old.kind != kind || old.color != color || old.glossy != glossy;
}
