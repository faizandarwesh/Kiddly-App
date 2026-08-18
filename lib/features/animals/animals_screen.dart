import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/floaty.dart';
import '../../core/widgets/activity_header.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';
import '../../data/content.dart';
import '../../data/learn_item.dart';

/// Animals world: one big animal per letter of the alphabet, A → Z.
///
/// The child swipes sideways to move to the next letter and the next animal.
/// Each card fills the screen with the picture, the letter and the name
/// together, so the shape of the letter, the look of the animal and its name
/// are all learned in one glance. Tapping the animal makes it react and speak.
class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  final _items = Content.animalsAZ;
  final _controller = PageController();
  final Set<String> _met = {};
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _meet(_items[0], celebrate: false));
  }

  @override
  void dispose() {
    _controller.dispose();
    AudioService.instance.stopVoice();
    super.dispose();
  }

  void _meet(LearnItem a, {bool celebrate = true}) {
    AudioService.instance.say(a.voice);
    if (_met.add(a.name)) {
      ProfileService.instance.awardStars(1);
      // A little milestone every five new animals — never a fail state.
      if (celebrate && _met.length % 5 == 0 && mounted) {
        Celebration.play(context,
            say: 'You met ${_met.length} animals! Wow!');
      }
    }
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, _items.length - 1);
    if (next == _index) return;
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 340), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_index];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(item.accent, Colors.white, 0.78)!,
              Color.lerp(item.accent, Colors.white, 0.92)!,
              const Color(0xFFFFF9EC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ActivityHeader(
                title: 'Animals A–Z',
                onHome: () => Navigator.of(context).pop(),
                trailing: RoundButton(
                  icon: Icons.volume_up_rounded,
                  semanticLabel: 'Say it again',
                  onTap: () => _meet(item),
                ),
              ),
              // The A–Z progress rail: shows where in the alphabet we are.
              _AlphabetRail(
                items: _items,
                index: _index,
                onPick: (i) => _controller.jumpToPage(i),
              ),
              // One big animal per page — swipe for the next letter.
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (i) {
                    Haptics.tap();
                    setState(() => _index = i);
                    _meet(_items[i]);
                  },
                  itemBuilder: (context, i) => _AnimalCard(
                    item: _items[i],
                    onTap: () => _meet(_items[i]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundButton(
                      icon: Icons.chevron_left_rounded,
                      semanticLabel: 'Previous animal',
                      onTap: () => _go(-1),
                    ),
                    const SizedBox(width: 28),
                    Text(
                      'Swipe →',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(width: 28),
                    RoundButton(
                      icon: Icons.chevron_right_rounded,
                      semanticLabel: 'Next animal',
                      onTap: () => _go(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin horizontal A…Z strip that keeps the current letter centred, so the
/// child can see the alphabet marching along as they swipe.
class _AlphabetRail extends StatefulWidget {
  final List<LearnItem> items;
  final int index;
  final ValueChanged<int> onPick;
  const _AlphabetRail({
    required this.items,
    required this.index,
    required this.onPick,
  });

  @override
  State<_AlphabetRail> createState() => _AlphabetRailState();
}

class _AlphabetRailState extends State<_AlphabetRail> {
  static const _cell = 44.0;
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _AlphabetRail old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) _centre();
  }

  void _centre() {
    if (!_scroll.hasClients) return;
    final target = (widget.index * _cell) -
        (_scroll.position.viewportDimension / 2) +
        (_cell / 2);
    _scroll.animateTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.items.length,
        itemBuilder: (context, i) {
          final on = i == widget.index;
          final item = widget.items[i];
          return GestureDetector(
            onTap: () => widget.onPick(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _cell - 8,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? item.accent : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: item.accent.withValues(alpha: on ? 0.5 : 0.0),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Text(
                item.letter!,
                style: TextStyle(
                  fontSize: on ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  color: on ? Colors.white : AppColors.ink.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A full-page animal card: giant picture, giant letter, giant name.
class _AnimalCard extends StatefulWidget {
  final LearnItem item;
  final VoidCallback onTap;
  const _AnimalCard({required this.item, required this.onTap});

  @override
  State<_AnimalCard> createState() => _AnimalCardState();
}

class _AnimalCardState extends State<_AnimalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tapped(Offset pos) {
    Haptics.pop();
    _c.forward(from: 0);
    SparkleBurst.at(context, pos, color: widget.item.accent, count: 16);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return LayoutBuilder(
      builder: (context, box) {
        // The card claims as much of the page as it can — the whole point of
        // the redesign is that the animal is *big*. Everything inside is a
        // fraction of the card's own height, and the picture takes whatever is
        // left, so it can never overflow on a short screen.
        final cardH = math.max(160.0, box.maxHeight - 12);
        final cardW = math.min(box.maxWidth - 24, cardH * 0.88);
        return Center(
          child: GestureDetector(
            onTapUp: (d) => _tapped(d.globalPosition),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = _c.value;
                final wobble = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Transform.rotate(
                  angle: 0.05 * wobble * (t < 0.5 ? 1 : -1),
                  child: Transform.scale(scale: 1 + 0.05 * wobble, child: child),
                );
              },
              child: Container(
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: item.accent.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: cardH * 0.05),
                    // Letter badge.
                    Container(
                      width: cardH * 0.17,
                      height: cardH * 0.17,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.accent.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            item.letter!,
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // The animal itself, filling everything left over.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Floaty(
                          style: FloatyStyle.bob,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(item.glyph,
                                style: const TextStyle(fontSize: 160)),
                          ),
                        ),
                      ),
                    ),
                    // Its name, big enough to start recognising the word.
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, cardH * 0.06),
                      child: SizedBox(
                        height: cardH * 0.15,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
