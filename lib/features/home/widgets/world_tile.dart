import 'package:flutter/material.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/widgets/bouncy.dart';
import '../../../core/widgets/floaty.dart';
import '../../../core/widgets/shine.dart';

/// A world on the dashboard, styled to match the premium "storybook" look:
/// either a glossy gradient **squircle** or a glassy translucent **bubble**,
/// with a soft translucent **pill label** tucked under it. Pops in with a
/// subtle bounce (staggered by [index]) then breathes with a gentle float.
class WorldTile extends StatefulWidget {
  final String emoji;
  final String label;
  final List<Color> gradient;
  final int index;
  final bool bubble;
  final double iconSize;
  final VoidCallback onOpen;

  const WorldTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.index,
    required this.onOpen,
    this.bubble = false,
    this.iconSize = 118,
  });

  @override
  State<WorldTile> createState() => _WorldTileState();
}

class _WorldTileState extends State<WorldTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  Duration get _delay => Duration(milliseconds: 85 * widget.index);

  @override
  void initState() {
    super.initState();
    Future.delayed(_delay, () {
      if (mounted) _in.forward();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  void _tap() {
    AudioService.instance.say(widget.label);
    Future.delayed(const Duration(milliseconds: 220), widget.onOpen);
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _in, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(
      parent: _in,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    final s = widget.iconSize;

    return AnimatedBuilder(
      animation: _in,
      builder: (context, child) => Opacity(
        opacity: fade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - pop.value) * 26),
          child: Transform.scale(
            scale: (0.55 + 0.45 * pop.value).clamp(0.0, 1.15),
            child: child,
          ),
        ),
      ),
      child: Floaty(
        style: FloatyStyle.bob,
        period: const Duration(seconds: 4),
        delay: _delay + const Duration(milliseconds: 560),
        amplitude: 0.5,
        child: Bouncy(
          onTap: _tap,
          child: SizedBox(
            width: s,
            height: s + 20,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Icon.
                widget.bubble ? _bubbleIcon(s) : _squircleIcon(s),
                // Pill label, tucked under and slightly overlapping the icon.
                Positioned(
                  bottom: 0,
                  child: _pillLabel(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _squircleIcon(double s) {
    return Shine(
      period: const Duration(seconds: 7),
      delay: Duration(milliseconds: 500 * (widget.index % 4)),
      borderRadius: BorderRadius.circular(s * 0.28),
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradient,
          ),
          borderRadius: BorderRadius.circular(s * 0.28),
          boxShadow: [
            BoxShadow(
              color: widget.gradient.last.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Center(
          child: Text(widget.emoji, style: TextStyle(fontSize: s * 0.44)),
        ),
      ),
    );
  }

  Widget _bubbleIcon(double s) {
    final tint = widget.gradient.last;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFBFE6FF).withValues(alpha: 0.55),
            tint.withValues(alpha: 0.30),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7FB8E8).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Center(
        child: Text(widget.emoji, style: TextStyle(fontSize: s * 0.4)),
      ),
    );
  }

  Widget _pillLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3B30).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        widget.label.toUpperCase(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
          shadows: [
            Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}
