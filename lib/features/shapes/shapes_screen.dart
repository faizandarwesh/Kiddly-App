import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';
import '../../data/shapes.dart';

/// Shapes world — a magical little stage. Each shape is a living character with
/// a blinking face and a glossy candy finish, floating over a color-themed
/// scene of drifting shapes. Tap it and it hops; tap again and it *poofs* into a
/// real-world object. Swipe or use the shape carousel to explore them all.
class ShapesScreen extends StatefulWidget {
  const ShapesScreen({super.key});

  @override
  State<ShapesScreen> createState() => _ShapesScreenState();
}

class _ShapesScreenState extends State<ShapesScreen> {
  final _controller = PageController();
  final _shapes = Shapes.all;
  final Set<ShapeKind> _found = {};
  int _index = 0;
  bool _finaleShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => AudioService.instance.say(_shapes[0].name));
  }

  void _jumpTo(int i) {
    _controller.animateToPage(i,
        duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  void _onFound(ShapeInfo info) {
    if (_found.add(info.kind)) {
      ProfileService.instance.awardStars(1);
      setState(() {});
      if (_found.length == _shapes.length && !_finaleShown) {
        _finaleShown = true;
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            Celebration.play(context, say: 'You found every shape! Wow!');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _shapes[_index];
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _ShapeSky(color: current.color)),
          SafeArea(
            child: Column(
              children: [
                // Header.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      RoundButton(
                        icon: Icons.home_rounded,
                        semanticLabel: 'Home',
                        onTap: () {
                          AudioService.instance.stopVoice();
                          Navigator.of(context).pop();
                        },
                      ),
                      const Spacer(),
                      const Text('Shapes',
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      _TrophyChip(found: _found.length, total: _shapes.length),
                    ],
                  ),
                ),
                // Hero stage.
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _shapes.length,
                    onPageChanged: (i) {
                      setState(() => _index = i);
                      AudioService.instance.say(_shapes[i].name);
                    },
                    itemBuilder: (context, i) => _ShapeStage(
                      key: ValueKey(_shapes[i].kind),
                      info: _shapes[i],
                      onFound: () => _onFound(_shapes[i]),
                    ),
                  ),
                ),
                // Shape carousel.
                _ShapePicker(
                  shapes: _shapes,
                  current: _index,
                  onSelect: _jumpTo,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background: a color-themed sky with slowly drifting translucent shapes.
// ---------------------------------------------------------------------------

class _ShapeSky extends StatefulWidget {
  final Color color;
  const _ShapeSky({required this.color});

  @override
  State<_ShapeSky> createState() => _ShapeSkyState();
}

class _ShapeSkyState extends State<_ShapeSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(widget.color, Colors.white, 0.82)!,
            Color.lerp(widget.color, Colors.white, 0.62)!,
            Color.lerp(widget.color, Colors.white, 0.74)!,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _FloatingShapesPainter(_c.value, widget.color),
        ),
      ),
    );
  }
}

class _FloatingShapesPainter extends CustomPainter {
  final double t;
  final Color tint;
  _FloatingShapesPainter(this.t, this.tint);

