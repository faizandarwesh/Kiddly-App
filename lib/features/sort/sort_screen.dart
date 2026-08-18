import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_gradient.dart';
import '../../core/widgets/bouncy.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/activity_header.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';
import '../../data/content.dart';

/// Sort It: put the shuffled tiles back in order.
///
/// A small batch of letters (A–E, F–J, …) or numbers (1–5, 6–10) arrives
/// jumbled in the tray; the child drops — or simply taps — them into the row
/// of slots, left to right, in the right order. Only the next tile in the
/// sequence is accepted, so the activity *is* the alphabet song and the
/// counting rhyme, turned into something you do with your hands.
///
/// Wrong tiles are never punished: they wiggle, the voice says which one comes
/// next, and the child tries again.
class SortScreen extends StatefulWidget {
  const SortScreen({super.key});

  @override
  State<SortScreen> createState() => _SortScreenState();
}

enum _SortMode { letters, numbers }

/// One sortable tile: what it shows, what it says, what it looks like.
class _Token {
  final String label; // 'A' or '7' — also the identity used while dragging
  final String glyph; // a small picture hint
  final String spoken;
  final Color accent;
  const _Token(this.label, this.glyph, this.spoken, this.accent);
}

class _SortScreenState extends State<SortScreen> {
  final _rng = math.Random();

  _SortMode _mode = _SortMode.letters;
  int _round = 0;

  late List<_Token> _target; // the correct order for this round
  late List<_Token> _tray; // still to be placed, shuffled
  final List<_Token> _placed = [];

