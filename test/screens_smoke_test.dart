import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kiddly/features/animals/animals_screen.dart';
import 'package:kiddly/features/bubbles/bubble_screen.dart';
import 'package:kiddly/features/fruits/fruits_screen.dart';
import 'package:kiddly/features/games/drag_drop_screen.dart';
import 'package:kiddly/features/music/music_screen.dart';
import 'package:kiddly/features/numbers/numbers_screen.dart';
import 'package:kiddly/features/sort/sort_screen.dart';
import 'package:kiddly/features/vehicles/vehicles_screen.dart';

/// Every activity is played on wildly different phones, so each screen is
/// pumped at a small, a tall and a tablet-ish size. A layout overflow or a
/// build error surfaces here rather than on a child's screen.
const _sizes = [
  Size(320, 568), // small phone
  Size(390, 844), // typical phone
  Size(800, 1200), // tablet
];

Future<void> _pumpAt(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  // Long enough to drain staggered entrance timers (the Food grid's last tile
  // is delayed 660ms) — a leftover Timer fails the test on teardown.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }
}

void main() {
  final screens = <String, Widget Function()>{
    'bubbles': () => const BubbleScreen(),
    'animals': () => const AnimalsScreen(),
    'numbers': () => const NumbersScreen(),
    'sort': () => const SortScreen(),
    'basket': () => const DragDropScreen(),
    'food': () => const FruitsScreen(),
    'vehicles': () => const VehiclesScreen(),
    'music': () => const MusicScreen(),
  };

  for (final entry in screens.entries) {
    for (final size in _sizes) {
      testWidgets('${entry.key} builds at ${size.width}x${size.height}',
          (tester) async {
        await _pumpAt(tester, entry.value(), size);
      });
    }
  }
}
