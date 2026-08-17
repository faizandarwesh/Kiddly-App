import 'package:flutter/material.dart';

import '../services/haptics.dart';

/// A tappable wrapper that squishes on press and springs back — the universal
/// "this is touchable and it reacts" feedback used everywhere in the app.
///
/// Touch targets are generous and the press area is forgiving, matching the
/// "assume poor motor control" guidance for toddlers.
class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;

  const Bouncy({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.86,
    this.haptic = true,
  });

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    lowerBound: 0,
    upperBound: 1,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: widget.pressedScale,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) => _c.forward();
  void _up() {
    // Spring back with a little overshoot for a lively feel.
    _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) {
        _up();
        if (widget.haptic) Haptics.tap();
        widget.onTap?.call();
      },
      onTapCancel: _up,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
