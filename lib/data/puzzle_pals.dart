import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Where a pal lives. Picks the backdrop painted behind them, so two pals
/// sharing a habitat still feel like different pictures thanks to their own
/// colors and props.
enum Habitat { meadow, farm, jungle, ocean, snow, sky }

/// A puzzle subject.
///
/// Every pal is drawn at runtime from an emoji glyph, gradients and
/// [CustomPainter] shapes — exactly like the rest of Kiddly. Nothing here is a
/// bundled picture, so the app ships no third-party artwork, there is nothing
/// to licence, and adding a pal costs one entry in [Pals.list] rather than a
/// new file in `assets/`.
///
/// Keep every scene brightly lit: once the board is cut into jigsaw pieces, a
/// dark picture turns into a tray of unreadable black squares.
class PuzzlePal {
  /// Shown in the header and spoken on completion, so it reads as a name a
  /// child can repeat — "Ellie the Elephant", not "elephant".
  final String name;

  /// The star of the picture, drawn large and centred.
  final String glyph;

  /// Small props scattered around the subject to give the corner pieces
  /// something recognisable in them. Four is the most that will be placed.
  final List<String> decor;

  final Habitat habitat;

  /// Tints the slot highlight and the sparkle burst when a piece lands.
  final Color accent;

  /// Top and bottom of the backdrop gradient.
  final Color bg1;
  final Color bg2;

  const PuzzlePal({
    required this.name,
    required this.glyph,
    required this.habitat,
    required this.accent,
    required this.bg1,
    required this.bg2,
    this.decor = const [],
  });
}

class Pals {
  Pals._();

  /// Every pal the puzzle deals, in order. The calm, single-subject scenes come
  /// first because that is what a 2-year-old meets on their first run; the
  /// busier ones sit further down the list.
  static const List<PuzzlePal> list = [
    PuzzlePal(
      name: 'Sunny the Duck',
      glyph: '🐥',
      habitat: Habitat.meadow,
      decor: ['🌼', '🌿'],
      accent: Color(0xFFF2A93B),
      bg1: Color(0xFF9FD8F7),
      bg2: Color(0xFFE9F7C9),
    ),
    PuzzlePal(
      name: 'Bella the Butterfly',
      glyph: '🦋',
      habitat: Habitat.meadow,
      decor: ['🌸', '🌷', '🌿'],
      accent: Color(0xFF7E6BD0),
      bg1: Color(0xFFAFE0FA),
      bg2: Color(0xFFF3E7FB),
    ),
    PuzzlePal(
      name: 'Freddie the Frog',
      glyph: '🐸',
      habitat: Habitat.meadow,
      decor: ['🍃', '🌼'],
      accent: Color(0xFF4CA83D),
      bg1: Color(0xFF9BDCF5),
      bg2: Color(0xFFDDF3C4),
    ),
    PuzzlePal(
      name: 'Momo the Cow',
      glyph: '🐄',
      habitat: Habitat.farm,
      decor: ['🌾', '🌻'],
      accent: Color(0xFFE0743F),
      bg1: Color(0xFFA8DCF2),
      bg2: Color(0xFFF0E4BC),
    ),
    PuzzlePal(
      name: 'Toot the Train',
      glyph: '🚂',
      habitat: Habitat.farm,
      decor: ['☁️', '🌳'],
      accent: Color(0xFFD8543F),
      bg1: Color(0xFF9AD3F2),
      bg2: Color(0xFFE8EFC6),
    ),
    PuzzlePal(
      name: 'Ellie the Elephant',
      glyph: '🐘',
      habitat: Habitat.jungle,
      decor: ['🍃', '🌺'],
      accent: Color(0xFF6E8FB8),
      bg1: Color(0xFFBFE9A8),
      bg2: Color(0xFFEAF6CB),
    ),
    PuzzlePal(
      name: 'Leo the Lion',
      glyph: '🦁',
      habitat: Habitat.jungle,
      decor: ['🌿', '🌞'],
      accent: Color(0xFFE0A02E),
      bg1: Color(0xFFF6DE9C),
      bg2: Color(0xFFDCEFAE),
    ),
    PuzzlePal(
      name: 'Mia the Monkey',
      glyph: '🐵',
      habitat: Habitat.jungle,
      decor: ['🍌', '🍃', '🌴'],
      accent: Color(0xFFB07A3E),
      bg1: Color(0xFFCDEDA6),
      bg2: Color(0xFFF2F5C8),
    ),
    PuzzlePal(
      name: 'Splash the Fish',
      glyph: '🐠',
      habitat: Habitat.ocean,
      decor: ['🐚', '🌿'],
      accent: Color(0xFFF08A3C),
      bg1: Color(0xFF8FD6F0),
      bg2: Color(0xFFCDEFF7),
    ),
    PuzzlePal(
      name: 'Wally the Whale',
      glyph: '🐳',
      habitat: Habitat.ocean,
      decor: ['⭐', '🐚'],
      accent: Color(0xFF3E92C4),
      bg1: Color(0xFF9EDCF4),
      bg2: Color(0xFFD8F0F8),
    ),
    PuzzlePal(
      name: 'Penny the Penguin',
      glyph: '🐧',
      habitat: Habitat.snow,
      decor: ['❄️', '⭐'],
      accent: Color(0xFF4E86B8),
      bg1: Color(0xFFBEE4F7),
      bg2: Color(0xFFF4FBFF),
    ),
    PuzzlePal(
      name: 'Rocky the Rocket',
      glyph: '🚀',
      habitat: Habitat.sky,
      decor: ['⭐', '🌈', '☁️'],
      accent: Color(0xFFE1604F),
      bg1: Color(0xFFA9D8F7),
      bg2: Color(0xFFEBDCF8),
    ),
  ];
}

