import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_gradient.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/activity_header.dart';
import '../../data/content.dart';
import '../../data/learn_item.dart';

/// Fill the Basket: drag the fruit into the basket — or just tap it, since
/// small hands often can't drag yet. Every fruit is a big named card, and the
/// ones already collected stay **visible inside the basket**, so the child can
/// see the basket filling up rather than staring at an empty prop.
class DragDropScreen extends StatefulWidget {
  const DragDropScreen({super.key});

  @override
  State<DragDropScreen> createState() => _DragDropScreenState();
}

class _DragDropScreenState extends State<DragDropScreen> {
  static const _perRound = 5;

  /// How many fruits can be shown sitting in the basket before the pile is
  /// full — beyond this the oldest slide out of view behind the rim.
  static const _visibleInBasket = 8;

  final _rng = math.Random();

  late List<LearnItem> _items; // still waiting on the tray
  final List<LearnItem> _inBasket = [];
  int _collected = 0;
  bool _basketHot = false;

  @override
  void initState() {
    super.initState();
    _refill(first: true);
  }

  @override
  void dispose() {
    AudioService.instance.stopVoice();
    super.dispose();
  }

  void _refill({bool first = false}) {
    _items =
        (List.of(Content.fruits)..shuffle(_rng)).take(_perRound).toList();
    if (!first) _inBasket.clear();
    setState(() {});
  }

  Future<void> _drop(LearnItem fruit) async {
    Haptics.pop();
    AudioService.instance.sfx(Sfx.pop);
    AudioService.instance.say('${fruit.name}! Yum!');
    setState(() {
      _items.removeWhere((f) => f.name == fruit.name);
      _inBasket.add(fruit);
      _collected++;
      _basketHot = false;
    });
    ProfileService.instance.awardStars(1);
    if (_items.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Celebration.play(context, say: 'The basket is full! Yay!');
      await Future.delayed(const Duration(milliseconds: 1600));
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
              ActivityHeader(
                title: 'Fill the Basket',
                onHome: () => Navigator.of(context).pop(),
              ),
              // Fruit tray.
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final fruit in _items)
                          _DraggableFruit(
                            fruit: fruit,
                            onTapped: () => _drop(fruit),
                          ),
                      ],
                    ),
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
                  final idx =
                      _items.indexWhere((f) => f.name == details.data);
                  if (idx != -1) _drop(_items[idx]);
                },
                builder: (context, candidate, rejected) {
                  return AnimatedScale(
                    scale: _basketHot ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: _Basket(
                      contents: _inBasket,
                      maxVisible: _visibleInBasket,
                      collected: _collected,
                      hot: _basketHot,
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// The basket itself: a woven bowl with the collected fruit resting inside it.
class _Basket extends StatelessWidget {
  final List<LearnItem> contents;
  final int maxVisible;
  final int collected;
  final bool hot;

  const _Basket({
    required this.contents,
    required this.maxVisible,
    required this.collected,
    required this.hot,
  });

  @override
  Widget build(BuildContext context) {
    // Only the most recent handful are drawn — a real basket hides the rest.
    final shown = contents.length > maxVisible
        ? contents.sublist(contents.length - maxVisible)
        : contents;

    return SizedBox(
      width: 260,
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // The fruit pile, drawn *behind* the basket front so the fruit looks
          // like it is sitting down inside the weave.
          Positioned(
            bottom: 46,
            left: 26,
            right: 26,
            child: SizedBox(
              height: 108,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 0,
                  children: [
                    for (final fruit in shown)
                      TweenAnimationBuilder<double>(
                        key: ValueKey('${fruit.name}$collected'),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        builder: (context, t, child) => Transform.translate(
                          offset: Offset(0, -60 * (1 - t)),
                          child: Transform.scale(scale: t, child: child),
                        ),
                        child: Text(fruit.glyph,
                            style: const TextStyle(fontSize: 34)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // The basket front.
          Container(
            height: 120,
            width: 240,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD9A05B), Color(0xFFA9743A)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
                bottom: Radius.circular(60),
              ),
              border: Border.all(
                color: hot ? const Color(0xFF56C860) : const Color(0xFFF3D9B6),
                width: 5,
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 14,
                    offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧺', style: TextStyle(fontSize: 46)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$collected',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A big named fruit card. Draggable for the children who can drag, tappable
/// for the ones who can't yet — both put it in the basket.
class _DraggableFruit extends StatelessWidget {
  final LearnItem fruit;
  final VoidCallback onTapped;
  const _DraggableFruit({required this.fruit, required this.onTapped});

  @override
  Widget build(BuildContext context) {
    const size = 118.0;
    final card = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: fruit.accent.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(fruit.glyph, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              child: Text(
                fruit.name,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: fruit.name,
      feedback: Transform.scale(
        scale: 1.2,
        child: Material(color: Colors.transparent, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: GestureDetector(onTap: onTapped, child: card),
    );
  }
}
