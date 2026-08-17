import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/haptics.dart';
import '../theme/app_colors.dart';

/// Fires a joyful full-screen celebration: confetti + floating stars, a happy
/// chime, a haptic thump and an optional cheerful voice line.
///
/// Used for every "win" moment. Positive-only — there is no failure equivalent.
class Celebration {
  Celebration._();

  static const List<String> praises = [
    'Great job!',
    'You did it!',
    'Wow!',
    'Amazing!',
    'Hooray!',
    'Yay!',
  ];

  static int _praiseCursor = 0;

  static void play(
    BuildContext context, {
    String? say,
    bool voice = true,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    Haptics.celebrate();
    AudioService.instance.sfx(Sfx.success);
    if (voice) {
      final phrase = say ?? praises[_praiseCursor++ % praises.length];
      // Small delay so the chime and the voice don't clash.
      Future.delayed(const Duration(milliseconds: 320),
          () => AudioService.instance.say(phrase));
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiLayer(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ConfettiLayer extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiLayer({required this.onDone});

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  final List<_Piece> _pieces = [];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    const emojis = ['⭐', '🌟', '🎈', '🎉', '💖', '✨', '🌈'];
    for (var i = 0; i < 46; i++) {
      _pieces.add(_Piece(
        x: _rng.nextDouble(),
        startY: -0.1 - _rng.nextDouble() * 0.3,
        drift: (_rng.nextDouble() - 0.5) * 0.5,
        size: 22 + _rng.nextDouble() * 34,
        spin: (_rng.nextDouble() - 0.5) * 8,
        speed: 0.8 + _rng.nextDouble() * 0.6,
        color: AppColors
            .partyGradients[i % AppColors.partyGradients.length].first,
        emoji: emojis[i % emojis.length],
        isEmoji: i % 3 == 0,
      ));
    }
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(_pieces, _c.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Piece {
  final double x, startY, drift, size, spin, speed;
  final Color color;
  final String emoji;
  final bool isEmoji;
  _Piece({
    required this.x,
    required this.startY,
    required this.drift,
    required this.size,
    required this.spin,
    required this.speed,
    required this.color,
    required this.emoji,
    required this.isEmoji,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t; // 0..1
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15);
    for (final p in pieces) {
      final progress = (t * p.speed).clamp(0.0, 1.0);
      final dy = p.startY + progress * 1.35;
      final dx = p.x + p.drift * progress;
      final center = Offset(dx * size.width, dy * size.height);
      if (center.dy < -40 || center.dy > size.height + 40) continue;

      if (p.isEmoji) {
        final tp = TextPainter(
          text: TextSpan(
            text: p.emoji,
            style: TextStyle(fontSize: p.size),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(p.spin * progress);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      } else {
        final paint = Paint()..color = p.color.withValues(alpha: fade);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(p.spin * progress);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size * 0.6, height: p.size * 0.4),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
