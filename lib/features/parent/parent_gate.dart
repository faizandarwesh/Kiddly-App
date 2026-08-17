import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'parent_zone_screen.dart';

/// A small, unobtrusive button that opens the adult-only Parent Zone — but only
/// after a "press and hold" challenge a toddler is unlikely to complete by
/// accident.
class ParentGateButton extends StatelessWidget {
  const ParentGateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Parents',
      button: true,
      child: GestureDetector(
        onTap: () => _showGate(context),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline_rounded,
              color: Color(0xFF6B5AA0), size: 24),
        ),
      ),
    );
  }

  void _showGate(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _HoldGateDialog(),
    ).then((ok) {
      if (ok == true && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ParentZoneScreen()),
        );
      }
    });
  }
}

/// The adult verification: hold the button for 3 seconds. Releasing early
/// resets. Simple, accessible, and effective against accidental toddler taps.
class _HoldGateDialog extends StatefulWidget {
  const _HoldGateDialog();

  @override
  State<_HoldGateDialog> createState() => _HoldGateDialogState();
}

class _HoldGateDialogState extends State<_HoldGateDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Navigator.of(context).pop(true);
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👩‍👧 Grown-ups only',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Press and hold the button\nfor 3 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTapDown: (_) => _c.forward(),
              onTapUp: (_) => _c.reverse(),
              onTapCancel: () => _c.reverse(),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: _c.value,
                            strokeWidth: 8,
                            backgroundColor: Colors.black12,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.grape),
                          ),
                        ),
                        Container(
                          width: 92,
                          height: 92,
                          decoration: const BoxDecoration(
                            color: AppColors.grape,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.touch_app_rounded,
                              color: Colors.white, size: 40),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
