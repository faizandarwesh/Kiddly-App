import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A single, warm, rounded theme. Toddlers don't need light/dark switching,
/// so we ship one joyful theme tuned for big touch targets and readable,
/// friendly typography.
class AppTheme {
  AppTheme._();

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.grape,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'Baloo', // Falls back to system if the family is absent.
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashColor: Colors.white24,
      highlightColor: Colors.white10,
    );
  }
}

/// Reusable text styles. Kept large and rounded for young eyes.
class AppText {
  AppText._();

  static const TextStyle huge = TextStyle(
    fontSize: 96,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    height: 1.0,
  );

  static const TextStyle title = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const TextStyle label = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
}
