import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile.dart';

/// Owns the list of child profiles and the currently-active one, plus the
/// reward economy (stars/rainbows/hearts). Persists to disk and notifies the
/// UI so reward HUDs update instantly.
class ProfileService extends ChangeNotifier {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _kProfiles = 'profiles_v1';
  static const _kActive = 'active_profile_v1';

  SharedPreferences? _prefs;
  final List<ChildProfile> _profiles = [];
  String? _activeId;

  List<ChildProfile> get profiles => List.unmodifiable(_profiles);

  ChildProfile? get active {
    if (_profiles.isEmpty) return null;
    return _profiles.firstWhere(
      (p) => p.id == _activeId,
      orElse: () => _profiles.first,
    );
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_kProfiles);
    _profiles.clear();
    if (raw != null && raw.isNotEmpty) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _profiles.addAll(list.map(ChildProfile.fromJson));
    }
    if (_profiles.isEmpty) {
      // Seed a friendly default so the app is playable on first launch.
      _profiles.add(ChildProfile(id: _newId(), name: 'Friend', avatar: '🐰'));
    }
    _activeId = _prefs?.getString(_kActive) ?? _profiles.first.id;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _prefs?.setString(
      _kProfiles,
      jsonEncode(_profiles.map((p) => p.toJson()).toList()),
    );
    if (_activeId != null) {
      await _prefs?.setString(_kActive, _activeId!);
    }
  }

  String _newId() =>
      'p${_profiles.length}_${_profiles.fold<int>(0, (a, p) => a + p.name.length)}';

  Future<void> addProfile(String name, String avatar) async {
    _profiles.add(ChildProfile(id: _newId(), name: name, avatar: avatar));
    notifyListeners();
    await _persist();
  }

  Future<void> updateProfile(ChildProfile profile) async {
    notifyListeners();
    await _persist();
  }

  Future<void> removeProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    if (_activeId == id) _activeId = _profiles.isNotEmpty ? _profiles.first.id : null;
    notifyListeners();
    await _persist();
  }

  Future<void> setActive(String id) async {
    _activeId = id;
    notifyListeners();
    await _persist();
  }

  // ----- rewards -----

  Future<void> awardStars(int count) async {
    final p = active;
    if (p == null) return;
    p.stars += count;
    // Every 5 stars becomes a rainbow; every 3 rainbows a heart — a gentle,
    // non-monetary sense of growing collection.
    while (p.stars >= 5) {
      p.stars -= 5;
      p.rainbows += 1;
    }
    while (p.rainbows >= 3) {
      p.rainbows -= 3;
      p.hearts += 1;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> markCompleted(String activityKey) async {
    final p = active;
    if (p == null) return;
    p.completed.add(activityKey);
    notifyListeners();
    await _persist();
  }
}