  // Deterministic scatter of decorative shapes.
  static const _specs = [
    [0.12, 0.20, 26.0, 0.7, 0.0],
    [0.82, 0.16, 34.0, 0.5, 0.3],
    [0.68, 0.55, 22.0, 0.9, 0.6],
    [0.22, 0.62, 30.0, 0.6, 0.15],
    [0.90, 0.72, 24.0, 0.8, 0.45],
    [0.06, 0.85, 28.0, 0.55, 0.8],
    [0.50, 0.30, 20.0, 1.0, 0.2],
    [0.40, 0.88, 32.0, 0.65, 0.9],
    [0.75, 0.90, 22.0, 0.75, 0.5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final kinds = ShapeKind.values;
    for (var i = 0; i < _specs.length; i++) {
      final s = _specs[i];
      final baseX = s[0], baseY = s[1], r = s[2], speed = s[3], phase = s[4];
      // Drift upward and wrap around.
      final y = ((baseY - t * speed + phase) % 1.2) - 0.1;
      final center = Offset(baseX * size.width, y * size.height);
      final path = ShapePainter.buildPath(kinds[i % kinds.length], center, r);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((t * 2 * math.pi * speed) + phase * 6);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: 0.16),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingShapesPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// The stage with the hero character + labels + tap hint.
// ---------------------------------------------------------------------------

class _ShapeStage extends StatefulWidget {
  final ShapeInfo info;
  final VoidCallback onFound;
  const _ShapeStage({super.key, required this.info, required this.onFound});

  @override
  State<_ShapeStage> createState() => _ShapeStageState();
}

class _ShapeStageState extends State<_ShapeStage> {
  bool _transformed = false;
  bool _tapped = false;

  void _tap(Offset pos) {
    setState(() => _tapped = true);
    SparkleBurst.at(context, pos, color: widget.info.color, count: 16);
    if (!_transformed) {
      AudioService.instance.say(widget.info.name);
      Future.delayed(const Duration(milliseconds: 560), () {
        if (!mounted) return;
        setState(() => _transformed = true);
        AudioService.instance.say("It's a ${widget.info.becomesName}!");
        widget.onFound();
      });
    } else {
      setState(() => _transformed = false);
      AudioService.instance.say(widget.info.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShapeCharacter(
            info: widget.info,
            transformed: _transformed,
            onTapAt: _tap,
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              _transformed ? widget.info.becomesName : widget.info.name,
              key: ValueKey(_transformed),
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Color.lerp(widget.info.color, AppColors.ink, 0.55),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // A bobbing hint hand, until the child first taps.
          AnimatedOpacity(
            opacity: _tapped ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: _BobbingHint(color: widget.info.color),
          ),
        ],
      ),
    );
  }
}

class _BobbingHint extends StatefulWidget {
  final Color color;
  const _BobbingHint({required this.color});

  @override
  State<_BobbingHint> createState() => _BobbingHintState();
}

class _BobbingHintState extends State<_BobbingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👆', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text('Tap me!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color.lerp(widget.color, AppColors.ink, 0.5))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The hero character: glossy shape + face + halo + shadow + hop + morph.
// ---------------------------------------------------------------------------

class ShapeCharacter extends StatefulWidget {
  final ShapeInfo info;
  final bool transformed;
  final void Function(Offset globalPosition) onTapAt;

  const ShapeCharacter({
    super.key,
    required this.info,
    required this.transformed,
    required this.onTapAt,
  });

  @override
  State<ShapeCharacter> createState() => _ShapeCharacterState();
}

class _ShapeCharacterState extends State<ShapeCharacter>
    with TickerProviderStateMixin {
  static const double _box = 250;
  static const double _shape = 210;

  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );

  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    final ms = 2400 + math.Random().nextInt(2600);
    Future.delayed(Duration(milliseconds: ms), () async {
      if (!mounted) return;
      await _blink.forward();
      await _blink.reverse();
      _scheduleBlink();
    });
  }

  @override
  void didUpdateWidget(covariant ShapeCharacter old) {
    super.didUpdateWidget(old);
    if (widget.transformed != old.transformed) {
      _ring.forward(from: 0);
    }
  }

  void _tap(Offset pos) {
    Haptics.pop();
    AudioService.instance.sfx(Sfx.pop);
    _hop.forward(from: 0);
    widget.onTapAt(pos);
  }

