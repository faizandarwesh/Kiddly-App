import 'dart:math' as math;
import 'dart:typed_data';

/// Generates short sound effects at runtime as 16-bit PCM WAV bytes, so the app
/// ships with **no bundled audio files** and stays fully offline.
///
/// Each effect is a small blend of sine partials shaped by a quick
/// attack/decay envelope — gentle, rounded, toy-like sounds rather than harsh
/// beeps. The results are cached because the same handful of earcons are
/// reused constantly.
class ToneSynth {
  ToneSynth._();

  static const int _sampleRate = 44100;
  static final Map<String, Uint8List> _cache = {};

  /// A soft bubbly "pop" for taps and bursting things.
  static Uint8List pop() => _cache.putIfAbsent('pop', () {
        return _render(
          durationMs: 180,
          builder: (t, dur) {
            // Pitch rises quickly, like a bubble bursting.
            final freq = 420 + 520 * (t / dur);
            return math.sin(2 * math.pi * freq * t);
          },
          envelope: _pluck,
          gain: 0.5,
        );
      });

  /// A bright ascending "sparkle" for magical reveals.
  static Uint8List sparkle() => _cache.putIfAbsent('sparkle', () {
        const notes = [880.0, 1174.0, 1568.0];
        return _render(
          durationMs: 360,
          builder: (t, dur) {
            final idx = (t / dur * notes.length).floor().clamp(0, notes.length - 1);
            final f = notes[idx];
            return math.sin(2 * math.pi * f * t) +
                0.4 * math.sin(2 * math.pi * f * 2 * t);
          },
          envelope: _bell,
          gain: 0.32,
        );
      });

  /// A happy three-note major arpeggio: "you did it!".
  static Uint8List success() => _cache.putIfAbsent('success', () {
        const notes = [523.25, 659.25, 783.99, 1046.5]; // C E G C
        return _render(
          durationMs: 620,
          builder: (t, dur) {
            final idx =
                (t / dur * notes.length).floor().clamp(0, notes.length - 1);
            final f = notes[idx];
            return math.sin(2 * math.pi * f * t) +
                0.3 * math.sin(2 * math.pi * f * 2 * t);
          },
          envelope: _bell,
          gain: 0.34,
        );
      });

  /// A comical "sad trombone" — four descending brassy notes ("wah-wah-waah").
  /// Playful, never harsh, for a wrong guess.
  static Uint8List funny() => _cache.putIfAbsent('funny', () {
        const notes = [392.00, 349.23, 311.13, 233.08]; // G F Eb Bb
        return _render(
          durationMs: 820,
          builder: (t, dur) {
            final idx =
                (t / dur * notes.length).floor().clamp(0, notes.length - 1);
            final f = notes[idx];
            final vibrato = 5 * math.sin(2 * math.pi * 6 * t); // wobble
            final ff = f + vibrato;
            // Brassy timbre from stacked harmonics.
            return math.sin(2 * math.pi * ff * t) +
                0.5 * math.sin(2 * math.pi * 2 * ff * t) +
                0.25 * math.sin(2 * math.pi * 3 * ff * t);
          },
          envelope: _soft,
          gain: 0.28,
        );
      });

  /// A gentle, non-scary "try again" wobble (never a harsh error buzz).
  static Uint8List nudge() => _cache.putIfAbsent('nudge', () {
        return _render(
          durationMs: 300,
          builder: (t, dur) {
            final vibrato = 8 * math.sin(2 * math.pi * 6 * t);
            final f = 300 + vibrato;
            return math.sin(2 * math.pi * f * t);
          },
          envelope: _soft,
          gain: 0.3,
        );
      });

  /// A single warm musical note (used by the instrument playground / counting).
  static Uint8List note(double frequency, {int durationMs = 420}) =>
      _cache.putIfAbsent('note_${frequency.toStringAsFixed(1)}_$durationMs', () {
        return _render(
          durationMs: durationMs,
          builder: (t, dur) =>
              math.sin(2 * math.pi * frequency * t) +
              0.35 * math.sin(2 * math.pi * frequency * 2 * t),
          envelope: _bell,
          gain: 0.34,
        );
      });

  // ----- envelopes (0..1 amplitude over the note) -----

  static double _pluck(double p) =>
      (p < 0.05 ? p / 0.05 : math.exp(-4 * (p - 0.05))).toDouble();

  static double _bell(double p) =>
      (p < 0.02 ? p / 0.02 : math.exp(-3.2 * (p - 0.02))).toDouble();

  static double _soft(double p) => math.sin(math.pi * p);

  // ----- core renderer -----

  static Uint8List _render({
    required int durationMs,
    required double Function(double t, double dur) builder,
    required double Function(double progress) envelope,
    required double gain,
  }) {
    final dur = durationMs / 1000.0;
    final total = (dur * _sampleRate).round();
    final samples = Int16List(total);
    for (var i = 0; i < total; i++) {
      final t = i / _sampleRate;
      final env = envelope(i / total);
      var v = builder(t, dur) * env * gain;
      v = v.clamp(-1.0, 1.0);
      samples[i] = (v * 32767).round();
    }
    return _wrapWav(samples);
  }

  /// Wraps mono 16-bit PCM samples in a minimal WAV container.
  static Uint8List _wrapWav(Int16List samples) {
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = _sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = samples.length * 2;
    final buffer = BytesBuilder();

    void str(String s) => buffer.add(s.codeUnits);
    void u32(int v) => buffer.add(
        Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
    void u16(int v) => buffer.add(
        Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

    str('RIFF');
    u32(36 + dataSize);
    str('WAVE');
    str('fmt ');
    u32(16);
    u16(1); // PCM
    u16(channels);
    u32(_sampleRate);
    u32(byteRate);
    u16(blockAlign);
    u16(bitsPerSample);
    str('data');
    u32(dataSize);
    buffer.add(samples.buffer.asUint8List());
    return buffer.toBytes();
  }
}
