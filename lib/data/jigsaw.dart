import 'dart:math' as math;
import 'dart:ui';

/// One jigsaw piece. Its [path] and [bounds] live in a **unit square**
/// (0..1 × 0..1), so the same geometry renders at any board size — just scale
/// the path by the pixel size. Tabs stick out beyond the piece's grid cell, so
/// [bounds] can exceed the cell.
class JigsawPiece {
  final int index;
  final int col;
  final int row;
  final Path path;
  final Rect bounds;
  const JigsawPiece({
    required this.index,
    required this.col,
    required this.row,
    required this.path,
    required this.bounds,
  });
}

/// A generated jigsaw layout: [rows] × [cols] interlocking [pieces].
class JigsawBoard {
  final int rows;
  final int cols;
  final List<JigsawPiece> pieces;
  const JigsawBoard(
      {required this.rows, required this.cols, required this.pieces});

  double get cellW => 1 / cols;
  double get cellH => 1 / rows;

  /// Builds a fresh jigsaw with randomized tab directions.
  factory JigsawBoard.generate(int rows, int cols, math.Random rng) {
    final cw = 1 / cols, ch = 1 / rows;

    // Interior edge tab signs. Neighbours share an edge with opposite sign so
    // one side bulges out (tab) and the other in (blank).
    final hTab =
        List.generate(rows + 1, (_) => List.filled(cols, 0)); // horizontal
    final vTab =
        List.generate(rows, (_) => List.filled(cols + 1, 0)); // vertical
    for (var r = 1; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        hTab[r][c] = rng.nextBool() ? 1 : -1;
      }
    }
    for (var r = 0; r < rows; r++) {
      for (var c = 1; c < cols; c++) {
        vTab[r][c] = rng.nextBool() ? 1 : -1;
      }
    }

    final pieces = <JigsawPiece>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = c * cw, y = r * ch;
        final path = Path()..moveTo(x, y);
        // top → right → bottom → left
        _edge(path, Offset(x, y), Offset(x + cw, y), r == 0 ? 0 : hTab[r][c]);
        _edge(path, Offset(x + cw, y), Offset(x + cw, y + ch),
            c == cols - 1 ? 0 : vTab[r][c + 1]);
        _edge(path, Offset(x + cw, y + ch), Offset(x, y + ch),
            r == rows - 1 ? 0 : -hTab[r + 1][c]);
        _edge(path, Offset(x, y + ch), Offset(x, y),
            c == 0 ? 0 : -vTab[r][c]);
        path.close();
        pieces.add(JigsawPiece(
          index: r * cols + c,
          col: c,
          row: r,
          path: path,
          bounds: path.getBounds(),
        ));
      }
    }
    return JigsawBoard(rows: rows, cols: cols, pieces: pieces);
  }

  /// Appends one jigsaw edge from [a] to [b]. [s] = 0 flat, ±1 = tab/blank.
  static void _edge(Path p, Offset a, Offset b, int s) {
    if (s == 0) {
      p.lineTo(b.dx, b.dy);
      return;
    }
    final e = b - a;
    final len = e.distance;
    final u = e / len; // along the edge
    final n = Offset(-u.dy, u.dx); // left-hand normal
    Offset at(double t, double off) => a + u * (len * t) + n * off;
    final o = 0.20 * len * s; // knob height

    p.lineTo(at(0.35, 0).dx, at(0.35, 0).dy);
    // Up onto the knob.
    p.cubicTo(at(0.43, 0).dx, at(0.43, 0).dy, at(0.36, o).dx, at(0.36, o).dy,
        at(0.5, o).dx, at(0.5, o).dy);
    // Down off the knob.
    p.cubicTo(at(0.64, o).dx, at(0.64, o).dy, at(0.57, 0).dx, at(0.57, 0).dy,
        at(0.65, 0).dx, at(0.65, 0).dy);
    p.lineTo(b.dx, b.dy);
  }
}
