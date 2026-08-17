import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Moods the mascot can express to give the child an emotional companion.
enum MascotMood { happy, excited, sleepy, cheer }

/// Bobbie the Bunny — the app's hand-drawn mascot, rendered entirely with a
/// [CustomPainter] (no image assets). Breathes and blinks on idle so it always
/// feels alive, and changes expression with [mood].
class Mascot extends StatefulWidget {
  final double size;
  final MascotMood mood;

  const Mascot({super.key, this.size = 140, this.mood = MascotMood.happy});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    // Blink at a slightly irregular cadence.
    final ms = 2200 + math.Random().nextInt(2600);
    Future.delayed(Duration(milliseconds: ms), () async {
      if (!mounted) return;
      await _blink.forward();
      await _blink.reverse();
      _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _breathe.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathe, _blink]),
      builder: (context, _) {
        final breath = Curves.easeInOut.transform(_breathe.value);
        return Transform.translate(
          offset: Offset(0, -3 + breath * 6),
          child: Transform.scale(
            scale: 1 + breath * 0.02,
            child: CustomPaint(
              size: Size(widget.size, widget.size * 1.25),
              painter: _BunnyPainter(
                mood: widget.mood,
                blink: widget.mood == MascotMood.sleepy ? 1 : _blink.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BunnyPainter extends CustomPainter {
  final MascotMood mood;
  final double blink; // 0 open .. 1 closed
  _BunnyPainter({required this.mood, required this.blink});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fur = Paint()..color = const Color(0xFFFFFFFF);
    final furShade = Paint()..color = const Color(0xFFEDE7FB);
    final pink = Paint()..color = AppColors.bubblegum;
    final dark = Paint()..color = AppColors.ink;

    final faceCenter = Offset(w * 0.5, h * 0.56);
    final faceRadius = w * 0.42;

    // Ears.
    void ear(double dx, double tilt) {
      canvas.save();
      canvas.translate(faceCenter.dx + dx, faceCenter.dy - faceRadius * 0.7);
      canvas.rotate(tilt);
      final earRect = Rect.fromCenter(
          center: Offset.zero, width: w * 0.20, height: h * 0.42);
      canvas.drawRRect(
          RRect.fromRectAndRadius(earRect, Radius.circular(w * 0.12)), fur);
      final innerRect = Rect.fromCenter(
          center: Offset.zero, width: w * 0.10, height: h * 0.30);
      canvas.drawRRect(
          RRect.fromRectAndRadius(innerRect, Radius.circular(w * 0.06)), pink);
      canvas.restore();
    }

    ear(-w * 0.16, -0.18);
    ear(w * 0.16, 0.18);

    // Head.
    canvas.drawCircle(faceCenter, faceRadius, fur);
    // Soft shadow under chin.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(faceCenter.dx, faceCenter.dy + faceRadius * 0.55),
          width: faceRadius * 1.5,
          height: faceRadius * 0.7),
      furShade,
    );
    canvas.drawCircle(faceCenter, faceRadius, fur..color = const Color(0xFFFFFFFF));

    // Cheeks.
    final cheekPaint = Paint()..color = AppColors.bubblegum.withValues(alpha: 0.55);
    canvas.drawCircle(
        Offset(faceCenter.dx - faceRadius * 0.55, faceCenter.dy + faceRadius * 0.15),
        faceRadius * 0.20,
        cheekPaint);
    canvas.drawCircle(
        Offset(faceCenter.dx + faceRadius * 0.55, faceCenter.dy + faceRadius * 0.15),
        faceRadius * 0.20,
        cheekPaint);

    // Eyes.
    final eyeY = faceCenter.dy - faceRadius * 0.12;
    final eyeDx = faceRadius * 0.42;
    final eyeOpen = (1 - blink).clamp(0.0, 1.0);
    void eye(double dx) {
      final c = Offset(faceCenter.dx + dx, eyeY);
      if (eyeOpen < 0.15) {
        // Closed / sleepy: a happy arc.
        final path = Path()
          ..moveTo(c.dx - faceRadius * 0.14, c.dy)
          ..quadraticBezierTo(
              c.dx, c.dy + faceRadius * 0.12, c.dx + faceRadius * 0.14, c.dy);
        canvas.drawPath(
          path,
          Paint()
            ..color = AppColors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = faceRadius * 0.06
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
              center: c,
              width: faceRadius * 0.24,
              height: faceRadius * 0.30 * eyeOpen),
          dark,
        );
        // Sparkle highlight.
        canvas.drawCircle(
            Offset(c.dx + faceRadius * 0.05, c.dy - faceRadius * 0.06 * eyeOpen),
            faceRadius * 0.05 * eyeOpen,
            Paint()..color = Colors.white);
      }
    }

    eye(-eyeDx);
    eye(eyeDx);

    // Nose.
    final noseC = Offset(faceCenter.dx, faceCenter.dy + faceRadius * 0.12);
    canvas.drawOval(
        Rect.fromCenter(
            center: noseC, width: faceRadius * 0.18, height: faceRadius * 0.13),
        pink..color = AppColors.coral);

    // Mouth (varies with mood).
    final mouth = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceRadius * 0.05
      ..strokeCap = StrokeCap.round;
    final my = noseC.dy + faceRadius * 0.14;
    final path = Path();
    switch (mood) {
      case MascotMood.excited:
      case MascotMood.cheer:
        // Open happy "O" smile.
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(faceCenter.dx, my + faceRadius * 0.04),
              width: faceRadius * 0.28,
              height: faceRadius * 0.26),
          Paint()..color = AppColors.ink,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(faceCenter.dx, my + faceRadius * 0.10),
              width: faceRadius * 0.16,
              height: faceRadius * 0.12),
          Paint()..color = AppColors.coral,
        );
        break;
      case MascotMood.happy:
      case MascotMood.sleepy:
        path
          ..moveTo(faceCenter.dx - faceRadius * 0.02, my)
          ..quadraticBezierTo(faceCenter.dx - faceRadius * 0.16,
              my + faceRadius * 0.14, faceCenter.dx - faceRadius * 0.24, my);
        path
          ..moveTo(faceCenter.dx + faceRadius * 0.02, my)
          ..quadraticBezierTo(faceCenter.dx + faceRadius * 0.16,
              my + faceRadius * 0.14, faceCenter.dx + faceRadius * 0.24, my);
        canvas.drawPath(path, mouth);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BunnyPainter old) =>
      old.blink != blink || old.mood != mood;
}
