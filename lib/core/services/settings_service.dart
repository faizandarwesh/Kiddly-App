import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent app-wide settings, controllable from the Parent Zone.
///
/// A [ChangeNotifier] so widgets (mute buttons, the audio service) can react
/// live. Values are cached in memory and written through to disk.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _kSound = 'sound_on';
  static const _kMusic = 'music_on';
  static const _kVoice = 'voice_on';

  SharedPreferences? _prefs;

  bool _soundOn = true;
  bool _musicOn = true;
  bool _voiceOn = true;

  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  bool get voiceOn => _voiceOn;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _soundOn = _prefs?.getBool(_kSound) ?? true;
    _musicOn = _prefs?.getBool(_kMusic) ?? true;
    _voiceOn = _prefs?.getBool(_kVoice) ?? true;
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    _soundOn = value;
    await _prefs?.setBool(_kSound, value);
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    _musicOn = value;
    await _prefs?.setBool(_kMusic, value);
    notifyListeners();
  }

  Future<void> setVoice(bool value) async {
    _voiceOn = value;
    await _prefs?.setBool(_kVoice, value);
    notifyListeners();
  }
}
