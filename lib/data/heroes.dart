import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The chest emblem style for a hero.
enum Emblem { star, web, smash, arc }

/// A puzzle character. Every hero is now backed by real artwork in
/// `assets/images/heroes/`; [imageAsset] is what the puzzle actually shows.
/// [accent] / [bg1] / [bg2] tint the screen, the slot highlight and the
/// sparkle burst so the whole screen matches the picture.
///
/// The [suit] / [cape] / [skin] / [emblem] fields only feed the legacy
/// procedural [HeroPainter], which is no longer used — they keep sensible
/// defaults so new heroes only need a name, a picture and three colors.
class SuperHero {
  final String name;
  final Color accent;
  final Color bg1;
  final Color bg2;

  /// Bundled artwork for this hero, e.g.
  /// 'assets/images/heroes/spiderman.jpeg'.
  final String imageAsset;

  /// Vertical crop bias for the square board, -1 (top) .. 1 (bottom).
  /// The art is portrait, so the square board can only show a slice of it —
  /// this keeps the faces in frame instead of centre-cropping them away.
  final double alignY;

  // --- Legacy [HeroPainter] styling (unused). ---
  final Color suit;
  final Color cape;
  final Color skin;
  final Emblem emblem;
  final bool helmet; // full-face helmet (robot hero)
  final bool angry; // big grin + brows (smash hero)

  const SuperHero({
    required this.name,
    required this.imageAsset,
    required this.accent,
    required this.bg1,
    required this.bg2,
    this.alignY = -0.3,
    this.suit = const Color(0xFF2E6BE6),
    this.cape = const Color(0xFFE23B3B),
    this.skin = const Color(0xFFFFD3B0),
    this.emblem = Emblem.star,
    this.helmet = false,
    this.angry = false,
  });
}

class Heroes {
  Heroes._();

  /// Every hero the puzzle deals, in order. The gentle, simple cartoons come
  /// first because that is what a 2-year-old meets on their first run; the
  /// busier, more detailed super-hero art sits further down the list.
  /// Keep every picture brightly lit — dark art turns into unreadable black
  /// squares once it is cut up and sitting in the tray.
  ///
  /// The old procedurally-painted heroes (Captain Star, Web Kid, Big Green,
  /// Iron Bot) were dropped along with [HeroPainter] — real artwork reads far
  /// better once it is cut into jigsaw pieces.
  static const List<SuperHero> list = [
    SuperHero(
      name: 'Baby JJ',
      imageAsset: 'assets/images/heroes/melon_child.jpeg',
      accent: Color(0xFF2BB3A3),
      bg1: Color(0xFF7ECBF2),
      bg2: Color(0xFFD9F2C8),
      alignY: 0.15,
    ),
    SuperHero(
      name: 'CoComelon',
      imageAsset: 'assets/images/heroes/cocomelon.jpeg',
      accent: Color(0xFF1E9BD8),
      bg1: Color(0xFF6EC6F2),
      bg2: Color(0xFFCFEFB8),
      alignY: 0.7,
    ),
    SuperHero(
      name: 'Motu Patlu',
      imageAsset: 'assets/images/heroes/motu_patlu_tow.jpeg',
      accent: Color(0xFFE2452F),
      bg1: Color(0xFF6FB7F0),
      bg2: Color(0xFFCFE8FB),
      alignY: 0.25,
    ),
    SuperHero(
      name: 'Talking Tom',
      imageAsset: 'assets/images/heroes/tom.jpeg',
      accent: Color(0xFF3FAE5A),
      bg1: Color(0xFFC9A88A),
      bg2: Color(0xFFF0E3D2),
      alignY: -0.75,
    ),
    SuperHero(
      name: 'Tom & Jerry',
      imageAsset: 'assets/images/heroes/tom_and_jerry.jpeg',
      accent: Color(0xFFE8A33D),
      bg1: Color(0xFF7E8A9B),
      bg2: Color(0xFFDCE2EA),
      alignY: 0.25,
    ),
    SuperHero(
      name: 'Motu & Patlu',
      imageAsset: 'assets/images/heroes/motu_patlu.jpeg',
      accent: Color(0xFFE0B32E),
      bg1: Color(0xFF7CC0EA),
      bg2: Color(0xFFDCEBF7),
      alignY: 0.15,
    ),
    SuperHero(
      name: 'Superman',
      imageAsset: 'assets/images/heroes/superman.jpeg',
      accent: Color(0xFFE23B3B),
      bg1: Color(0xFF5EA9FF),
      bg2: Color(0xFFBFE3FF),
      alignY: -0.85,
    ),
    SuperHero(
      name: 'Spider-Man',
      imageAsset: 'assets/images/heroes/spiderman.jpeg',
      accent: Color(0xFFE23B4E),
      bg1: Color(0xFFFFA579),
      bg2: Color(0xFFFFE3C9),
      alignY: -0.7,
    ),
    SuperHero(
      name: 'Hulk',
      imageAsset: 'assets/images/heroes/hulk.jpeg',
      accent: Color(0xFF3E8E2E),
      bg1: Color(0xFFAEE87F),
      bg2: Color(0xFFDDF3C0),
      alignY: -0.8,
    ),
    SuperHero(
      name: 'Iron Man',
      imageAsset: 'assets/images/heroes/iron_man.jpeg',
      accent: Color(0xFFD32F2F),
      bg1: Color(0xFFFFC98F),
      bg2: Color(0xFFFFE9CC),
      alignY: -0.9,
    ),
    SuperHero(
      name: 'Batman',
      imageAsset: 'assets/images/heroes/batman.jpeg',
      accent: Color(0xFFFFD23F),
      bg1: Color(0xFF7E97C4),
      bg2: Color(0xFFCFDCEF),
      alignY: -0.85,
    ),
  ];
}

