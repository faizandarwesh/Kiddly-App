import 'dart:math' as math;
import 'dart:typed_data';

/// The distinct instrument voices the Music playground can produce.
///
/// Each one is synthesized with its *own* waveform, harmonic stack and
/// envelope — not the same sine wave at a different pitch — so a child taps a
/// drum and hears a drum, taps a bell and hears a bell.
enum Timbre { xylophone, drum, bell, guitar, trumpet, flute, piano }

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

  /// Renders one note of [timbre] at [frequency].
  ///
  /// This is what makes the instruments in the Music world actually *sound*
  /// different from one another: each branch below builds a different spectrum
  /// and a different amplitude shape. Results are cached per (timbre, pitch,
  /// length), so the same tap costs nothing the second time.
  static Uint8List instrument(Timbre timbre, double frequency,
          {int durationMs = 500}) =>
      _cache.putIfAbsent(
        'ins_${timbre.name}_${frequency.toStringAsFixed(1)}_$durationMs',
        () {
          switch (timbre) {
            case Timbre.xylophone:
              return _xylophone(frequency, durationMs);
            case Timbre.drum:
              return _drum(frequency, durationMs);
            case Timbre.bell:
              return _bellVoice(frequency, durationMs);
            case Timbre.guitar:
              return _pluckedString(frequency, durationMs);
            case Timbre.trumpet:
              return _trumpet(frequency, durationMs);
            case Timbre.flute:
              return _flute(frequency, durationMs);
            case Timbre.piano:
              return _piano(frequency, durationMs);
          }
        },
      );

  /// Wooden mallet bar: bright, inharmonic partials that die away fast.
  static Uint8List _xylophone(double f, int ms) => _render(
        durationMs: ms,
        builder: (t, dur) =>
            math.sin(2 * math.pi * f * t) +
            0.45 * math.sin(2 * math.pi * f * 3.0 * t) +
            0.18 * math.sin(2 * math.pi * f * 6.2 * t),
        envelope: (p) => (p < 0.008 ? p / 0.008 : math.exp(-5.5 * p)),
        gain: 0.32,
      );

  /// Drum: a noise transient over a body whose pitch dives quickly — the
  /// classic "thump". The pitch sweep is integrated analytically so the phase
  /// stays continuous and the hit never clicks.
  static Uint8List _drum(double f, int ms) {
    final rng = math.Random(11);
    const a = 2.6, b = 0.5; // pitch multiplier: start high, settle low
    final k = 18.0;
    return _render(
      durationMs: ms,
      builder: (t, dur) {
        // ∫ f(t) dt for f(t) = f * (a·e^(-kt) + b)
        final phase = 2 * math.pi * f * (a * (1 - math.exp(-k * t)) / k + b * t);
        final body = math.sin(phase) + 0.3 * math.sin(2 * phase);
        final noise = (rng.nextDouble() * 2 - 1) * math.exp(-38 * t) * 0.8;
        return body + noise;
      },
      envelope: (p) => (p < 0.004 ? p / 0.004 : math.exp(-7 * p)),
      gain: 0.42,
    );
  }

  /// Bell: struck-metal partials (the classic tubular-bell ratios) ringing on
  /// long after the strike.
  static Uint8List _bellVoice(double f, int ms) {
    const ratios = [1.0, 2.76, 5.40, 8.93];
    const amps = [1.0, 0.62, 0.34, 0.18];
    return _render(
      durationMs: ms,
      builder: (t, dur) {
        var v = 0.0;
        for (var i = 0; i < ratios.length; i++) {
          // Higher partials fade first, like real metal.
          v += amps[i] *
              math.exp(-(1.4 + i * 1.6) * (t / dur)) *
              math.sin(2 * math.pi * f * ratios[i] * t);
        }
        return v;
      },
      envelope: (p) => (p < 0.003 ? p / 0.003 : (p > 0.9 ? (1 - p) / 0.1 : 1)),
      gain: 0.26,
    );
  }

  /// Guitar: a real Karplus–Strong plucked string. A burst of noise is fed
  /// into a delay line one wavelength long and averaged on every pass, which
  /// is exactly how a plucked string loses its high harmonics first.
  static Uint8List _pluckedString(double f, int ms) {
    final total = (ms / 1000.0 * _sampleRate).round();
    final n = math.max(2, (_sampleRate / f).round());
    final rng = math.Random(1337);
    final ring = List<double>.generate(n, (_) => rng.nextDouble() * 2 - 1);
    final samples = Int16List(total);
    var idx = 0;
    for (var i = 0; i < total; i++) {
      final current = ring[idx];
      final next = ring[(idx + 1) % n];
      ring[idx] = 0.9965 * 0.5 * (current + next); // low-pass + slow decay
      idx = (idx + 1) % n;
      final p = i / total;
      // Fade the tail so the note ends on silence rather than a click.
      final fade = p > 0.85 ? (1 - p) / 0.15 : 1.0;
      final v = (current * 0.5 * fade).clamp(-1.0, 1.0);
      samples[i] = (v * 32767).round();
    }
    return _wrapWav(samples);
  }

  /// Trumpet: a bright sawtooth-like stack of harmonics with a brassy swell
  /// and a touch of vibrato.
  static Uint8List _trumpet(double f, int ms) => _render(
        durationMs: ms,
        builder: (t, dur) {
          final vib = 1 + 0.004 * math.sin(2 * math.pi * 5.5 * t);
          var v = 0.0;
          for (var n = 1; n <= 8; n++) {
            v += (1 / n) * math.sin(2 * math.pi * f * n * vib * t);
          }
          return v;
        },
        envelope: (p) => p < 0.08
            ? p / 0.08
            : (p > 0.82 ? (1 - p) / 0.18 : 1 - 0.15 * (p - 0.08)),
        gain: 0.20,
      );

  /// Flute: an almost-pure tone with a whisper of breath noise and a slow,
  /// singing vibrato.
  static Uint8List _flute(double f, int ms) {
    final rng = math.Random(29);
    return _render(
      durationMs: ms,
      builder: (t, dur) {
        final vib = 1 + 0.05 * math.sin(2 * math.pi * 4.8 * t);
        final breath = (rng.nextDouble() * 2 - 1) * 0.035;
        return (math.sin(2 * math.pi * f * t) +
                0.10 * math.sin(2 * math.pi * f * 2 * t) +
                0.04 * math.sin(2 * math.pi * f * 3 * t)) *
                vib +
            breath;
      },
      envelope: (p) => p < 0.14
          ? p / 0.14
          : (p > 0.75 ? (1 - p) / 0.25 : 1.0),
      gain: 0.34,
    );
  }

  /// Piano: a hammered string — instant attack, harmonics that each decay at
  /// their own rate so the tone darkens as it fades.
  static Uint8List _piano(double f, int ms) {
    const amps = [1.0, 0.50, 0.26, 0.13, 0.07];
    const decays = [2.6, 4.2, 6.0, 8.5, 12.0];
    return _render(
      durationMs: ms,
      builder: (t, dur) {
        final p = t / dur;
        var v = 0.0;
        for (var i = 0; i < amps.length; i++) {
          v += amps[i] *
              math.exp(-decays[i] * p) *
              math.sin(2 * math.pi * f * (i + 1) * t);
        }
        return v;
      },
      envelope: (p) => (p < 0.004 ? p / 0.004 : (p > 0.92 ? (1 - p) / 0.08 : 1)),
      gain: 0.30,
    );
  }

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
