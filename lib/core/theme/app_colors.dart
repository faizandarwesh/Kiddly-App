import 'package:flutter/material.dart';

/// The playful color palette for the whole app.
///
/// Colors are intentionally bright, saturated and cheerful. Every learning
/// color the app teaches (see [namedColors]) lives here so activities and the
/// UI stay in sync.
class AppColors {
  AppColors._();

  // Brand / UI accents.
  static const Color sky = Color(0xFF7EC8F5);
  static const Color skyDeep = Color(0xFF4AA6E8);
  static const Color grass = Color(0xFF8BD450);
  static const Color grassDeep = Color(0xFF5EB82E);
  static const Color sunshine = Color(0xFFFFD23F);
  static const Color sunshineDeep = Color(0xFFFFB800);
  static const Color coral = Color(0xFFFF7A6B);
  static const Color bubblegum = Color(0xFFFF8FC7);
  static const Color grape = Color(0xFFA98CE8);
  static const Color mint = Color(0xFF57E0C0);
  static const Color cream = Color(0xFFFFF6E5);
  static const Color ink = Color(0xFF3A2E5C);

  /// The colors the "Colors" activity teaches, each with a friendly name.
  static const List<NamedColor> namedColors = [
    NamedColor('Red', Color(0xFFF14B4B)),
    NamedColor('Blue', Color(0xFF3E8EF7)),
    NamedColor('Yellow', Color(0xFFFFD23F)),
    NamedColor('Green', Color(0xFF56C860)),
    NamedColor('Orange', Color(0xFFFF9A3D)),
    NamedColor('Purple', Color(0xFFA163E0)),
    NamedColor('Pink', Color(0xFFFF8FC7)),
    NamedColor('Brown', Color(0xFF9C6B4A)),
    NamedColor('Black', Color(0xFF3A3A46)),
    NamedColor('White', Color(0xFFFAFAFA)),
  ];

  /// A soft candy gradient used behind many screens.
  static const List<Color> playgroundSky = [
    Color(0xFF9BD6FF),
    Color(0xFFCDEBFF),
    Color(0xFFEAF9E8),
  ];

  /// A rotating set of vivid gradients used for activity portals & cards.
  static const List<List<Color>> partyGradients = [
    [Color(0xFFFF9A9E), Color(0xFFFF6A88)],
    [Color(0xFF6DD5FA), Color(0xFF2980F2)],
    [Color(0xFFFFE259), Color(0xFFFFA751)],
    [Color(0xFFB5F0C8), Color(0xFF56C860)],
    [Color(0xFFC79CFF), Color(0xFF8A56E0)],
    [Color(0xFFFFC1E3), Color(0xFFFF6FB5)],
  ];
}

/// A learning color paired with its child-friendly spoken name.
class NamedColor {
  final String name;
  final Color color;
  const NamedColor(this.name, this.color);

  /// Whether text/particles on top of this color should be dark.
  bool get needsDarkForeground =>
      color.computeLuminance() > 0.6;
}
