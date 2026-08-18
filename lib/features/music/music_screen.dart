import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/tone_synth.dart';
import '../../core/widgets/animated_gradient.dart';
import '../../core/widgets/activity_header.dart';
import '../../core/widgets/sparkle_burst.dart';

/// Music world: a rainbow xylophone plus a row of instruments. Every instrument
/// has its own synthesized *voice* (see [Timbre]) — a drum thumps, a bell
/// rings, a guitar plucks — and picking one also re-voices the whole
/// xylophone, so the choice is audible everywhere on the screen.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  // C major scale, C4 → C5.
  static const _scale = [
    _Note('C', 261.63, Color(0xFFF14B4B)),
    _Note('D', 293.66, Color(0xFFFF9A3D)),
    _Note('E', 329.63, Color(0xFFFFD23F)),
    _Note('F', 349.23, Color(0xFF56C860)),
    _Note('G', 392.00, Color(0xFF3E8EF7)),
    _Note('A', 440.00, Color(0xFF6C63FF)),
    _Note('B', 493.88, Color(0xFFA163E0)),
    _Note('C²', 523.25, Color(0xFFFF8FC7)),
  ];

  /// Each instrument carries its own timbre, its own demo pitch and its own
  /// note length — a drum is a short thump, a bell rings for a second and a
  /// half.
  static const _instruments = [
    _Instrument('🎼', 'Bars', Timbre.xylophone, 523.25, 500),
    _Instrument('🥁', 'Drum', Timbre.drum, 90.00, 420),
    _Instrument('🔔', 'Bell', Timbre.bell, 880.00, 1500),
    _Instrument('🎸', 'Guitar', Timbre.guitar, 196.00, 1100),
    _Instrument('🎺', 'Trumpet', Timbre.trumpet, 349.23, 700),
    _Instrument('🪈', 'Flute', Timbre.flute, 587.33, 900),
    _Instrument('🎹', 'Piano', Timbre.piano, 261.63, 900),
  ];

  int _selected = 0;

  /// How long a xylophone bar should ring in the currently chosen voice.
  int get _barLength => switch (_instruments[_selected].timbre) {
        Timbre.drum => 400,
        Timbre.bell => 1400,
        Timbre.guitar => 1000,
        Timbre.piano => 900,
        Timbre.flute => 800,
        Timbre.trumpet => 650,
        Timbre.xylophone => 500,
      };

  void _hitBar(_Note note, Offset pos) {
    Haptics.tap();
    final ins = _instruments[_selected];
    // A drum has no pitch to speak of — keep it low and punchy so the bars
    // still read as a drum kit rather than a squeaky beep.
    final freq = ins.timbre == Timbre.drum ? note.freq / 3 : note.freq;
    AudioService.instance
        .playInstrument(ins.timbre, freq, durationMs: _barLength);
    SparkleBurst.at(context, pos, color: note.color, count: 8);
  }

  void _pickInstrument(int i) {
    Haptics.pop();
    setState(() => _selected = i);
    final ins = _instruments[i];
    AudioService.instance
        .playInstrument(ins.timbre, ins.demoFreq, durationMs: ins.durationMs);
  }

  @override
  Widget build(BuildContext context) {
    final ins = _instruments[_selected];
    return Scaffold(
      body: AnimatedGradient(
        palettes: const [
          [Color(0xFF2E1A47), Color(0xFF4A2E6E)],
          [Color(0xFF3A2E5C), Color(0xFF6E4AA0)],
          [Color(0xFF241A47), Color(0xFF3E2E7E)],
        ],
        child: SafeArea(
          child: Column(
            children: [
              ActivityHeader(
                title: 'Music',
                titleColor: Colors.white,
                onHome: () => Navigator.of(context).pop(),
              ),
              // Which voice the bars are playing right now.
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    '${ins.emoji}  Playing the ${ins.name.toLowerCase()}',
                    key: ValueKey(_selected),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              // Xylophone.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < _scale.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _Bar(
                              note: _scale[i],
                              // Longer bars for lower notes.
                              heightFactor: 1 - i * 0.055,
                              onHit: _hitBar,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Instruments.
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _instruments.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => Center(
                    child: _InstrumentButton(
                      ins: _instruments[i],
                      selected: i == _selected,
                      onTap: () => _pickInstrument(i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note {
  final String label;
  final double freq;
  final Color color;
  const _Note(this.label, this.freq, this.color);
}

class _Instrument {
  final String emoji;
  final String name;
  final Timbre timbre;

  /// The pitch played when the instrument itself is tapped.
  final double demoFreq;
  final int durationMs;
  const _Instrument(
      this.emoji, this.name, this.timbre, this.demoFreq, this.durationMs);
}

class _Bar extends StatefulWidget {
  final _Note note;
  final double heightFactor;
  final void Function(_Note note, Offset globalPosition) onHit;
  const _Bar({
    required this.note,
    required this.heightFactor,
    required this.onHit,
  });

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  void _hit(Offset pos) {
    widget.onHit(widget.note, pos);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) => _hit(d.globalPosition),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final squish = math.sin(_c.value * math.pi);
          return Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: FractionallySizedBox(
              heightFactor: widget.heightFactor * (1 - 0.06 * squish),
              child: Transform.scale(scaleX: 1 + 0.06 * squish, child: child),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.note.color,
                Color.lerp(widget.note.color, Colors.black, 0.18)!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.note.color.withValues(alpha: 0.6),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            widget.note.label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _InstrumentButton extends StatefulWidget {
  final _Instrument ins;
  final bool selected;
  final VoidCallback onTap;
  const _InstrumentButton({
    required this.ins,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InstrumentButton> createState() => _InstrumentButtonState();
}

class _InstrumentButtonState extends State<_InstrumentButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(covariant _InstrumentButton old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _c.forward(from: 0);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final wob = math.sin(_c.value * math.pi);
          return Transform.rotate(
            angle: wob * 0.3,
            child: Transform.scale(scale: 1 + 0.2 * wob, child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.selected
                    ? Colors.white.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.selected ? Colors.white : Colors.white24,
                  width: widget.selected ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white
                        .withValues(alpha: widget.selected ? 0.5 : 0.0),
                    blurRadius: 16,
                  ),
                ],
              ),
              child:
                  Text(widget.ins.emoji, style: const TextStyle(fontSize: 34)),
            ),
            const SizedBox(height: 4),
            Text(widget.ins.name,
                style: TextStyle(
                    color: widget.selected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
