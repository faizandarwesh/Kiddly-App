import 'package:flutter/material.dart';

import '../services/profile_service.dart';

/// A small always-visible tally of the active child's collected rewards.
/// Each chip springs and its number rolls whenever the value increases.
/// Set [vertical] for the stacked pill used on the home dashboard.
class RewardHud extends StatelessWidget {
  final bool vertical;
  const RewardHud({super.key, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProfileService.instance,
      builder: (context, _) {
        final p = ProfileService.instance.active;
        if (p == null) return const SizedBox.shrink();
        final chips = [
          _Chip(emoji: '⭐', count: p.stars),
          _Chip(emoji: '🌈', count: p.rainbows),
          _Chip(emoji: '💖', count: p.hearts),
        ];
        return Container(
          padding: vertical
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: vertical
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chips[0],
                    const SizedBox(height: 10),
                    chips[1],
                    const SizedBox(height: 10),
                    chips[2],
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    chips[0],
                    const SizedBox(width: 10),
                    chips[1],
                    const SizedBox(width: 10),
                    chips[2],
                  ],
                ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String emoji;
  final int count;
  const _Chip({required this.emoji, required this.count});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$emoji-$count'),
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SizeTransition(
                  sizeFactor: anim, axis: Axis.vertical, child: child),
            ),
            child: Text(
              '$count',
              key: ValueKey(count),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
