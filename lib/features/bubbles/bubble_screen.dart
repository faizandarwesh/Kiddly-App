import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';

/// Bubble Pop: a calm, endless playground. Colorful bubbles drift up and sway;
/// tapping one pops it with a sparkle and a soft sound. Pure cause-and-effect
/// delight for the very youngest — every few pops earns a star.
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
  final Color color;
  final double speed; // per second
  final double phase;
  final double swayAmp;
  _Bubble(this.id, this.x, this.y, this.size, this.color, this.speed,
      this.phase, this.swayAmp);
}

class _BubbleScreenState extends State<BubbleScreen>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFF4FC3F7),
    Color(0xFF9575F0),
    Color(0xFFFF8FC7),
    Color(0xFF57E0C0),
    Color(0xFFFFC107),
    Color(0xFFFF7A6B),
    Color(0xFF7ED957),
  ];
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

  _Bubble _spawn({double startY = -0.12}) {
    return _Bubble(
      _nextId++,
      0.08 + _rng.nextDouble() * 0.84,
      startY,
      46 + _rng.nextDouble() * 52,
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
    SparkleBurst.at(context, globalPos, color: b.color, count: 12);
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
                      onTap: () => Navigator.of(context).pop(),
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
        child: _BubbleBall(color: b.color),
      ),
    );
  }
}

class _BubbleBall extends StatelessWidget {
  final Color color;
  const _BubbleBall({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 0.95,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0.28),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Align(
        alignment: const Alignment(-0.35, -0.4),
        child: FractionallySizedBox(
          widthFactor: 0.24,
          heightFactor: 0.24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