  @override
  void dispose() {
    _idle.dispose();
    _blink.dispose();
    _hop.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (d) => _tap(d.globalPosition),
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _blink, _hop, _ring]),
        builder: (context, _) {
          final breath = math.sin(_idle.value * 2 * math.pi);
          final hop = math.sin(math.pi * Curves.easeOut.transform(_hop.value));
          final ty = breath * 5 - hop * 46;
          final mouthOpen = hop;

          return SizedBox(
            width: _box,
            height: _box,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing halo.
                Container(
                  width: _box * (0.98 + 0.03 * breath),
                  height: _box * (0.98 + 0.03 * breath),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.info.color
                            .withValues(alpha: 0.30 + 0.08 * breath),
                        widget.info.color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                // Ground shadow (stays put while the shape hops).
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: _shape * 0.62 * (1 - 0.35 * hop),
                    height: 20 * (1 - 0.3 * hop),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14 * (1 - 0.5 * hop)),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                // Morph "poof" ring.
                if (_ring.isAnimating)
                  CustomPaint(
                    size: const Size(_box, _box),
                    painter: _RingPainter(_ring.value, widget.info.color),
                  ),
                // The figure (shape+face) or its transformed object.
                Transform.translate(
                  offset: Offset(0, ty),
                  child: Transform.scale(
                    scaleX: 1 - 0.08 * hop,
                    scaleY: 1 + 0.12 * hop + 0.03 * breath,
                    child: Transform.rotate(
                      angle: breath * 0.05,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: Tween(begin: 0.8, end: 1.0).animate(anim),
                          child: ScaleTransition(
                            scale: CurvedAnimation(
                                parent: anim, curve: Curves.easeOutBack),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                        ),
                        child: widget.transformed
                            ? SizedBox(
                                key: const ValueKey('object'),
                                width: _shape,
                                height: _shape,
                                child: Center(
                                  child: Text(widget.info.becomesEmoji,
                                      style: const TextStyle(fontSize: 150)),
                                ),
                              )
                            : SizedBox(
                                key: const ValueKey('shape'),
                                width: _shape,
                                height: _shape,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: ShapePainter(
                                            widget.info.kind, widget.info.color,
                                            glossy: true),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _ShapeFacePainter(
                                          kind: widget.info.kind,
                                          blink: _blink.value,
                                          mouthOpen: mouthOpen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  _RingPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final eased = Curves.easeOut.transform(t);
    for (var k = 0; k < 2; k++) {
      final r = 50 + eased * (95 + k * 26);
      final a = (1 - t).clamp(0.0, 1.0) * (k == 0 ? 0.7 : 0.4);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 * (1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.t != t;
}

/// Draws a cute blinking face centered on the current shape.
class _ShapeFacePainter extends CustomPainter {
  final ShapeKind kind;
  final double blink; // 0 open → 1 closed
  final double mouthOpen; // 0 smile → 1 open "O"
  _ShapeFacePainter(
      {required this.kind, required this.blink, required this.mouthOpen});

  double get _faceY {
    switch (kind) {
      case ShapeKind.triangle:
        return 0.60;
      case ShapeKind.heart:
        return 0.46;
      case ShapeKind.star:
        return 0.52;
      default:
        return 0.50;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = size.width / 2;
    final cy = size.height * _faceY;
    final eyeDx = w * 0.13;
    final eyeY = cy - w * 0.03;
    final ink = Paint()..color = const Color(0xFF2E2A44);
    final eyeOpen = (1 - blink).clamp(0.0, 1.0);

    // Blush.
    final blush = Paint()..color = const Color(0xFFFF7DA8).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx - eyeDx * 1.55, eyeY + w * 0.05), w * 0.045, blush);
    canvas.drawCircle(Offset(cx + eyeDx * 1.55, eyeY + w * 0.05), w * 0.045, blush);

    // Eyes.
    void eye(double dx) {
      final e = Offset(cx + dx, eyeY);
      if (eyeOpen < 0.2) {
        final path = Path()
          ..moveTo(e.dx - w * 0.05, e.dy)
          ..quadraticBezierTo(e.dx, e.dy + w * 0.04, e.dx + w * 0.05, e.dy);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF2E2A44)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.022
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
              center: e, width: w * 0.075, height: w * 0.10 * eyeOpen),
          ink,
        );
        canvas.drawCircle(
          Offset(e.dx + w * 0.02, e.dy - w * 0.02 * eyeOpen),
          w * 0.017 * eyeOpen,
          Paint()..color = Colors.white,
        );
      }
    }

    eye(-eyeDx);
    eye(eyeDx);

    // Mouth.
    final my = cy + w * 0.085;
    if (mouthOpen > 0.15) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, my), width: w * 0.11, height: w * 0.12 * mouthOpen),
        ink,
      );
    } else {
      final smile = Path()
        ..moveTo(cx - w * 0.07, my)
        ..quadraticBezierTo(cx, my + w * 0.075, cx + w * 0.07, my);
      canvas.drawPath(
        smile,
        Paint()
          ..color = const Color(0xFF2E2A44)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.024
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeFacePainter old) =>
      old.blink != blink || old.mouthOpen != mouthOpen || old.kind != kind;
}

// ---------------------------------------------------------------------------
// Bottom shape carousel.
// ---------------------------------------------------------------------------

class _ShapePicker extends StatelessWidget {
  final List<ShapeInfo> shapes;
  final int current;
  final void Function(int) onSelect;
  const _ShapePicker(
      {required this.shapes, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: shapes.length,
        itemBuilder: (context, i) {
          final selected = i == current;
          final info = shapes[i];
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              // NOTE: keep a non-overshooting curve here. An overshooting curve
              // (easeOutBack) drives the lerped boxShadow blur negative and
              // trips a framework assertion.
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              width: selected ? 84 : 66,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              padding: EdgeInsets.all(selected ? 12 : 14),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? info.color : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: info.color.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: CustomPaint(
                painter: ShapePainter(info.kind, info.color, glossy: true),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrophyChip extends StatelessWidget {
  final int found;
  final int total;
  const _TrophyChip({required this.found, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text('$found/$total',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
