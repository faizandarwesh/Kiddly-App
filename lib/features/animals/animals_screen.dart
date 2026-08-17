import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bouncy.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';
import '../../data/content.dart';
import '../../data/learn_item.dart';

/// Animals world: pick a habitat, tap an animal to hear its name and sound and
/// watch it react. Each new animal discovered earns a star.
class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  final _groups = Content.animalGroups;
  final Set<String> _met = {};
  late String _group = _groups.first;

  static const _groupEmoji = {
    'Farm': '🚜',
    'Jungle': '🌴',
    'Ocean': '🌊',
    'Pets': '🏠',
    'Dino': '🦕',
  };

  List<LearnItem> get _visible =>
      Content.animals.where((a) => a.group == _group).toList();

  void _tap(LearnItem a, Offset pos) {
    AudioService.instance.say(a.voice);
    SparkleBurst.at(context, pos, color: a.accent, count: 12);
    if (_met.add(a.name)) {
      ProfileService.instance.awardStars(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F7DF), Color(0xFFDFF3FF), Color(0xFFFFF3D6)],
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
                    const Text('Animals',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final g in _groups)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _GroupChip(
                          label: g,
                          emoji: _groupEmoji[g] ?? '🐾',
                          selected: g == _group,
                          onTap: () => setState(() => _group = g),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    for (final a in _visible)
                      _AnimalCard(item: a, onTap: (pos) => _tap(a, pos)),
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

class _GroupChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _GroupChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.grape : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalCard extends StatefulWidget {
  final LearnItem item;
  final void Function(Offset globalPosition) onTap;
  const _AnimalCard({required this.item, required this.onTap});

  @override
  State<_AnimalCard> createState() => _AnimalCardState();
}

class _AnimalCardState extends State<_AnimalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
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
          final wobble = (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Transform.rotate(
            angle: 0.12 * wobble * (t < 0.5 ? 1 : -1),
            child: Transform.scale(scale: 1 + 0.15 * wobble, child: child),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: widget.item.accent.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.item.glyph, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 4),
              Text(
                widget.item.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
