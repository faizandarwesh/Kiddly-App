import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kiddly/data/content.dart';
import 'package:kiddly/features/games/drag_drop_screen.dart';
import 'package:kiddly/features/numbers/numbers_screen.dart';
import 'package:kiddly/features/sort/sort_screen.dart';

/// Advances the clock one real frame at a time, failing on the first frame
/// that throws. Coarse `pump(300ms)` steps jump straight over a 220ms implicit
/// animation and never sample its middle — which is exactly where an
/// overshooting curve misbehaves.
Future<void> _pumpFrames(WidgetTester tester, Duration total) async {
  const frame = Duration(milliseconds: 16);
  for (var elapsed = Duration.zero; elapsed < total; elapsed += frame) {
    await tester.pump(frame);
    expect(tester.takeException(), isNull,
        reason: 'threw ${elapsed.inMilliseconds}ms in');
  }
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('numbers counts in ascending order', () {
    testWidgets('the object the child taps gets the next number', (tester) async {
      await _pump(tester, const NumbersScreen());

      // The screen opens on "Three", so three identical objects are on stage.
      final glyph = Content.numbers[2].glyph;
      expect(find.text(glyph), findsNWidgets(3));

      // Tap the LAST object first. It must become "1" — counting is ascending,
      // it is not driven by the object's position in the row.
      await tester.tap(find.text(glyph).at(2));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('1'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
              of: find.text(glyph).at(2), matching: find.byType(Stack)).first,
          matching: find.text('1'),
        ),
        findsOneWidget,
        reason: 'the badge must land on the object that was actually tapped',
      );

      // Then the first object — it becomes "2", not "1".
      await tester.tap(find.text(glyph).at(0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
              of: find.text(glyph).at(0), matching: find.byType(Stack)).first,
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an object cannot be counted twice', (tester) async {
      await _pump(tester, const NumbersScreen());
      final glyph = Content.numbers[2].glyph;

      await tester.tap(find.text(glyph).at(1));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(glyph).at(1));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
    });
  });

  group('sort it', () {
    testWidgets('only the next item in the sequence is accepted',
        (tester) async {
      await _pump(tester, const SortScreen());

      List<String> trayLabels() => tester
          .widgetList<Draggable<String>>(find.byType(Draggable<String>))
          .map((d) => d.data!)
          .toList();

      expect(trayLabels().length, 5);
      expect(trayLabels().toSet(), {'A', 'B', 'C', 'D', 'E'});

      // 'C' is not what comes first — the tray must be untouched.
      await tester.tap(find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'C'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(trayLabels().length, 5, reason: 'a wrong tile is never placed');

      // 'A' is. It leaves the tray for the answer row.
      await tester.tap(find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == 'A'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(trayLabels(), isNot(contains('A')));
      expect(trayLabels().length, 4);
    });

    testWidgets('finishing a round re-deals without crashing', (tester) async {
      // Regression: every slot dropped its glow in the same frame when the
      // next round was dealt. AnimatedContainer lerped the shadow list to
      // null under an overshooting curve, scaling the blur radius negative and
      // tripping a dart:ui assertion.
      await _pump(tester, const SortScreen());

      for (final label in ['A', 'B', 'C', 'D', 'E']) {
        await tester.tap(find.byWidgetPredicate(
            (w) => w is Draggable<String> && w.data == label));
        await _pumpFrames(tester, const Duration(milliseconds: 350));
      }

      // Celebration (~2.2s), then the next round is dealt and every slot
      // resets its glow in a single frame.
      await _pumpFrames(tester, const Duration(seconds: 4));

      final labels = tester
          .widgetList<Draggable<String>>(find.byType(Draggable<String>))
          .map((d) => d.data!)
          .toSet();
      expect(labels, {'F', 'G', 'H', 'I', 'J'}, reason: 'round two dealt');
    });

    testWidgets('switching to 123 deals the numbers 1–5', (tester) async {
      await _pump(tester, const SortScreen());

      await tester.tap(find.text('123'));
      await tester.pump(const Duration(milliseconds: 400));

      final labels = tester
          .widgetList<Draggable<String>>(find.byType(Draggable<String>))
          .map((d) => d.data!)
          .toSet();
      expect(labels, {'1', '2', '3', '4', '5'});
    });
  });

  group('fill the basket', () {
    testWidgets('a collected fruit is shown inside the basket',
        (tester) async {
      await _pump(tester, const DragDropScreen());

      final trayNames = tester
          .widgetList<Draggable<String>>(find.byType(Draggable<String>))
          .map((d) => d.data!)
          .toList();
      expect(trayNames.length, 5);

      final fruit =
          Content.fruits.firstWhere((f) => f.name == trayNames.first);
      // On the tray a fruit shows its name; in the basket only its picture.
      expect(find.text(fruit.name), findsOneWidget);

      await tester.tap(find.byWidgetPredicate(
          (w) => w is Draggable<String> && w.data == fruit.name));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(fruit.name), findsNothing, reason: 'left the tray');
      expect(find.text(fruit.glyph), findsOneWidget,
          reason: 'and is now visible sitting inside the basket');
      expect(find.text('1'), findsOneWidget, reason: 'basket tally');
    });
  });
}
