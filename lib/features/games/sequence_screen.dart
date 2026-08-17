import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_gradient.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/round_button.dart';

/// Number Memory: cards hide the numbers 1..N shuffled across a grid. They peek
/// once at the start, then flip down; the child must tap them in order
/// 1 → 2 → 3 … Correct taps stay up with a sparkle; wrong taps give a gentle
/// peek + "try again" (never a harsh fail). Trains memory, focus, number
/// recognition and sequencing. Grows 4 → 6 → 9 cards.
class SequenceScreen extends StatefulWidget {
  const SequenceScreen({super.key});

  @override
  State<SequenceScreen> createState() => _SequenceScreenState();
}

class _SequenceScreenState extends State<SequenceScreen> {
  // level → (count, columns)
  static const _levels = [
    [4, 2],
    [6, 3],
    [9, 3],
  ];

  static const _cardColors = [
    Color(0xFFF14B4B),
    Color(0xFF3E8EF7),
    Color(0xFFFF9A3D),
    Color(0xFF56C860),
    Color(0xFFA163E0),
    Color(0xFFFF8FC7),
    Color(0xFF57E0C0),
    Color(0xFF6C63FF),
    Color(0xFFFFC107),
  ];

  final _rng = math.Random();
  int _level = 0;
  late int _count;
  late int _cols;
  late List<int> _numbers; // number hidden at each position
  final Set<int> _found = {}; // positions correctly revealed
  int _next = 1; // number we're looking for
  bool _peeking = true;
  bool _busy = false;
  int _wrongPos = -1;
  int _wrongTick = 0;
  MascotMood _mood = MascotMood.happy;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final lv = _levels[math.min(_level, _levels.length - 1)];
    _count = lv[0];
    _cols = lv[1];
    _numbers = List.generate(_count, (i) => i + 1)..shuffle(_rng);
    _found.clear();
    _next = 1;
    _wrongPos = -1;
    _busy = false;
    _mood = MascotMood.happy;
    _peeking = true;
    setState(() {});
    AudioService.instance.say('Remember where the numbers are!');
    // Show the numbers, then flip them all down.
    Future.delayed(Duration(milliseconds: 1600 + 260 * _count), () {
      if (!mounted) return;
      setState(() => _peeking = false);
      AudioService.instance.say('Find one!');
    });
  }

  Future<void> _tap(int pos) async {
    if (_peeking || _busy || _found.contains(pos)) return;
    final value = _numbers[pos];

    if (value == _next) {
      Haptics.pop();
      AudioService.instance.sfx(Sfx.sparkle);
      AudioService.instance.say('$value');
      setState(() {
        _found.add(pos);
        _next++;
        _mood = MascotMood.excited;
      });
      ProfileService.instance.awardStars(1);

      if (_next > _count) {
        _busy = true;
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Celebration.play(context, say: 'Perfect! You did it!');
        setState(() => _mood = MascotMood.cheer);
        await Future.delayed(const Duration(milliseconds: 1700));
        if (!mounted) return;
        _level++;
        _deal();
      }
    } else {
      // Wrong card → funny sound, then the whole board resets to the start and
      // the child begins again from 1 (with a quick fresh peek). Never harsh.
      Haptics.pop();
      AudioService.instance.sfx(Sfx.funny);
      AudioService.instance.say('Oops! Let us start again!');
      setState(() {
        _wrongPos = pos; // briefly show the wrong card + shake
        _wrongTick++;
        _busy = true;
        _mood = MascotMood.happy;
      });
      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      // Back to the initial state: clear all progress and re-peek.
      setState(() {
        _found.clear();
        _next = 1;
        _wrongPos = -1;
        _peeking = true;
      });
      await Future.delayed(Duration(milliseconds: 1300 + 140 * _count));
      if (!mounted) return;
      setState(() {
        _peeking = false;
        _busy = false;
      });
      AudioService.instance.say('Find one!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradient(
        palettes: const [
          [Color(0xFFE7E1FF), Color(0xFFDFF3FF)],
          [Color(0xFFDFF3FF), Color(0xFFE7FBE8)],
          [Color(0xFFFFE1F0), Color(0xFFE7E1FF)],
        ],
        child: SafeArea(
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
                    const Text('Memory',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    RoundButton(
                      icon: Icons.visibility_rounded,
                      semanticLabel: 'Peek',
                      onTap: _busy
                          ? () {}
                          : () {
                              setState(() => _peeking = true);
                              AudioService.instance.sfx(Sfx.sparkle);
                              Future.delayed(
                                  const Duration(milliseconds: 1200), () {
                                if (mounted) setState(() => _peeking = false);
                              });
                            },
                    ),
                  ],
                ),
              ),
              // Target prompt.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _TargetPrompt(
                  peeking: _peeking,
                  next: _next,
                  count: _count,
                  color: _cardColors[(_next - 1).clamp(0, _cardColors.length - 1)],
                ),
              ),
              // Card grid.
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: GridView.count(
                      crossAxisCount: _cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      children: [
                        for (var i = 0; i < _count; i++)
                          _MemoryCard(
                            number: _numbers[i],
                            color: _cardColors[
                                (_numbers[i] - 1) % _cardColors.length],
                            faceUp: _peeking ||
                                _found.contains(i) ||
                                _wrongPos == i,
                            wrong: _wrongPos == i,
                            shakeTick: _wrongPos == i ? _wrongTick : 0,
                            onTap: () => _tap(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Mascot companion.
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Mascot(size: 84, mood: _mood),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetPrompt extends StatelessWidget {
  final bool peeking;
  final int next;
  final int count;
  final Color color;
  const _TargetPrompt({
    required this.peeking,
    required this.next,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: peeking
          ? const Text('Remember! 👀',
              key: ValueKey('peek'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))
          : Row(
              key: ValueKey('find$next'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Find ',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text('$next',
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ],
            ),
    );
  }
}

class _MemoryCard extends StatefulWidget {
  final int number;
  final Color color;
  final bool faceUp;
  final bool wrong;
  final int shakeTick;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.number,
    required this.color,
    required this.faceUp,
    required this.wrong,
    required this.shakeTick,
    required this.onTap,
  });

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant _MemoryCard old) {
    super.didUpdateWidget(old);
    if (widget.shakeTick != old.shakeTick && widget.shakeTick != 0) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final dx = math.sin(_shake.value * math.pi * 6) *
              10 *
              (1 - _shake.value);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.faceUp ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          builder: (context, t, _) {
            final angle = t * math.pi;
            final showFront = t > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showFront
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _front(),
                    )
                  : _back(),
            );
          },
        ),
      ),
    );
  }

  Widget _front() {
    final highlight = widget.wrong ? AppColors.coral : widget.color;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight, width: 4),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text('${widget.number}',
              style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  color: widget.color)),
        ),
      ),
    );
  }

  Widget _back() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color,
            Color.lerp(widget.color, Colors.black, 0.2)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: const Text('?',
          style: TextStyle(
              fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white70)),
    );
  }
}
