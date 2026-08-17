import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kiddly/core/services/tone_synth.dart';
import 'package:kiddly/data/content.dart';
import 'package:kiddly/data/puzzle_pals.dart';

void main() {
  group('content datasets', () {
    test('alphabet covers A–Z with words and emoji', () {
      expect(Content.alphabet.length, 26);
      expect(Content.alphabet.first.letter, 'A');
      expect(Content.alphabet.last.letter, 'Z');
      for (final item in Content.alphabet) {
        expect(item.name, isNotEmpty);
        expect(item.glyph, isNotEmpty);
        expect(item.voice, contains(item.letter!));
      }
    });

    test('numbers cover 1–10 in order', () {
      expect(Content.numbers.length, 10);
      expect(Content.numbers.first.number, 1);
      expect(Content.numbers.last.number, 10);
    });

    test('every animal belongs to a known habitat group', () {
      expect(Content.animals, isNotEmpty);
      for (final a in Content.animals) {
        expect(Content.animalGroups, contains(a.group));
      }
    });

    test('fruits and vehicles are populated', () {
      expect(Content.fruits.length, greaterThanOrEqualTo(7));
      expect(Content.vehicles.length, greaterThanOrEqualTo(9));
      // Vehicles encode motion type in `group`.
      for (final v in Content.vehicles) {
        expect(['air', 'ground', 'water'], contains(v.group));
      }
    });
  });

  group('puzzle pals', () {
    test('every pal has a name, a glyph and at most four props', () {
      expect(Pals.list, isNotEmpty);
      for (final p in Pals.list) {
        expect(p.name, isNotEmpty);
        expect(p.glyph, isNotEmpty);
        // The scene only has four prop positions; extras would be dropped.
        expect(p.decor.length, lessThanOrEqualTo(4));
      }
    });

    test('names are unique, so the header never repeats between levels', () {
      final names = Pals.list.map((p) => p.name).toSet();
      expect(names.length, Pals.list.length);
    });

    test('no pal references a bundled image asset', () {
      // The app ships no third-party artwork — scenes are painted at runtime.
      // A stray 'assets/…' string here would mean that regressed.
      for (final p in Pals.list) {
        expect(p.glyph, isNot(contains('assets/')));
        for (final d in p.decor) {
          expect(d, isNot(contains('assets/')));
        }
      }
    });

    test('a scene paints without throwing at every size the puzzle uses', () {
      // The board, a placed piece, a tray thumbnail and a dragged piece all
      // paint the same scene at different scales in one frame.
      for (final p in Pals.list) {
        final scene = PalScene(p);
        for (final size in [520.0, 104.0, 156.0]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          scene.paint(canvas, Size(size, size));
          recorder.endRecording().dispose();
        }
      }
    });
  });

  group('tone synth', () {
    test('produces a valid, non-empty WAV for each effect', () {
      final clips = <Uint8List>[
        ToneSynth.pop(),
        ToneSynth.sparkle(),
        ToneSynth.success(),
        ToneSynth.nudge(),
        ToneSynth.funny(),
        ToneSynth.note(440),
      ];
      for (final wav in clips) {
        expect(wav.length, greaterThan(44)); // header + samples
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      }
    });

    test('caches identical effects', () {
      expect(identical(ToneSynth.pop(), ToneSynth.pop()), isTrue);
    });
  });
}