// ---------------------------------------------------------------------------
// Scene painting
// ---------------------------------------------------------------------------

/// A picture that fills a square canvas. The puzzle clips it into jigsaw
/// pieces, so any implementation is interchangeable.
abstract class PuzzleScene {
  PuzzlePal get pal;
  void paint(Canvas canvas, Size size);
}

/// Paints a pal's whole scene procedurally.
///
/// Everything is laid out in a fixed 1000×1000 reference space and the canvas
/// is scaled to whatever the caller asked for. That matters because the puzzle
/// paints the same scene at several sizes in one frame — the full board, each
/// placed piece, every tray thumbnail and the piece growing in a dragging
/// hand — and the pieces only line up seamlessly if all of them agree on the
/// geometry. It also means the emoji [TextPainter]s are laid out once here
/// rather than on every repaint.
class PalScene implements PuzzleScene {
  @override
  final PuzzlePal pal;

  PalScene(this.pal);

  static const double _ref = 1000;

  /// Where props go, in reference space. Deliberately out at the corners: the
  /// centre belongs to the subject, and corner pieces are the ones that
  /// otherwise come out as flat blocks of sky.
  static const List<Offset> _propSpots = [
    Offset(150, 250),
    Offset(852, 300),
    Offset(175, 815),
    Offset(840, 800),
  ];

  late final TextPainter _subject = _glyph(pal.glyph, 430, shadow: true);
  late final List<TextPainter> _props =
      pal.decor.take(_propSpots.length).map((g) => _glyph(g, 118)).toList();

  static TextPainter _glyph(String text, double size, {bool shadow = false}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          shadows: shadow
              ? const [
                  Shadow(
                    color: Color(0x40000000),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static void _at(Canvas c, TextPainter tp, Offset center) {
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _ref, size.height / _ref);
    _backdrop(canvas);
    for (var i = 0; i < _props.length; i++) {
      _at(canvas, _props[i], _propSpots[i]);
    }
    // Sits a little above centre so the subject's face lands in the top row of
    // pieces, where a child looks first.
    _at(canvas, _subject, const Offset(500, 470));
    canvas.restore();
  }

  // --- Backdrops ----------------------------------------------------------

  void _backdrop(Canvas c) {
    const rect = Rect.fromLTWH(0, 0, _ref, _ref);
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.bg1, pal.bg2],
        ).createShader(rect),
    );

