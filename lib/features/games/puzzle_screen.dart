import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/round_button.dart';
import '../../core/widgets/sparkle_burst.dart';
import '../../data/jigsaw.dart';
import '../../data/puzzle_pals.dart';

/// A full-screen jigsaw puzzle of a friendly animal, vehicle or scene.
/// A faint "ghost" of the finished picture guides the child; pieces are dragged
/// from the tray onto the board where they snap in with a sparkle. Completing a
/// pal cheers, then deals the next one — never above [_maxPieces] pieces.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  // Grid grows with the level, but never past 6 pieces: play-testing with
  // 2–5 year olds showed anything larger reads as "too hard" and they give up,
  // and it also shrinks each piece below a comfortable finger target.
  static const _maxPieces = 6;
  static const _grids = [
    [2, 2], // 4
    [2, 3], // 6
    [3, 2], // 6 — same count, fresh shape
  ];

  final _rng = math.Random();
  int _level = 0;
  late PuzzlePal _pal;
  late PuzzleScene _scene;
  late JigsawBoard _board;
  final Set<int> _placed = {};

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final grid = _grids[math.min(_level, _grids.length - 1)];
    assert(grid[0] * grid[1] <= _maxPieces, 'Puzzle grew past $_maxPieces');
    _pal = Pals.list[_level % Pals.list.length];
    // Scenes are painted, not decoded, so the picture is ready on this frame —
    // no placeholder backdrop and no hand-off flicker between puzzles.
    _scene = PalScene(_pal);
    _board = JigsawBoard.generate(grid[0], grid[1], _rng);
    _placed.clear();
    setState(() {});
  }

  Future<void> _place(JigsawPiece piece, Offset dropCenter) async {
    Haptics.pop();
    AudioService.instance.sfx(Sfx.sparkle);
    SparkleBurst.at(context, dropCenter, color: _pal.accent, count: 16);
    setState(() => _placed.add(piece.index));
    ProfileService.instance.awardStars(1);

    if (_placed.length == _board.pieces.length) {
      AudioService.instance.say('You finished ${_pal.name}! Amazing!');
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Celebration.play(context, say: '${_pal.name} is here!', voice: false);
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      setState(() => _level++);
      _deal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final placed = _placed.length;
    final total = _board.pieces.length;
    final unplaced = _board.pieces
        .where((p) => !_placed.contains(p.index))
        .toList();

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(_pal.bg1, Colors.white, 0.35)!,
              Color.lerp(_pal.bg2, Colors.white, 0.15)!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header.
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
                    Column(
                      children: [
                        Text(
                          _pal.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$placed / $total pieces',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    RoundButton(
                      icon: Icons.refresh_rounded,
                      semanticLabel: 'New puzzle',
                      onTap: _deal,
                    ),
                  ],
                ),
              ),
              // The board.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final s = math.min(c.maxWidth, c.maxHeight);
                      return Center(
                        child: SizedBox(
                          width: s,
                          height: s,
                          child: _PuzzleBoard(
                            board: _board,
                            scene: _scene,
                            placed: _placed,
                            size: s,
                            onPlace: _place,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // The piece tray.
              _Tray(pieces: unplaced, total: total, scene: _scene),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The board: ghost guide + slot outlines + placed pieces + drop targets.
// ---------------------------------------------------------------------------

class _PuzzleBoard extends StatelessWidget {
  final JigsawBoard board;
  final PuzzleScene scene;
  final Set<int> placed;
  final double size;
  final void Function(JigsawPiece, Offset) onPlace;

  const _PuzzleBoard({
    required this.board,
    required this.scene,
    required this.placed,
    required this.size,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    final cw = board.cellW * size;
    final ch = board.cellH * size;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ghost picture + empty slot outlines.
            Positioned.fill(
              child: CustomPaint(
                painter: _BoardBackPainter(scene, board, placed),
              ),
            ),
            // Placed pieces (seamless assembly). They ignore pointers so the
            // drop targets underneath always win.
            for (final p in board.pieces)
              if (placed.contains(p.index))
                Positioned(
                  left: p.bounds.left * size,
                  top: p.bounds.top * size,
                  width: p.bounds.width * size,
                  height: p.bounds.height * size,
                  child: IgnorePointer(
                    child: _PieceView(piece: p, scene: scene, factor: size),
                  ),
                ),
            // One drop target per cell.
            for (final p in board.pieces)
              Positioned(
                left: p.col * cw,
                top: p.row * ch,
                width: cw,
                height: ch,
                child: _Slot(
                  piece: p,
                  placed: placed.contains(p.index),
                  accent: scene.pal.accent,
                  onPlace: onPlace,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final JigsawPiece piece;
  final bool placed;
  final Color accent;
  final void Function(JigsawPiece, Offset) onPlace;
  const _Slot({
    required this.piece,
    required this.placed,
    required this.accent,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data == piece.index && !placed,
      onAcceptWithDetails: (d) {
        final box = context.findRenderObject() as RenderBox?;
        final center = box != null
            ? box.localToGlobal(box.size.center(Offset.zero))
            : d.offset;
        onPlace(piece, center);
      },
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: hot ? accent.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hot ? accent : Colors.transparent,
              width: 3,
            ),
          ),
        );
      },
    );
  }
}

/// Paints a faded "ghost" of the finished picture plus dashed-free slot
/// outlines for the pieces not yet placed.
class _BoardBackPainter extends CustomPainter {
  final PuzzleScene scene;
  final JigsawBoard board;
  final Set<int> placed;
  _BoardBackPainter(this.scene, this.board, this.placed);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    // Full picture, then a white wash to fade it into a soft guide.
    scene.paint(canvas, Size(s, s));
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );

    // Outline the still-empty pieces.
    final m = _scaleMatrix(s);
    for (final p in board.pieces) {
      if (placed.contains(p.index)) continue;
      canvas.drawPath(
        p.path.transform(m),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoardBackPainter old) =>
      old.placed.length != placed.length ||
      old.board != board ||
      old.scene != scene;
}

// ---------------------------------------------------------------------------
// A single piece rendered as the picture clipped to its jigsaw silhouette.
// ---------------------------------------------------------------------------

class _PieceView extends StatelessWidget {
  final JigsawPiece piece;
  final PuzzleScene scene;
  final double factor;
  const _PieceView({
    required this.piece,
    required this.scene,
    required this.factor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: piece.bounds.width * factor,
      height: piece.bounds.height * factor,
      child: CustomPaint(painter: _PiecePainter(piece, scene, factor)),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final JigsawPiece piece;
  final PuzzleScene scene;
  final double factor;
  _PiecePainter(this.piece, this.scene, this.factor);

  @override
  void paint(Canvas canvas, Size size) {
    final f = factor;
    final scaled = piece.path.transform(_scaleMatrix(f));
    final dx = -piece.bounds.left * f;
    final dy = -piece.bounds.top * f;

    // Fill the silhouette with the correct portion of the picture.
    canvas.save();
    canvas.translate(dx, dy);
    canvas.clipPath(scaled);
    scene.paint(canvas, Size(f, f));
    canvas.restore();

    // White rim for a printed-cardboard look.
    canvas.save();
    canvas.translate(dx, dy);
    canvas.drawPath(
      scaled,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, f * 0.008),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) =>
      old.piece != piece || old.factor != factor || old.scene != scene;
}

// ---------------------------------------------------------------------------
// The draggable piece tray.
// ---------------------------------------------------------------------------

/// Holds the pieces still waiting to be placed.
///
/// It floats as a rounded card with a deliberate gap under it: little hands
/// grabbing a piece at the very bottom edge of the phone kept triggering the
/// OS navigation gestures instead. Every piece is also laid out at once (up to
/// two rows, no scrolling) so a toddler never has to swipe sideways — that
/// sideways swipe was the other gesture they kept firing by accident.
class _Tray extends StatelessWidget {
  final List<JigsawPiece> pieces;

  /// The full piece count for this puzzle. Slots are sized from this rather
  /// than from [pieces], so the tray keeps one height as pieces are used up.
  final int total;
  final PuzzleScene scene;
  const _Tray({required this.pieces, required this.total, required this.scene});

  /// Clear of the home indicator / gesture bar, on top of the SafeArea inset.
  static const _liftAboveGestures = 22.0;
  static const _gap = 10.0;
  static const _maxCell = 104.0;

  @override
  Widget build(BuildContext context) {
    // Up to 3 across, then wrap to a second row — 6 in a single row would
    // shrink each piece well below a comfortable finger target.
    final perRow = total <= 3 ? total : (total / 2).ceil();
    final rows = (total / perRow).ceil();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, _liftAboveGestures),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3DC), Color(0xFFF6E2B8)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final cell = math.min(
              _maxCell,
              (c.maxWidth - _gap * (perRow - 1)) / perRow,
            );
            return SizedBox(
              height: rows * cell + _gap * (rows - 1),
              child: pieces.isEmpty
                  ? const Center(
                      child: Text('🎉', style: TextStyle(fontSize: 56)),
                    )
                  : Center(
                      // Pinned to exactly [perRow] slots wide, otherwise a
                      // roomy screen packs 3+1 instead of an even 2+2.
                      child: SizedBox(
                        width: perRow * cell + _gap * (perRow - 1),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: _gap,
                          runSpacing: _gap,
                          children: [
                            for (final p in pieces)
                              _DraggablePiece(
                                key: ValueKey(p.index),
                                piece: p,
                                scene: scene,
                                cell: cell,
                              ),
                          ],
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _DraggablePiece extends StatelessWidget {
  final JigsawPiece piece;
  final PuzzleScene scene;

  /// Side of the square slot this piece is drawn into.
  final double cell;
  const _DraggablePiece({
    super.key,
    required this.piece,
    required this.scene,
    required this.cell,
  });

  @override
  Widget build(BuildContext context) {
    // Scale by the longest side so a piece — tabs included — always fits its
    // slot, and every piece in the tray reads at the same size.
    final maxDim = math.max(piece.bounds.width, piece.bounds.height);
    final thumb = cell / maxDim;
    final big = thumb * 1.5; // grows in the hand while dragging

    return SizedBox(
      width: cell,
      height: cell,
      child: Center(
        child: Draggable<int>(
          data: piece.index,
          onDragStarted: Haptics.tap,
          feedback: Material(
            color: Colors.transparent,
            child: _PieceView(piece: piece, scene: scene, factor: big),
          ),
          childWhenDragging: SizedBox(
            width: piece.bounds.width * thumb,
            height: piece.bounds.height * thumb,
          ),
          child: _PieceView(piece: piece, scene: scene, factor: thumb),
        ),
      ),
    );
  }
}

/// A column-major 4×4 uniform-scale matrix for [Path.transform].
Float64List _scaleMatrix(double f) => Float64List.fromList([
      f, 0, 0, 0, //
      0, f, 0, 0, //
      0, 0, 1, 0, //
      0, 0, 0, 1, //
    ]);
