import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/haptics.dart';
import '../../core/services/profile_service.dart';
import '../../core/widgets/bouncy.dart';
import '../../core/widgets/floaty.dart';
import '../../core/widgets/activity_header.dart';
import '../../data/content.dart';
import '../../data/learn_item.dart';

/// Vehicles world: a big stage with sky, hills and a road. Tap a vehicle from
/// the tray and watch it zoom across — planes fly up high, boats bob on a wave,
/// cars race along the road — each with its own sound.
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen>
    with SingleTickerProviderStateMixin {
  final _items = Content.vehicles;
  final Set<String> _seen = {};

  late final AnimationController _drive;

  LearnItem? _active;

  @override
  void initState() {
    super.initState();
    _drive = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  void _launch(LearnItem v) {
    Haptics.pop();
    AudioService.instance.say(v.voice);
    setState(() => _active = v);
    _drive.forward(from: 0);
    if (_seen.add(v.name)) ProfileService.instance.awardStars(1);
  }

  @override
  void dispose() {
    _drive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9BD6FF), Color(0xFFCDEBFF), Color(0xFFE9FBE6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ActivityHeader(
                title: 'Vehicles',
                onHome: () => Navigator.of(context).pop(),
              ),
              // The moving stage.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    return Stack(
                      children: [
                        // Decorative sun & clouds.
                        const Positioned(
                          right: 24,
                          top: 8,
                          child: Floaty(
                            style: FloatyStyle.pulse,
                            child: Text('☀️', style: TextStyle(fontSize: 56)),
                          ),
                        ),
                        const Positioned(
                          left: 30,
                          top: 20,
                          child: Floaty(
                            style: FloatyStyle.sway,
                            period: Duration(seconds: 7),
                            child: Text('☁️', style: TextStyle(fontSize: 48)),
                          ),
                        ),
                        // Road.
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: box.maxHeight * 0.10,
                          child: Container(
                            height: 6,
                            color: Colors.brown.shade200,
                          ),
                        ),
                        // The travelling vehicle.
                        if (_active != null)
                          AnimatedBuilder(
                            animation: _drive,
                            builder: (context, _) =>
                                _positioned(_active!, _drive.value, box.biggest),
                          ),
                        if (_active == null)
                          const Center(
                            child: Text('Tap a vehicle to go! 👇',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black45)),
                          ),
                        // Name the vehicle that is currently zooming past.
                        if (_active != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 12,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  _active!.name,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: _active!.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              // The tray of vehicles.
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => Center(
                    child: Bouncy(
                      onTap: () => _launch(_items[i]),
                      child: Container(
                        width: 84,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: _items[i].accent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_items[i].glyph,
                                style: const TextStyle(fontSize: 40)),
                            Text(_items[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  /// How big the travelling vehicle should be drawn. The stage is mostly empty
  /// sky, so the vehicle is sized from the stage itself — roughly a third of
  /// its height — instead of a fixed, tiny 64px.
  static double _vehicleSize(Size stage) =>
      (stage.height * 0.38).clamp(120.0, 240.0).toDouble();

  /// Places the vehicle emoji along a path appropriate to how it travels.
  Widget _positioned(LearnItem v, double t, Size size) {
    final glyphSize = _vehicleSize(size);
    // Start and finish fully off-screen, whatever the vehicle's size.
    final x = -glyphSize + t * (size.width + glyphSize * 2);
    double y; // vertical centre of the vehicle
    double angle = 0;
    switch (v.group) {
      case 'air':
        // Fly up and across in a gentle arc.
        y = size.height * 0.52 - math.sin(t * math.pi) * size.height * 0.30;
        angle = -0.15;
        break;
      case 'water':
        // Bob along a wave near the lower third.
        y = size.height * 0.66 + math.sin(t * math.pi * 4) * 12;
        break;
      default: // ground
        // Sit the wheels on the road line (10% up from the bottom).
        y = size.height * 0.90 - glyphSize * 0.42;
        // A tiny bounce as it drives.
        y -= (math.sin(t * math.pi * 8).abs()) * 8;
    }
    Widget art = Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: glyphSize,
        height: glyphSize,
        child: FittedBox(
          child: Text(v.glyph, style: const TextStyle(fontSize: 120)),
        ),
      ),
    );
    // Vehicles travel left → right, but most of the emoji are drawn facing
    // left, so they appeared to drive backwards. Mirror those. The flip sits
    // *outside* the rotation on purpose: mirroring the whole thing also mirrors
    // the tilt, which keeps the aeroplane's nose pointing up as it climbs.
    if (v.facesLeft) {
      art = Transform.flip(flipX: true, child: art);
    }
    return Positioned(left: x, top: y - glyphSize / 2, child: art);
  }
}
