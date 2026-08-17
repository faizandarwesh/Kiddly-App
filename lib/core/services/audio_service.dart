import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings_service.dart';
import 'tone_synth.dart';

/// The named sound effects the app can play. Bytes come from [ToneSynth] so
/// there are no audio assets to ship.
enum Sfx { pop, sparkle, success, nudge, funny }

/// One friendly voice + all sound effects, gated by [SettingsService].
///
/// Voice uses the device's text-to-speech (offline on most platforms) tuned to
/// sound warm and a little high-pitched — playful for young children. Effects
/// play through a tiny pool of [AudioPlayer]s so several taps can overlap.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final FlutterTts _tts = FlutterTts();
  final List<AudioPlayer> _sfxPool =
      List.generate(4, (i) => AudioPlayer(playerId: 'sfx_$i'));
  int _sfxCursor = 0;
  bool _ready = false;

  final Map<Sfx, Uint8List> _sfxBytes = {
    Sfx.pop: ToneSynth.pop(),
    Sfx.sparkle: ToneSynth.sparkle(),
    Sfx.success: ToneSynth.success(),
    Sfx.nudge: ToneSynth.nudge(),
    Sfx.funny: ToneSynth.funny(),
  };

  SettingsService get _settings => SettingsService.instance;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.35); // Higher = friendlier/younger.
      await _tts.setSpeechRate(0.42); // Slow and clear for toddlers.
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('TTS init failed (voice will be skipped): $e');
    }
    _ready = true;
  }

  /// Speak a short, cheerful phrase. No-op when voice is muted.
  Future<void> say(String text) async {
    if (!_settings.voiceOn) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  Future<void> stopVoice() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Play a sound effect. No-op when sound is muted.
  Future<void> sfx(Sfx effect) async {
    if (!_settings.soundOn) return;
    final bytes = _sfxBytes[effect];
    if (bytes == null) return;
    try {
      final player = _sfxPool[_sfxCursor];
      _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
      await player.stop();
      // mimeType is required so iOS/AVFoundation writes a proper .wav temp file
      // (without it, "Failed to set source" — the file has no extension).
      await player.play(BytesSource(bytes, mimeType: 'audio/wav'), volume: 1.0);
    } catch (e) {
      debugPrint('SFX failed: $e');
    }
  }

  /// Play a single warm musical note by frequency (instruments / counting).
  Future<void> playNote(double frequency, {int durationMs = 420}) async {
    if (!_settings.soundOn) return;
    try {
      final player = _sfxPool[_sfxCursor];
      _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
      await player.stop();
      await player.play(
        BytesSource(ToneSynth.note(frequency, durationMs: durationMs),
            mimeType: 'audio/wav'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('note failed: $e');
    }
  }

  void dispose() {
    for (final p in _sfxPool) {
      p.dispose();
    }
  }
}
