import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/animated_gradient.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';

/// Music world: a rainbow xylophone plus a row of fun instruments. Every tap
/// makes a warm synthesized note (no audio files) and a satisfying visual
/// bounce + note-burst. Pure digital-toy joy, no lesson.
class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

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

  static const _instruments = [
    _Instrument('🥁', 'Drum', 130.81, 160),
    _Instrument('🔔', 'Bell', 1046.50, 500),
    _Instrument('🎸', 'Guitar', 196.00, 500),
    _Instrument('🎺', 'Trumpet', 349.23, 460),
    _Instrument('🪈', 'Flute', 587.33, 480),
    _Instrument('🎹', 'Piano', 261.63, 420),
  ];

  @override
  Widget build(BuildContext context) {
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
                    const Text('Music',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const Spacer(),
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              // Xylophone.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Instruments.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final ins in _instruments) _InstrumentButton(ins),
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

class _Note {
  final String label;
  final double freq;
  final Color color;
  const _Note(this.label, this.freq, this.color);
}

class _Instrument {
  final String emoji;
  final String name;
  final double freq;
  final int durationMs;
  const _Instrument(this.emoji, this.name, this.freq, this.durationMs);
}

class _Bar extends StatefulWidget {
  final _Note note;
  final double heightFactor;
  const _Bar({required this.note, required this.heightFactor});

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  void _hit(Offset pos) {
    Haptics.tap();
    AudioService.instance.playNote(widget.note.freq, durationMs: 500);
    SparkleBurst.at(context, pos, color: widget.note.color, count: 8);
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
  const _InstrumentButton(this.ins);

  @override
  State<_InstrumentButton> createState() => _InstrumentButtonState();
}

class _InstrumentButtonState extends State<_InstrumentButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  void _hit() {
    Haptics.pop();
    AudioService.instance
        .playNote(widget.ins.freq, durationMs: widget.ins.durationMs);
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
      onTap: _hit,
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
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child:
                  Text(widget.ins.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 4),
            Text(widget.ins.name,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
