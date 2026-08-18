import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/activity_header.dart';
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

  /// Which ordinal each tapped object was given: position → 1, 2, 3, …
  ///
  /// Counting always runs in ascending order — the *next* number is handed to
  /// whichever object the child actually touches, rather than being decided by
  /// that object's position in the row. Tap the last balloon first and it
  /// becomes "One", exactly as a child counting out loud would expect.
  final Map<int, int> _counts = {};

  int get _number => _index + 1;
  int get _counted => _counts.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => AudioService.instance.say(_items[_index].name));
  }

  void _setNumber(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, _items.length - 1);
      _counts.clear();
    });
    AudioService.instance.say(_items[_index].name);
  }

  void _countOne(int position) {
    // Already counted, or the whole set is done → nothing to do.
    if (_counts.containsKey(position) || _counted >= _number) return;
    final ordinal = _counted + 1; // the next number, always ascending
    _counts[position] = ordinal;
    Haptics.pop();
    AudioService.instance.sfx(Sfx.pop);
    AudioService.instance.say(_numberWords[ordinal - 1]);
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
              ActivityHeader(
                onHome: () => Navigator.of(context).pop(),
                titleWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_number',
                        style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: item.accent)),
                    const SizedBox(width: 12),
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800)),
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
                            accent: item.accent,
                            count: _counts[i],
                            onTap: () => _countOne(i),
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
  final Color accent;

  /// The number this object was given, or null while it is still uncounted.
  final int? count;
  final VoidCallback onTap;
  const _Countable({
    required this.glyph,
    required this.accent,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counted = count != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: counted ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.elasticOut,
        child: AnimatedOpacity(
          opacity: counted ? 1.0 : 0.72,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: counted
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: counted
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
                // The badge makes the ascending order visible: the child sees
                // 1, 2, 3 land on the objects they chose, in that order.
                if (counted)
                  Positioned(
                    right: 0,
                    top: -4,
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
  }
}
