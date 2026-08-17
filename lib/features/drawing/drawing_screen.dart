import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bouncy.dart';
import '../../core/widgets/round_button.dart';

/// A finger-painting playground. Big canvas, chunky color dots, faint templates
/// to color inside, plus erase and clear. Forgiving and instant — every drag
/// leaves a satisfying trail.
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;
  _Stroke(this.color, this.width) : points = [];
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<_Stroke> _strokes = [];
  Color _color = AppColors.namedColors[0].color;
  final double _width = 22;
  String? _template;

  static const _templates = ['🍎', '🐱', '🚗', '🦕', '🏠', '🌸', '⭐', '🌈'];
  static const _canvasBg = Color(0xFFFFFDF6);

  void _start(Offset p) {
    Haptics.tap();
    setState(() => _strokes.add(_Stroke(_color, _width)..points.add(p)));
  }

  void _extend(Offset p) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.points.add(p));
  }

  void _clear() {
    AudioService.instance.sfx(Sfx.sparkle);
    setState(_strokes.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  RoundButton(
                    icon: Icons.home_rounded,
                    semanticLabel: 'Home',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  const Text('Draw',
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  RoundButton(
                    icon: Icons.delete_sweep_rounded,
                    semanticLabel: 'Clear',
                    onTap: _clear,
                  ),
                ],
              ),
            ),
            // Template chooser.
            SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _TemplateChip(
                    emoji: '🗒️',
                    selected: _template == null,
                    onTap: () => setState(() => _template = null),
                  ),
                  for (final t in _templates)
                    _TemplateChip(
                      emoji: t,
                      selected: _template == t,
                      onTap: () => setState(() => _template = t),
                    ),
                ],
              ),
            ),
            // Canvas.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: GestureDetector(
                    onPanStart: (d) => _start(d.localPosition),
                    onPanUpdate: (d) => _extend(d.localPosition),
                    child: CustomPaint(
                      painter: _CanvasPainter(_strokes, _template),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            // Palette + tools.
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final nc in AppColors.namedColors)
                      _Swatch(
                        color: nc.color,
                        selected: _color == nc.color,
                        onTap: () => setState(() => _color = nc.color),
                      ),
                    // Eraser paints the canvas background back on.
                    _Swatch(
                      color: _canvasBg,
                      icon: Icons.cleaning_services_rounded,
                      selected: _color == _canvasBg,
                      onTap: () => setState(() => _color = _canvasBg),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final String? template;
  _CanvasPainter(this.strokes, this.template);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = _DrawingScreenState._canvasBg);

    // Faint template to color over.
    if (template != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: template,
          style: TextStyle(
              fontSize: size.shortestSide * 0.7,
              color: Colors.black.withValues(alpha: 0.08)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    }

    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width;
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) => true;
}

class _TemplateChip extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _TemplateChip(
      {required this.emoji, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Bouncy(
        onTap: onTap,
        child: Container(
          width: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.grape : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Bouncy(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 54 : 46,
          height: selected ? 54 : 46,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.grape : Colors.white,
              width: selected ? 4 : 3,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: icon != null
              ? Icon(icon, color: Colors.black38, size: 22)
              : null,
        ),
      ),
    );
  }
}
