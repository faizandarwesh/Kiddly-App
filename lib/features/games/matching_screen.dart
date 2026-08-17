import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_gradient.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/round_button.dart';

/// Memory match: flip two cards to find matching friends. Tiny board (3 pairs)
/// so toddlers can win quickly. Every match sparkles; clearing the board
/// celebrates and deals a fresh, harder-by-one round.
class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _Card {
  final int pairId;
  final String emoji;
  bool matched = false;
  bool revealed = false;
  _Card(this.pairId, this.emoji);
}

class _MatchingScreenState extends State<MatchingScreen> {
  static const _pool = ['🐶', '🐱', '🐰', '🦊', '🐻', '🐼', '🦁', '🐸'];
  final _rng = math.Random();

  int _pairs = 3;
  late List<_Card> _cards;
  _Card? _first;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final chosen = (List.of(_pool)..shuffle(_rng)).take(_pairs).toList();
    _cards = [
      for (var i = 0; i < chosen.length; i++) ...[
        _Card(i, chosen[i]),
        _Card(i, chosen[i]),
      ],
    ]..shuffle(_rng);
    _first = null;
    _busy = false;
    setState(() {});
  }

  Future<void> _tap(_Card card) async {
    if (_busy || card.matched || card.revealed) return;
    Haptics.tap();
    AudioService.instance.sfx(Sfx.pop);
    setState(() => card.revealed = true);

    if (_first == null) {
      _first = card;
      return;
    }

    if (_first!.pairId == card.pairId) {
      // Match!
      AudioService.instance.sfx(Sfx.sparkle);
      setState(() {
        card.matched = true;
        _first!.matched = true;
        _first = null;
      });
      ProfileService.instance.awardStars(1);
      if (_cards.every((c) => c.matched)) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        Celebration.play(context, say: 'You matched them all!');
        _pairs = math.min(_pairs + 1, 6);
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) _deal();
      }
    } else {
      // No match — flip both back after a beat.
      _busy = true;
      final first = _first!;
      _first = null;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        card.revealed = false;
        first.revealed = false;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _cards.length <= 6 ? 3 : 4;
    return Scaffold(
      body: AnimatedGradient(
        palettes: const [
          [Color(0xFFDFF3FF), Color(0xFFE7E1FF)],
          [Color(0xFFE7FBE8), Color(0xFFDFF3FF)],
          [Color(0xFFFFE1F0), Color(0xFFE7E1FF)],
        ],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    RoundButton(
                      icon: Icons.home_rounded,
                      semanticLabel: 'Home',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    const Text('Match',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    RoundButton(
                      icon: Icons.refresh_rounded,
                      semanticLabel: 'Shuffle',
                      onTap: _deal,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      children: [
                        for (final c in _cards)
                          _FlipCard(card: c, onTap: () => _tap(c)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  final _Card card;
  final VoidCallback onTap;
  const _FlipCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final showFront = card.revealed || card.matched;
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: showFront ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final angle = t * math.pi;
          final front = t > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: front
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _face(
                      color: card.matched
                          ? AppColors.mint
                          : Colors.white,
                      child: Text(card.emoji,
                          style: const TextStyle(fontSize: 46)),
                    ),
                  )
                : _face(
                    color: AppColors.grape,
                    child: const Icon(Icons.star_rounded,
                        color: Colors.white70, size: 40),
                  ),
          );
        },
      ),
    );
  }

  Widget _face({required Color color, required Widget child}) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