/// A hero picture that fills a square canvas. The puzzle clips it into jigsaw
/// pieces, so any implementation is interchangeable.
abstract class HeroScene {
  SuperHero get hero;
  void paint(Canvas canvas, Size size);
}

/// A [HeroScene] backed by a bundled image, drawn cover-fit into the square.
class ImageHeroScene implements HeroScene {
  @override
  final SuperHero hero;
  final ui.Image image;
  const ImageHeroScene(this.hero, this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = hero.bg2);
    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      fit: BoxFit.cover,
      // Portrait hero art is taller than the square board, so the crop is
      // biased per hero to keep the faces in frame.
      alignment: Alignment(0, hero.alignY),
      filterQuality: FilterQuality.medium,
    );
  }
}

/// The soft gradient shown for the split-second before a hero's picture has
/// decoded, so the board is never blank and never flashes a wrong drawing.
class HeroBackdropScene implements HeroScene {
  @override
  final SuperHero hero;
  const HeroBackdropScene(this.hero);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 1.15,
          colors: [hero.bg1, hero.bg2],
        ).createShader(rect),
    );
  }
}

/// Paints a cute, chibi super-hero scene filling the given size.
///
/// UNUSED — kept for reference only. The puzzle now uses the real artwork in
/// `assets/images/heroes/` via [ImageHeroScene]; nothing constructs this
/// painter any more.
class HeroPainter extends CustomPainter implements HeroScene {
  @override
  final SuperHero hero;
  const HeroPainter(this.hero);

  @override
  void paint(Canvas canvas, Size size) {
    _background(canvas, size);
    _character(canvas, size);
  }