    final h = pal.habitat;
    if (h == Habitat.meadow) {
      _sun(c);
      _cloud(c, 250, 200, 1);
      _cloud(c, 760, 130, 0.7);
      _hills(c, const Color(0xFF7CCB5B), const Color(0xFF9BDC79));
    } else if (h == Habitat.farm) {
      _sun(c);
      _cloud(c, 220, 175, 0.85);
      _hills(c, const Color(0xFF86CC63), const Color(0xFFA6DC83));
      _fence(c);
    } else if (h == Habitat.jungle) {
      _sun(c);
      _leaves(c);
      _hills(c, const Color(0xFF63B84C), const Color(0xFF83C965));
    } else if (h == Habitat.ocean) {
      _waves(c);
      _bubbles(c);
      _seabed(c);
    } else if (h == Habitat.snow) {
      _sun(c);
      _flakes(c);
      _drifts(c);
    } else {
      _stars(c);
      _cloud(c, 210, 780, 0.9);
      _cloud(c, 800, 860, 1.1);
    }
  }

  void _hills(Canvas c, Color near, Color far) {
    final back = Path()
      ..moveTo(0, 690)
      ..quadraticBezierTo(240, 560, 520, 665)
      ..quadraticBezierTo(790, 765, 1000, 645)
      ..lineTo(1000, 1000)
      ..lineTo(0, 1000)
      ..close();
    c.drawPath(back, Paint()..color = far);

    final front = Path()
      ..moveTo(0, 835)
      ..quadraticBezierTo(300, 710, 610, 810)
      ..quadraticBezierTo(830, 878, 1000, 812)
      ..lineTo(1000, 1000)
      ..lineTo(0, 1000)
      ..close();
    c.drawPath(front, Paint()..color = near);
  }

  void _sun(Canvas c) {
    c.drawCircle(
      const Offset(838, 168),
      158,
      Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.45),
    );
    c.drawCircle(const Offset(838, 168), 98, Paint()..color = const Color(0xFFFFD84D));
  }

  void _cloud(Canvas c, double x, double y, double s) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 74 * s, y + 2 * s, 150 * s, 48 * s),
        Radius.circular(26 * s),
      ),
      p,
    );
    c.drawCircle(Offset(x, y), 50 * s, p);
    c.drawCircle(Offset(x + 56 * s, y + 12 * s), 38 * s, p);
    c.drawCircle(Offset(x - 54 * s, y + 16 * s), 32 * s, p);
  }

  void _fence(Canvas c) {
    final wood = Paint()..color = const Color(0xFFE8F0D2);
    for (var i = 0; i < 6; i++) {
      final x = 60.0 + i * 178;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 780, 26, 150),
          const Radius.circular(10),
        ),
        wood,
      );
    }
    for (final y in [812.0, 872.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(40, y, 940, 20),
          const Radius.circular(9),
        ),
        wood,
      );
    }
  }

  void _leaves(Canvas c) {
    final p = Paint()..color = const Color(0xFF4FAE41).withValues(alpha: 0.5);
    void leaf(Offset o, double r, double rot) {
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(rot);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(r * 0.66, -r * 0.5, r * 1.55, 0)
        ..quadraticBezierTo(r * 0.66, r * 0.5, 0, 0)
        ..close();
      c.drawPath(path, p);
      c.restore();
    }

    leaf(const Offset(-30, 95), 250, 0.32);
    leaf(const Offset(1030, 140), 235, math.pi - 0.28);
    leaf(const Offset(-40, 430), 205, -0.22);
    leaf(const Offset(1040, 470), 195, math.pi + 0.2);
  }

  void _waves(Canvas c) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 4; row++) {
      final path = Path()..moveTo(-40, 250.0 + row * 205);
      for (var i = 0; i < 9; i++) {
        path.relativeQuadraticBezierTo(35, -30, 70, 0);
        path.relativeQuadraticBezierTo(35, 30, 70, 0);
      }
      c.drawPath(path, p);
    }
  }

  void _bubbles(Canvas c) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.5);
    const spots = [
      [120.0, 640.0, 26.0],
      [186.0, 545.0, 16.0],
      [880.0, 600.0, 30.0],
      [812.0, 496.0, 18.0],
      [640.0, 880.0, 20.0],
    ];
    for (final s in spots) {
      c.drawCircle(Offset(s[0], s[1]), s[2], p);
    }
  }

  void _seabed(Canvas c) {
    final sand = Path()
      ..moveTo(0, 880)
      ..quadraticBezierTo(280, 800, 560, 872)
      ..quadraticBezierTo(800, 930, 1000, 866)
      ..lineTo(1000, 1000)
      ..lineTo(0, 1000)
      ..close();
    c.drawPath(sand, Paint()..color = const Color(0xFFF3E3B8));
  }

  void _drifts(Canvas c) {
    final snow = Paint()..color = Colors.white;
    final back = Path()
      ..moveTo(0, 730)
      ..quadraticBezierTo(260, 640, 540, 726)
      ..quadraticBezierTo(800, 800, 1000, 720)
      ..lineTo(1000, 1000)
      ..lineTo(0, 1000)
      ..close();
    c.drawPath(back, Paint()..color = const Color(0xFFE6F4FC));
    final front = Path()
      ..moveTo(0, 860)
      ..quadraticBezierTo(300, 780, 620, 858)
      ..quadraticBezierTo(840, 908, 1000, 856)
      ..lineTo(1000, 1000)
      ..lineTo(0, 1000)
      ..close();
    c.drawPath(front, snow);
  }

  void _flakes(Canvas c) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
    const spots = [
      [140.0, 170.0, 13.0],
      [330.0, 300.0, 9.0],
      [520.0, 150.0, 11.0],
      [700.0, 330.0, 9.0],
      [900.0, 430.0, 12.0],
      [250.0, 470.0, 10.0],
    ];
    for (final s in spots) {
      c.drawCircle(Offset(s[0], s[1]), s[2], p);
    }
  }

  void _stars(Canvas c) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.9);
    const spots = [
      [150.0, 150.0, 12.0],
      [330.0, 265.0, 8.0],
      [560.0, 130.0, 10.0],
      [740.0, 245.0, 9.0],
      [905.0, 145.0, 13.0],
      [455.0, 355.0, 7.0],
    ];
    for (final s in spots) {
      // A soft four-point twinkle: two crossed, rounded bars.
      final r = s[2];
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(s[0], s[1]), width: r * 2.6, height: r * 0.8),
          Radius.circular(r * 0.4),
        ),
        p,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(s[0], s[1]), width: r * 0.8, height: r * 2.6),
          Radius.circular(r * 0.4),
        ),
        p,
      );
    }
  }
}
