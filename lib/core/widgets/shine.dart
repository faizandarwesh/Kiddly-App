import 'package:flutter/material.dart';

/// Periodically sweeps a soft diagonal light band across [child] — a subtle,
/// glossy "toy plastic" sheen. The band is masked to the child's shape.
class Shine extends StatefulWidget {
  final Widget child;
  final Duration period;
  final Duration delay;
  final BorderRadius borderRadius;

  const Shine({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 5),
    this.delay = Duration.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  // The sheen only shows during the first third of the loop,
                  // then rests — so it flashes by rather than sliding always.
                  final active = _c.value < 0.33;
                  if (!active) return const SizedBox.shrink();
                  final p = _c.value / 0.33; // 0..1
                  return FractionallySizedBox(
                    widthFactor: 0.4,
                    alignment: Alignment(-1.6 + p * 3.2, 0),
                    child: Transform.rotate(
                      angle: 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.35),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