  void _background(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 1.15,
          colors: [hero.bg1, hero.bg2],
        ).createShader(rect),
    );

    // Comic sun-burst rays from behind the hero.
    final c = Offset(size.width / 2, size.height * 0.42);
    final ray = Paint()..color = Colors.white.withValues(alpha: 0.14);
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a = (i / n) * 2 * math.pi;
      final a2 = a + math.pi / n;
      final len = size.longestSide;
      final p = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a) * len, c.dy + math.sin(a) * len)
        ..lineTo(c.dx + math.cos(a2) * len, c.dy + math.sin(a2) * len)
        ..close();
      if (i.isEven) canvas.drawPath(p, ray);
    }

    // Simple city skyline silhouette at the bottom.
    final sky = Paint()..color = Colors.black.withValues(alpha: 0.10);
    final base = size.height * 0.86;
    final bw = size.width / 7;
    for (var i = 0; i < 7; i++) {
      final bh = size.height * (0.10 + 0.09 * ((i * 37) % 5) / 4);
      canvas.drawRect(
        Rect.fromLTWH(i * bw, base - bh, bw * 0.82, bh + size.height),
        sky,
      );
    }
  }

  void _character(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final suit = Paint()..color = hero.suit;
    final accent = Paint()..color = hero.accent;

    // Cape behind the body.
    final cape = Path()
      ..moveTo(cx - 0.15 * w, 0.40 * h)
      ..quadraticBezierTo(cx - 0.34 * w, 0.74 * h, cx - 0.12 * w, 0.88 * h)
      ..quadraticBezierTo(cx, 0.82 * h, cx + 0.12 * w, 0.88 * h)
      ..quadraticBezierTo(cx + 0.34 * w, 0.74 * h, cx + 0.15 * w, 0.40 * h)
      ..close();
    canvas.drawPath(cape, Paint()..color = hero.cape);
    canvas.drawPath(
      cape,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.01,
    );

    // Legs + boots.
    final legY = 0.70 * h;
    for (final s in [-1, 1]) {
      final lx = cx + s * 0.09 * w;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(lx, legY + 0.09 * h),
              width: 0.11 * w,
              height: 0.22 * h),
          Radius.circular(0.03 * w),
        ),
        suit,
      );
      // Boot.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(lx, legY + 0.19 * h),
              width: 0.13 * w,
              height: 0.07 * h),
          Radius.circular(0.02 * w),
        ),
        accent,
      );
    }

    // Torso.
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, 0.56 * h), width: 0.34 * w, height: 0.32 * h),
      Radius.circular(0.09 * w),
    );
    canvas.drawRRect(torso, suit);

    // Arms — right fist raised heroically.
    final armPaint = suit;
    // Left arm (down).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx - 0.20 * w, 0.58 * h),
            width: 0.10 * w,
            height: 0.24 * h),
        Radius.circular(0.05 * w),
      ),
      armPaint,
    );
    _fist(canvas, Offset(cx - 0.20 * w, 0.70 * h), w * 0.06);
    // Right arm (raised).
    canvas.save();
    canvas.translate(cx + 0.18 * w, 0.50 * h);
    canvas.rotate(-0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset.zero, width: 0.10 * w, height: 0.24 * h),
        Radius.circular(0.05 * w),
      ),
      armPaint,
    );
    canvas.restore();
    _fist(canvas, Offset(cx + 0.30 * w, 0.36 * h), w * 0.065);

    // Belt.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, 0.68 * h), width: 0.34 * w, height: 0.05 * h),
        Radius.circular(0.02 * w),
      ),
      accent,
    );

    // Chest emblem.
    _emblem(canvas, Offset(cx, 0.53 * h), w * 0.09);

    // Head.
    final headC = Offset(cx, 0.32 * h);
    final headR = 0.15 * w;
    if (hero.helmet) {
      _helmet(canvas, headC, headR);
    } else {
      _face(canvas, headC, headR);
    }
  }

  void _fist(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = hero.skin);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.2,
    );
  }

  void _emblem(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    canvas.drawCircle(
        c, r, Paint()..color = hero.accent.withValues(alpha: 0.25));
    switch (hero.emblem) {
      case Emblem.star:
        _star(canvas, c, r * 0.8, r * 0.34, hero.suit);
        break;
      case Emblem.arc:
        canvas.drawCircle(c, r * 0.7, Paint()..color = hero.accent);
        canvas.drawCircle(c, r * 0.4, Paint()..color = Colors.white);
        break;
      case Emblem.web:
        final p = Paint()
          ..color = hero.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12;
        for (var i = 0; i < 6; i++) {
          final a = i / 6 * 2 * math.pi;
          canvas.drawLine(
              c, c + Offset(math.cos(a), math.sin(a)) * r * 0.8, p);
        }
        for (var k = 1; k <= 2; k++) {
          canvas.drawCircle(
              c, r * 0.35 * k, p..style = PaintingStyle.stroke);
        }
        break;
      case Emblem.smash:
        _star(canvas, c, r * 0.8, r * 0.3, hero.suit); // burst-ish
        break;
    }
  }

  void _face(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = hero.skin);

    // Eye mask.
    final mask = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy - r * 0.15),
            width: r * 2.0,
            height: r * 0.9),
        Radius.circular(r * 0.4),
      ));
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawPath(mask, Paint()..color = hero.suit);
    canvas.restore();

    // Eyes (white with pupils, or big white lenses for web hero).
    final eyeDx = r * 0.42;
    final eyeY = c.dy - r * 0.12;
    if (hero.emblem == Emblem.web) {
      for (final s in [-1, 1]) {
        final e = Offset(c.dx + s * eyeDx, eyeY);
        final lens = Path()
          ..moveTo(e.dx - r * 0.28, e.dy)
          ..quadraticBezierTo(e.dx, e.dy - r * 0.34, e.dx + r * 0.34, e.dy - r * 0.05)
          ..quadraticBezierTo(e.dx + r * 0.1, e.dy + r * 0.28, e.dx - r * 0.28, e.dy)
          ..close();
        canvas.drawPath(lens, Paint()..color = Colors.white);
        canvas.drawPath(
            lens,
            Paint()
              ..color = hero.accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.06);
      }
    } else {
      for (final s in [-1, 1]) {
        final e = Offset(c.dx + s * eyeDx, eyeY);
        canvas.drawCircle(e, r * 0.16, Paint()..color = Colors.white);
        canvas.drawCircle(
            e, r * 0.09, Paint()..color = const Color(0xFF2E2A44));
      }
      if (hero.angry) {
        final brow = Paint()
          ..color = const Color(0xFF2E2A44)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.09
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(c.dx - eyeDx - r * 0.16, eyeY - r * 0.3),
            Offset(c.dx - eyeDx + r * 0.16, eyeY - r * 0.18), brow);
        canvas.drawLine(Offset(c.dx + eyeDx + r * 0.16, eyeY - r * 0.3),
            Offset(c.dx + eyeDx - r * 0.16, eyeY - r * 0.18), brow);
      }
    }

    // Mouth.
    final my = c.dy + r * 0.42;
    final mouth = Paint()
      ..color = const Color(0xFF2E2A44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(c.dx - r * 0.3, my)
      ..quadraticBezierTo(c.dx, my + r * (hero.angry ? 0.12 : 0.34),
          c.dx + r * 0.3, my);
    canvas.drawPath(path, mouth);
  }

  void _helmet(Canvas canvas, Offset c, double r) {
    // Metallic head.
    canvas.drawCircle(c, r, Paint()..color = hero.skin);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.5), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Faceplate.
    final plate = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.15),
          width: r * 1.3,
          height: r * 1.1),
      Radius.circular(r * 0.4),
    );
    canvas.drawRRect(plate, Paint()..color = hero.suit.withValues(alpha: 0.9));
    // Glowing eyes.
    final glow = Paint()..color = hero.accent;
    for (final s in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(c.dx + s * r * 0.4, c.dy - r * 0.05),
              width: r * 0.4,
              height: r * 0.18),
          Radius.circular(r * 0.09),
        ),
        glow,
      );
    }
  }

  void _star(Canvas canvas, Offset c, double outer, double inner, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant HeroPainter old) => old.hero != hero;
}
