import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';

/// Bubble Pop: a calm, endless playground that doubles as colour practice.
/// Bright, saturated bubbles drift up and sway; tapping one pops it with a
/// sparkle and the friendly voice **names its colour** — "Red!", "Blue!" — so
/// every pop teaches something. Every few pops earns a star.
class BubbleScreen extends StatefulWidget {
  const BubbleScreen({super.key});

  @override
  State<BubbleScreen> createState() => _BubbleScreenState();
}

class _Bubble {
  final int id;
  final double x; // 0..1 base horizontal
  double y; // 0 bottom → 1 top
  final double size;
  final NamedColor color;
  final double speed; // per second
  final double phase;
  final double swayAmp;
  _Bubble(this.id, this.x, this.y, this.size, this.color, this.speed,
      this.phase, this.swayAmp);
}

class _BubbleScreenState extends State<BubbleScreen>
    with SingleTickerProviderStateMixin {
  /// The colours a child can actually name. Pulled straight from the palette
  /// the Colors world teaches so the two activities reinforce each other;
  /// black and white are left out — they read as "no colour" against the sky.
  static final List<NamedColor> _colors = AppColors.namedColors
      .where((c) => c.name != 'White' && c.name != 'Black')
      .toList();

  static const int _max = 14;

  final _rng = math.Random();
  final List<_Bubble> _bubbles = [];
  int _nextId = 0;
  int _pops = 0;
  Duration _last = Duration.zero;
  double _spawnAccum = 0;

  late final Ticker _ticker = createTicker(_tick);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 7; i++) {
      _bubbles.add(_spawn(startY: _rng.nextDouble() * 0.8));
    }
    _ticker.start();
  }

  _Bubble _spawn({double startY = -0.14}) {
    return _Bubble(
      _nextId++,
      0.08 + _rng.nextDouble() * 0.84,
      startY,
      // Bigger than before: a toddler's fingertip needs a fat target.
      64 + _rng.nextDouble() * 56,
      _colors[_rng.nextInt(_colors.length)],
      0.05 + _rng.nextDouble() * 0.09,
      _rng.nextDouble() * math.pi * 2,
      0.02 + _rng.nextDouble() * 0.05,
    );
  }

  void _tick(Duration elapsed) {
    var dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    if (dt > 0.05) dt = 0.05; // avoid big jumps after a stall

    for (final b in _bubbles) {
      b.y += b.speed * dt;
    }
    _bubbles.removeWhere((b) => b.y > 1.2);

    _spawnAccum += dt;
    if (_spawnAccum > 0.5 && _bubbles.length < _max) {
      _spawnAccum = 0;
      _bubbles.add(_spawn());
    }
    setState(() {});
  }

  void _pop(_Bubble b, Offset globalPos) {
    Haptics.pop();
    AudioService.instance.sfx(Sfx.pop);
    // The whole point: the child hears the colour they just popped.
    AudioService.instance.say('${b.color.name}!');
    SparkleBurst.at(context, globalPos, color: b.color.color, count: 12);
    setState(() => _bubbles.removeWhere((x) => x.id == b.id));
    _pops++;
    if (_pops % 5 == 0) {
      AudioService.instance.sfx(Sfx.sparkle);
      ProfileService.instance.awardStars(1);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    AudioService.instance.stopVoice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8ED8FF), Color(0xFFBFEFFF), Color(0xFFE3FBFF)],
          ),
        ),
        child: Stack(
          children: [
            // Bubbles.
            LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth, h = c.maxHeight;
                return Stack(
                  children: [
                    for (final b in _bubbles)
                      _positioned(b, w, h),
                  ],
                );
              },
            ),
            // Header + counter.
            SafeArea(
              child: Padding(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🫧', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 6),
                          Text('$_pops',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positioned(_Bubble b, double w, double h) {
    final sway = math.sin(b.y * 6 + b.phase) * b.swayAmp;
    final left = ((b.x + sway).clamp(0.0, 1.0)) * w - b.size / 2;
    final top = (1 - b.y) * h - b.size / 2;
    return Positioned(
      left: left,
      top: top,
      width: b.size,
      height: b.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _pop(b, d.globalPosition),
        child: _BubbleBall(color: b.color.color),
      ),
    );
  }
}

/// A bright, glossy ball. Deliberately near-opaque: the old translucent
/// version washed every colour out against the sky, so "the blue one" and
/// "the purple one" looked the same. Now the colour reads at full strength and
/// only the highlight is white.
class _BubbleBall extends StatelessWidget {
  final Color color;
  const _BubbleBall({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: [
            Color.lerp(color, Colors.white, 0.55)!,
            color,
            Color.lerp(color, Colors.black, 0.22)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.9), width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Big soft gleam.
          Align(
            alignment: const Alignment(-0.38, -0.45),
            child: FractionallySizedBox(
              widthFactor: 0.28,
              heightFactor: 0.28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
          // Tiny secondary sparkle, sells the "glass ball" look.
          Align(
            alignment: const Alignment(0.15, -0.62),
            child: FractionallySizedBox(
              widthFactor: 0.11,
              heightFactor: 0.11,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