  String _wrongLabel = '';
  int _wrongTick = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _deal(announce: true);
  }

  @override
  void dispose() {
    AudioService.instance.stopVoice();
    super.dispose();
  }

  // ----- rounds -----

  /// Every round of a mode: letters go five at a time (the last round takes
  /// the six leftovers, U–Z), numbers go 1–5 then 6–10.
  List<List<_Token>> get _rounds {
    if (_mode == _SortMode.numbers) {
      final all = Content.numbers
          .map((n) => _Token('${n.number}', n.glyph, n.name, n.accent))
          .toList();
      return [all.sublist(0, 5), all.sublist(5)];
    }
    final all = Content.alphabet
        .map((l) => _Token(l.letter!, l.glyph, '${l.letter}. ${l.name}',
            l.accent))
        .toList();
    return [
      for (var i = 0; i < 4; i++) all.sublist(i * 5, i * 5 + 5),
      all.sublist(20), // U V W X Y Z
    ];
  }

  void _deal({bool announce = false}) {
    final rounds = _rounds;
    _round = _round % rounds.length;
    _target = rounds[_round];
    _tray = List.of(_target)..shuffle(_rng);
    // A shuffle that happens to come out already in order robs the child of
    // the game, so reshuffle until something is genuinely out of place.
    var guard = 0;
    bool alreadySorted() {
      for (var i = 0; i < _tray.length; i++) {
        if (_tray[i].label != _target[i].label) return false;
      }
      return true;
    }

    while (guard++ < 8 && _tray.length > 1 && alreadySorted()) {
      _tray.shuffle(_rng);
    }
    _placed.clear();
    _wrongLabel = '';
    _busy = false;
    setState(() {});
    if (announce) _sayGoal();
  }

  void _sayGoal() {
    final what = _mode == _SortMode.numbers ? 'numbers' : 'letters';
    AudioService.instance.say(
        'Put the $what in order. Start with ${_target.first.label}.');
  }

  void _setMode(_SortMode mode) {
    if (mode == _mode) return;
    Haptics.tap();
    setState(() {
      _mode = mode;
      _round = 0;
    });
    _deal(announce: true);
  }

  // ----- play -----

  _Token? get _expected =>
      _placed.length < _target.length ? _target[_placed.length] : null;

  Future<void> _place(String label, [Offset? at]) async {
    if (_busy) return;
    final expected = _expected;
    if (expected == null) return;

    if (label != expected.label) {
      // Gentle correction — wiggle the tile and remind them what comes next.
      Haptics.tap();
      AudioService.instance.sfx(Sfx.nudge);
      AudioService.instance.say('Not yet! Find ${expected.label}.');
      setState(() {
        _wrongLabel = label;
        _wrongTick++;
      });
      return;
    }

    Haptics.pop();
    AudioService.instance.sfx(Sfx.sparkle);
    AudioService.instance.say(expected.spoken);
    if (at != null) {
      SparkleBurst.at(context, at, color: expected.accent, count: 12);
    }
    setState(() {
      _placed.add(expected);
      _tray.removeWhere((t) => t.label == expected.label);
      _wrongLabel = '';
    });

    if (_placed.length == _target.length) {
      _busy = true;
      ProfileService.instance.awardStars(2);
      ProfileService.instance.markCompleted('sort');
      await Future.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      Celebration.play(context, say: 'All in order! Amazing!');
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      _round++;
      _deal(announce: true);
    }
  }

  // ----- ui -----

  @override
  Widget build(BuildContext context) {
    final expected = _expected;
    return Scaffold(
      body: AnimatedGradient(
        palettes: const [
          [Color(0xFFE7F0FF), Color(0xFFFFF3D6)],
          [Color(0xFFFFE9F3), Color(0xFFE7F0FF)],
          [Color(0xFFE7FBE8), Color(0xFFFFECEC)],
        ],
        child: SafeArea(
          child: Column(
            children: [
              ActivityHeader(
                title: 'Sort It!',
                onHome: () => Navigator.of(context).pop(),
                trailing: RoundButton(
                  icon: Icons.volume_up_rounded,
                  semanticLabel: 'Say it again',
                  onTap: _sayGoal,
                ),
              ),
              // ABC / 123 switch.
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeChip(
                      emoji: '🔤',
                      label: 'ABC',
                      selected: _mode == _SortMode.letters,
                      onTap: () => _setMode(_SortMode.letters),
                    ),
                    const SizedBox(width: 12),
                    _ModeChip(
                      emoji: '🔢',
                      label: '123',
                      selected: _mode == _SortMode.numbers,
                      onTap: () => _setMode(_SortMode.numbers),
                    ),
                  ],
                ),
              ),
              // What we are looking for right now.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: expected == null
                      ? const Text('Perfect! 🎉',
                          key: ValueKey('done'),
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900))
                      : Row(
                          key: ValueKey('next${expected.label}'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Next comes ',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: expected.accent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(expected.label,
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                ),
              ),
              // The row of slots. The whole row is one big, forgiving drop
              // target — a tile always lands in the next empty slot, so the
              // child only has to choose the right tile, not aim.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (_) => true,
                  onAcceptWithDetails: (d) => _place(d.data, d.offset),
                  builder: (context, candidate, rejected) {
                    return LayoutBuilder(
                      builder: (context, box) {
                        final n = _target.length;
                        // Each slot carries 8px of horizontal padding, so the
                        // row needs n * (w + 8). Shrink the slots to whatever
                        // actually fits rather than overflowing the row.
                        final w = math.min(88.0, (box.maxWidth - n * 8) / n);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < n; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                child: _Slot(
                                  size: w,
                                  token: i < _placed.length ? _placed[i] : null,
                                  ghost: _target[i],
                                  active: i == _placed.length,
                                  hovered: i == _placed.length &&
                                      candidate.isNotEmpty,
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              // The jumbled tray.
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final t in _tray)
                          _TrayTile(
                            token: t,
                            shakeTick: _wrongLabel == t.label ? _wrongTick : 0,
                            onTap: (pos) => _place(t.label, pos),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Drag or tap a tile into the row',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink.withValues(alpha: 0.45)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One position in the answer row: an outlined ghost until it is filled.
class _Slot extends StatelessWidget {
  final double size;
  final _Token? token;
  final _Token ghost;
  final bool active;
  final bool hovered;

  const _Slot({
    required this.size,
    required this.token,
    required this.ghost,
    required this.active,
    required this.hovered,
  });

  @override
  Widget build(BuildContext context) {
    final filled = token != null;
    final glow = active && hovered;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      // Deliberately NOT an overshooting curve (easeOutBack and friends).
      // AnimatedContainer lerps the whole decoration, and an overshoot drives
      // t past 1.0, which scales shadow blur radii negative — a dart:ui
      // assertion, not a cosmetic glitch.
      curve: Curves.easeOut,
      width: size,
      height: size * 1.12,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: filled
              ? token!.accent
              : (active
                  ? (hovered ? const Color(0xFF56C860) : ghost.accent)
                  : Colors.white),
          width: filled ? 4 : (active ? 4 : 3),
        ),
        // A slot with no glow gets a *transparent* shadow rather than none:
        // fading a shadow list to null is what crashed when a finished round
        // was re-dealt and every slot dropped its glow in the same frame.
        boxShadow: [
          BoxShadow(
            color: (filled ? token!.accent : ghost.accent).withValues(
                alpha: (filled || active) ? (glow ? 0.6 : 0.35) : 0.0),
            blurRadius: glow ? 18 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: filled
          ? FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(token!.label,
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: token!.accent)),
                    Text(token!.glyph, style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            )
          : Text(
              active ? '?' : '',
              style: TextStyle(
                fontSize: size * 0.44,
                fontWeight: FontWeight.w900,
                color: ghost.accent.withValues(alpha: 0.5),
              ),
            ),
    );
  }
}

/// A shuffled tile waiting in the tray — draggable, and tappable for the
/// children whose fingers can't drag yet.
class _TrayTile extends StatefulWidget {
  final _Token token;
  final int shakeTick;
  final void Function(Offset globalPosition) onTap;

  const _TrayTile({
    required this.token,
    required this.shakeTick,
    required this.onTap,
  });

  @override
  State<_TrayTile> createState() => _TrayTileState();
}

class _TrayTileState extends State<_TrayTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant _TrayTile old) {
    super.didUpdateWidget(old);
    if (widget.shakeTick != old.shakeTick && widget.shakeTick != 0) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 92.0;
    final card = Container(
      width: size,
      height: size * 1.1,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.token.accent,
            Color.lerp(widget.token.accent, Colors.black, 0.18)!,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: widget.token.accent.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.token.label,
              style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text(widget.token.glyph, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final dx =
            math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Draggable<String>(
        data: widget.token.label,
        feedback: Transform.scale(
          scale: 1.2,
          child: Material(color: Colors.transparent, child: card),
        ),
        childWhenDragging: Opacity(opacity: 0.28, child: card),
        child: Builder(
          builder: (context) => GestureDetector(
            onTapUp: (d) => widget.onTap(d.globalPosition),
            child: card,
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.grape : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
