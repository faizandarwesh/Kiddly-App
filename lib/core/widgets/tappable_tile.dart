import 'package:flutter/material.dart';

/// A rounded white card showing a big emoji + label that squishes and wobbles
/// when tapped. Reports the tap's global position so the caller can spawn a
/// sparkle burst there. Used across discovery grids (fruits, animals, …).
class TappableTile extends StatefulWidget {
  final String emoji;
  final String label;
  final Color accent;
  final double emojiSize;
  final void Function(Offset globalPosition) onTap;

  const TappableTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.accent,
    required this.onTap,
    this.emojiSize = 52,
  });

  @override
  State<TappableTile> createState() => _TappableTileState();
}

class _TappableTileState extends State<TappableTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (d) {
        _c.forward(from: 0);
        widget.onTap(d.globalPosition);
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          final wobble = t < 0.5 ? t * 2 : (1 - t) * 2; // 0→1→0
          // Squish horizontally then spring, with a small rotation.
          return Transform.rotate(
            angle: 0.12 * wobble * (t < 0.5 ? 1 : -1),
            child: Transform.scale(
              scaleX: 1 + 0.18 * wobble,
              scaleY: 1 - 0.10 * wobble,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // Both children shrink to fit rather than overflow: these tiles sit
          // in square grid cells whose height varies with the phone, and the
          // label grows with the parent's text-scale setting.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.emoji,
                      style: TextStyle(fontSize: widget.emojiSize)),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
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
