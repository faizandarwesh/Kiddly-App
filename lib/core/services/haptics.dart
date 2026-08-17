import 'package:flutter/services.dart';

/// Thin wrapper around platform haptics so interactions feel tactile.
/// Failures are swallowed (e.g. on web / desktop without a vibrator).
class Haptics {
  Haptics._();

  static void tap() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void pop() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static void celebrate() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
