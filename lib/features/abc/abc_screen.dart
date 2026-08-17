import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bouncy.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/floaty.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';
import '../../data/content.dart';
import '../../data/learn_item.dart';

/// ABC world: swipe through the alphabet. Each letter is a big, friendly,
/// tappable card that reveals its word and speaks it — discovery, not drilling.
class AbcScreen extends StatefulWidget {
  const AbcScreen({super.key});

  @override
  State<AbcScreen> createState() => _AbcScreenState();
}

class _AbcScreenState extends State<AbcScreen> {
  final _controller = PageController();
  final _items = Content.alphabet;
  final Set<String> _discovered = {};
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Greet the first letter shortly after arrival.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak(_items[0]));
  }

  void _speak(LearnItem item) => AudioService.instance.say(item.voice);

  void _onDiscover(LearnItem item) {
    _speak(item);
    if (_discovered.add(item.letter!)) {
      ProfileService.instance.awardStars(1);
      // Celebrate every 5 new letters as a little milestone.
      if (_discovered.length % 5 == 0) {
        Celebration.play(context,
            say: 'You found ${_discovered.length} letters! Wow!');
      }
    }
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, _items.length - 1);
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE1EC), Color(0xFFEDE1FF), Color(0xFFDFF3FF)],
          ),
        ),
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
                      onTap: () {
                        AudioService.instance.stopVoice();
                        Navigator.of(context).pop();
                      },
                    ),
                    const Spacer(),
                    const Text('ABC',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    _speak(_items[i]);
                  },
                  itemBuilder: (context, i) => _LetterCard(
                    item: _items[i],
                    onTap: () => _onDiscover(_items[i]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundButton(
                      icon: Icons.chevron_left_rounded,
                      semanticLabel: 'Previous',
                      onTap: () => _go(-1),
                    ),
                    const SizedBox(width: 40),
                    RoundButton(
                      icon: Icons.chevron_right_rounded,
                      semanticLabel: 'Next',
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

class _LetterCard extends StatelessWidget {
  final LearnItem item;
  final VoidCallback onTap;
  const _LetterCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            return GestureDetector(
              onTapUp: (d) {
                onTap();
                SparkleBurst.at(context, d.globalPosition,
                    color: item.accent, count: 14);
              },
              child: Bouncy(
                onTap: () {},
                child: Container(
                  width: 220,
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(48),
                    boxShadow: [
                      BoxShadow(
                        color: item.accent.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Text(
                    item.letter!,
                    style: TextStyle(
                      fontSize: 150,
                      fontWeight: FontWeight.w900,
                      color: item.accent,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 28),
          Floaty(
            style: FloatyStyle.bob,
            child: Text(item.glyph, style: const TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: const TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
