import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/widgets/animated_gradient.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';
import '../../core/widgets/tappable_tile.dart';
import '../../data/content.dart';

/// Fruits & Food world: a colorful pantry of tappable treats. Each tap makes
/// the fruit squish and burst with juice-colored sparkles while a voice names
/// it. Discovering each one for the first time earns a star.
class FruitsScreen extends StatefulWidget {
  const FruitsScreen({super.key});

  @override
  State<FruitsScreen> createState() => _FruitsScreenState();
}

class _FruitsScreenState extends State<FruitsScreen> {
  final _items = Content.fruits;
  final Set<String> _tasted = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradient(
        palettes: const [
          [Color(0xFFFFF0D6), Color(0xFFFFE0EC)],
          [Color(0xFFFFE8D6), Color(0xFFFFF6D9)],
          [Color(0xFFFFECEC), Color(0xFFFDE7FF)],
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
                      onTap: () {
                        AudioService.instance.stopVoice();
                        Navigator.of(context).pop();
                      },
                    ),
                    const Spacer(),
                    const Text('Yummy Food',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    const SizedBox(width: 64),
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
                    for (var i = 0; i < _items.length; i++)
                      Entrance(
                        delay: Duration(milliseconds: 60 * i),
                        child: TappableTile(
                          emoji: _items[i].glyph,
                          label: _items[i].name,
                          accent: _items[i].accent,
                          onTap: (pos) {
                            AudioService.instance.sfx(Sfx.pop);
                            AudioService.instance.say(_items[i].voice);
                            SparkleBurst.at(context, pos,
                                color: _items[i].accent, count: 14);
                            if (_tasted.add(_items[i].name)) {
                              ProfileService.instance.awardStars(1);
                            }
                          },
                        ),
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
