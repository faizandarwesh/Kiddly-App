import 'package:flutter/material.dart';

import 'bouncy.dart';

/// A big, friendly circular icon button — the app's only navigation control
/// style. Text-free by default so pre-readers can use it.
class RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final String? semanticLabel;

  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.size = 64,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Bouncy(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Icon(icon, size: size * 0.52, color: const Color(0xFF6B5AA0)),
        ),
      ),
    );
  }
}
