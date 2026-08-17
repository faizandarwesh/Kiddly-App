import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/round_button.dart';

/// Colors world: "Can you find red?" A handful of colorful blobs appear; the
/// child taps the matching one. Correct → celebration + star. Wrong → a gentle
/// wiggle and an encouraging "Try again!" — never a failure state.
class ColorsScreen extends StatefulWidget {
  const ColorsScreen({super.key});

  @override
  State<ColorsScreen> createState() => _ColorsScreenState();
}

class _ColorsScreenState extends State<ColorsScreen> {
  final _rng = math.Random();
  late NamedColor _target;
  late List<NamedColor> _options;
  int _correctCount = 0;
  int _wrongIndex = -1;
  int _wrongTick = 0;

  @override
  void initState() {
    super.initState();
    _newRound(speakGreeting: true);
  }

  void _newRound({bool speakGreeting = false}) {
    final all = List<NamedColor>.from(AppColors.namedColors)..shuffle(_rng);
    final count = 3 + _rng.nextInt(2); // 3 or 4 options
    _options = all.take(count).toList();
    _target = _options[_rng.nextInt(_options.length)];
    _wrongIndex = -1;
    setState(() {});
    _askVoice();
  }

  void _askVoice() =>
      AudioService.instance.say('Can you find ${_target.name}?');

  void _onTap(int index) {
    final chosen = _options[index];
    if (chosen.name == _target.name) {
      _correctCount++;
      ProfileService.instance.awardStars(1);
      if (_correctCount % 5 == 0) {
        ProfileService.instance.markCompleted('colors');
      }
      Celebration.play(context, say: '${_target.name}! Great job!');
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _newRound();
      });
    } else {
      // Gentle, no-punishment feedback + a hint.
      Haptics.tap();
      AudioService.instance.sfx(Sfx.nudge);
      AudioService.instance.say('Try again! Find ${_target.name}.');
      setState(() {
        _wrongIndex = index;
        _wrongTick++;
      });
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
            colors: [Color(0xFFFFF3D6), Color(0xFFFFE6F1), Color(0xFFE4ECFF)],
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
                    RoundButton(
                      icon: Icons.volume_up_rounded,
                      semanticLabel: 'Say again',
                      onTap: _askVoice,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Find ${_target.name}!',
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w900)),
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _target.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Wrap(
                      spacing: 22,
                      runSpacing: 22,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < _options.length; i++)
                          _ColorBlob(
                            named: _options[i],
                            wiggle: _wrongIndex == i ? _wrongTick : 0,
                            onTap: () => _onTap(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorBlob extends StatefulWidget {
  final NamedColor named;
  final int wiggle; // changes to trigger a wiggle
  final VoidCallback onTap;
  const _ColorBlob(
      {required this.named, required this.wiggle, required this.onTap});

  @override
  State<_ColorBlob> createState() => _ColorBlobState();
}

class _ColorBlobState extends State<_ColorBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant _ColorBlob old) {
    super.didUpdateWidget(old);
    if (widget.wiggle != old.wiggle && widget.wiggle != 0) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final shake = math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value);
          return Transform.translate(offset: Offset(shake, 0), child: child);
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: widget.named.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
            ],
          ),
        ),
      ),
    );
  }
}
