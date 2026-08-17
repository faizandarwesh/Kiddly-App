import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/widgets/bouncy.dart';
import '../../core/widgets/floaty.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/reward_hud.dart';
import '../parent/parent_gate.dart';
import 'activities.dart';

/// The "Playroom Toy Box" home: a magical garden backdrop with the worlds
/// floating over it as glassy, tilted toy portals, an outlined "Let's Play!"
/// title, and the mascot, parent-lock and reward pill drifting up top.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MascotMood _mood = MascotMood.happy;

  static const _cheers = [
    'Hi friend!',
    'Wanna play?',
    'Pick a world!',
    'Yay!',
    'Tee hee!',
  ];
  int _cheerCursor = 0;

  void _open(Activity a) {
    AudioService.instance.stopVoice();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, anim, secondary) => a.builder(context),
        transitionsBuilder: (context, anim, secondary, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
    );
  }

  void _pokeMascot() {
    AudioService.instance.say(_cheers[_cheerCursor++ % _cheers.length]);
    setState(() => _mood =
        _mood == MascotMood.excited ? MascotMood.happy : MascotMood.excited);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fixed magical-garden backdrop.
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_garden_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Gentle spinning wish-star, low in the sky.
          const Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Floaty(
                style: FloatyStyle.spin,
                period: Duration(seconds: 16),
                child: Opacity(opacity: 0.85, child: Text('⭐', style: TextStyle(fontSize: 40))),
              ),
            ),
          ),

          // Scrollable scatter of floating world toys.
          Positioned.fill(child: _ToyScatter(onOpen: _open)),

          // Fixed foreground UI.
          SafeArea(
            child: Stack(
              children: [
                // Outlined title.
                const Positioned(
                  top: 6,
                  left: 24,
                  right: 24,
                  child: Center(child: _OutlinedTitle("Let's Play!")),
                ),

                // Parent lock + waving mascot, top-left.
                Positioned(
                  top: 60,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ParentGateButton(),
                      const SizedBox(height: 14),
                      Floaty(
                        style: FloatyStyle.bob,
                        period: const Duration(seconds: 5),
                        amplitude: 0.7,
                        child: _MascotBubble(mood: _mood, onPoke: _pokeMascot),
                      ),
                    ],
                  ),
                ),

                // Reward pill, top-right.
                Positioned(
                  top: 125,
                  right: 16,
                  child: Floaty(
                    style: FloatyStyle.sway,
                    period: const Duration(seconds: 6),
                    amplitude: 0.5,
                    child: const RewardHud(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The mascot in a frosted white bubble with a waving hand, tappable to cheer.
class _MascotBubble extends StatelessWidget {
  final MascotMood mood;
  final VoidCallback onPoke;
  const _MascotBubble({required this.mood, required this.onPoke});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPoke,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: OverflowBox(
                maxWidth: 96,
                maxHeight: 116,
                child: Mascot(size: 66, mood: mood),
              ),
            ),
          ),
          const Positioned(
            right: -6,
            bottom: -4,
            child: Text('👋', style: TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }
}

/// Lays every world out over the garden as an organic, scrolling scatter of
/// tilted toy portals.
class _ToyScatter extends StatelessWidget {
  final void Function(Activity) onOpen;
  const _ToyScatter({required this.onOpen});

  static const double _rowH = 210;
  static const double _topPad = 236;
  static const double _cell = 156;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final n = kActivities.length;
        final rows = (n / 2).ceil();
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final totalH = _topPad + rows * _rowH + 140 + bottomInset;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: w,
            height: totalH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < n; i++) _positioned(i, w),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _positioned(int i, double w) {
    final col = i % 2;
    final row = i ~/ 2;
    final centerX = (col == 0 ? 0.30 : 0.70) + 0.045 * math.sin(i * 1.6);
    final left = centerX * w - _cell / 2;
    final top = _topPad + row * _rowH + (col == 1 ? _rowH * 0.46 : 0.0);
    final a = kActivities[i];
    final style = _toyStyles[i % _toyStyles.length];

    return Positioned(
      left: left,
      top: top,
      width: _cell,
      child: Floaty(
        style: i.isEven ? FloatyStyle.bob : FloatyStyle.sway,
        period: Duration(milliseconds: 4200 + 500 * (i % 5)),
        delay: Duration(milliseconds: 180 * i),
        amplitude: 0.7,
        child: _ToyPortal(
          emoji: a.emoji,
          label: a.label,
          gradient: _toyGradients[i % _toyGradients.length],
          shape: style.shape,
          degrees: style.degrees,
          index: i,
          onOpen: () => onOpen(a),
        ),
      ),
    );
  }
}

enum _ToyShape { circle, squircle, pill, diamond }

class _ToyStyle {
  final _ToyShape shape;
  final double degrees;
  const _ToyStyle(this.shape, this.degrees);
}

/// The rotation + shape rhythm lifted from the Stitch toy scatter.
const List<_ToyStyle> _toyStyles = [
  _ToyStyle(_ToyShape.circle, -5),
  _ToyStyle(_ToyShape.squircle, 12),
  _ToyStyle(_ToyShape.pill, -12),
  _ToyStyle(_ToyShape.circle, 15),
  _ToyStyle(_ToyShape.diamond, 45),
  _ToyStyle(_ToyShape.squircle, -10),
];

/// Glassy toy-portal palette (top-left brighter → deeper bottom-right).
const List<List<Color>> _toyGradients = [
  [Color(0xFF4A9DF8), Color(0xFF3B82E0)], // blue
  [Color(0xFFA879ED), Color(0xFF8A5CE0)], // purple
  [Color(0xFFF9A844), Color(0xFFF0851E)], // orange
  [Color(0xFF3EAAED), Color(0xFF2E90D8)], // teal
  [Color(0xFFFC778B), Color(0xFFE85570)], // pink
  [Color(0xFF7FD68B), Color(0xFF52C066)], // green
  [Color(0xFFC79CFF), Color(0xFF9B6BEA)], // lilac
  [Color(0xFFFFB03D), Color(0xFFF5871E)], // amber
];

/// A single floating world: a tilted, glassy gradient portal with a top gloss,
/// white rim and big emoji, over an upright translucent label pill.
class _ToyPortal extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Color> gradient;
  final _ToyShape shape;
  final double degrees;
  final int index;
  final VoidCallback onOpen;

  const _ToyPortal({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.shape,
    required this.degrees,
    required this.index,
    required this.onOpen,
  });

  void _tap() {
    AudioService.instance.say(label);
    Future.delayed(const Duration(milliseconds: 220), onOpen);
  }

  Size get _size => switch (shape) {
        _ToyShape.pill => const Size(150, 96),
        _ToyShape.circle => const Size(120, 120),
        _ToyShape.diamond => const Size(118, 118),
        _ToyShape.squircle => const Size(116, 116),
      };

  BorderRadius? get _radius => switch (shape) {
        _ToyShape.circle => null,
        _ToyShape.pill => const BorderRadius.all(Radius.elliptical(150, 96)),
        _ToyShape.diamond => BorderRadius.circular(26),
        _ToyShape.squircle => BorderRadius.circular(30),
      };

  @override
  Widget build(BuildContext context) {
    final s = _size;
    final radius = _radius;
    final angle = degrees * math.pi / 180;

    final body = Container(
      width: s.width,
      height: s.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient.first.withValues(alpha: 0.86),
            gradient.last.withValues(alpha: 0.86),
          ],
        ),
        shape: shape == _ToyShape.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 4),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top gloss highlight.
          Positioned(
            top: s.height * 0.06,
            left: s.width * 0.08,
            right: s.width * 0.08,
            height: s.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCCFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          // Emoji, counter-rotated so it stays upright.
          Transform.rotate(
            angle: -angle,
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: shape == _ToyShape.pill ? 44 : 52,
                shadows: const [
                  Shadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Bouncy(
      onTap: _tap,
      pressedScale: 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 168,
            child: Center(child: Transform.rotate(angle: angle, child: body)),
          ),
          const SizedBox(height: 4),
          _LabelPill(label),
        ],
      ),
    );
  }
}

/// Upright, translucent-dark pill label — uppercase, white, bold.
class _LabelPill extends StatelessWidget {
  final String text;
  const _LabelPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.8,
          shadows: [
            Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }
}

/// White-filled, dark-outlined storybook title — the design's "Let's Play!".
class _OutlinedTitle extends StatelessWidget {
  final String text;
  const _OutlinedTitle(this.text);

  @override
  Widget build(BuildContext context) {
    const size = 42.0;
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF2F2F4F),
          ),
        ),
        Text(
          text,
          style: const TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: Colors.white,
            shadows: [
              Shadow(color: Color(0x4D000000), blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
        ),
      ],
    );
  }
}
