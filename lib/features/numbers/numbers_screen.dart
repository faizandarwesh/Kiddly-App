import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/round_button.dart';
import '../../data/content.dart';

const _numberWords = [
  'One', 'Two', 'Three', 'Four', 'Five',
  'Six', 'Seven', 'Eight', 'Nine', 'Ten'
];

/// Numbers world: pick a number, then pop that many objects one at a time while
/// a friendly voice counts along — "One! Two! Three!" — and celebrate.
class NumbersScreen extends StatefulWidget {
  const NumbersScreen({super.key});

  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  final _items = Content.numbers;
  int _index = 2; // start at "Three" — a satisfying first count.
  int _counted = 0;

  int get _number => _index + 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => AudioService.instance.say(_items[_index].name));
  }

  void _setNumber(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, _items.length - 1);
      _counted = 0;
    });
    AudioService.instance.say(_items[_index].name);
  }

  void _countOne() {
    if (_counted >= _number) return;
    _counted++;
    Haptics.pop();
    AudioService.instance.sfx(Sfx.pop);
    AudioService.instance.say(_numberWords[_counted - 1]);
    if (_counted == _number) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        ProfileService.instance.awardStars(1);
        Celebration.play(context, say: '${_items[_index].name}! You did it!');
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_index];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDF3FF), Color(0xFFE7FBE8), Color(0xFFFFF6D9)],
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
                    Text('$_number',
                        style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: item.accent)),
                    const SizedBox(width: 12),
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < _number; i++)
                          _Countable(
                            glyph: item.glyph,
                            popped: i < _counted,
                            onTap: _countOne,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _counted == 0
                      ? 'Tap to count!'
                      : (_counted < _number ? '$_counted…' : 'Yay!'),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundButton(
                        icon: Icons.chevron_left_rounded,
                        semanticLabel: 'Fewer',
                        onTap: () => _setNumber(-1)),
                    const SizedBox(width: 40),
                    RoundButton(
                        icon: Icons.chevron_right_rounded,
                        semanticLabel: 'More',
                        onTap: () => _setNumber(1)),
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

class _Countable extends StatelessWidget {
  final String glyph;
  final bool popped;
  final VoidCallback onTap;
  const _Countable(
      {required this.glyph, required this.popped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: popped ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.elasticOut,
        child: AnimatedOpacity(
          opacity: popped ? 1.0 : 0.72,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: popped
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              boxShadow: popped
                  ? const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ]
                  : null,
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 44)),
          ),
        ),
      ),
    );
  }
}
