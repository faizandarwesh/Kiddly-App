import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/widgets/animated_gradient.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/round_button.dart';

/// Drag & Drop: pick up the fruit and drop it into the basket. The drop target
/// is huge and forgiving, and items only need to be released *near* the basket.
/// Fill it up to celebrate, then a fresh batch tumbles in.
class DragDropScreen extends StatefulWidget {
  const DragDropScreen({super.key});

  @override
  State<DragDropScreen> createState() => _DragDropScreenState();
}

class _DragDropScreenState extends State<DragDropScreen> {
  static const _pool = ['🍎', '🍌', '🍓', '🍇', '🍊', '🍉', '🥝', '🍒'];
  final _rng = math.Random();

  late List<String> _items;
  int _collected = 0;
  bool _basketHot = false;

  @override
  void initState() {
    super.initState();
    _refill();
  }

  void _refill() {
    _items = (List.of(_pool)..shuffle(_rng)).take(5).toList();
    setState(() {});
  }

  Future<void> _drop(int index) async {
    Haptics.pop();
    AudioService.instance.sfx(Sfx.pop);
    AudioService.instance.say('Yum!');
    setState(() {
      _items.removeAt(index);
      _collected++;
      _basketHot = false;
    });
    ProfileService.instance.awardStars(1);
    if (_items.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Celebration.play(context, say: 'The basket is full! Yay!');
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) _refill();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradient(
        palettes: const [
          [Color(0xFFFFF3D6), Color(0xFFE7FBE8)],
          [Color(0xFFFFECEC), Color(0xFFFFF3D6)],
          [Color(0xFFE7FBE8), Color(0xFFDFF3FF)],
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
                    const Text('Fill the Basket',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              // Fruit tray.
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        _DraggableFruit(emoji: _items[i]),
                    ],
                  ),
                ),
              ),
              // Basket drop target.
              DragTarget<String>(
                onWillAcceptWithDetails: (_) {
                  setState(() => _basketHot = true);
                  return true;
                },
                onLeave: (_) => setState(() => _basketHot = false),
                onAcceptWithDetails: (details) {
                  final idx = _items.indexOf(details.data);
                  if (idx != -1) _drop(idx);
                },
                builder: (context, candidate, rejected) {
                  return AnimatedScale(
                    scale: _basketHot ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 28, top: 8),
                      width: 180,
                      height: 150,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _basketHot
                              ? const Color(0xFF56C860)
                              : Colors.white,
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🧺', style: TextStyle(fontSize: 64)),
                          Text('$_collected',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraggableFruit extends StatelessWidget {
  final String emoji;
  const _DraggableFruit({required this.emoji});

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    final chip = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 44)),
    );

    return Draggable<String>(
      data: emoji,
      feedback: Transform.scale(
        scale: 1.25,
        child: Material(color: Colors.transparent, child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      // Tapping (or a quick drag onto anything) also delivers, keeping it easy.
      onDragEnd: (details) {
        if (details.wasAccepted) return;
        // If not dropped on the basket, gently ignore — no penalty.
      },
      child: chip,
    );
  }
}
