import 'package:flutter/material.dart';

/// A single, reusable unit of learnable content.
///
/// The whole app is data-driven around this model (see the "content
/// architecture" brief): the same structure powers letters, numbers, animals,
/// fruits, vehicles and more. To add content you add data — not screens.
class LearnItem {
  /// A big emoji used as the visual (keeps the app asset-free).
  final String glyph;

  /// Child-friendly display name, e.g. "Apple".
  final String name;

  /// What the friendly voice should say when this item is discovered.
  /// Defaults to [name] when omitted.
  final String? spoken;

  /// Optional single letter this item illustrates (ABC).
  final String? letter;

  /// Optional quantity/number this item represents.
  final int? number;

  /// A sub-grouping within a category, e.g. "Farm" for animals.
  final String? group;

  /// An accent color for cards/particles tied to this item.
  final Color accent;

  /// Whether this emoji's artwork points **left**.
  ///
  /// Emoji have a fixed, baked-in orientation: in every major emoji font the
  /// car, bus, fire truck, police car, tractor, helicopter, sailboat and
  /// aeroplane are all drawn facing left, while the rocket points right and the
  /// train is head-on. Anything that animates across the screen has to mirror
  /// the left-facing ones, or the vehicle drives backwards.
  final bool facesLeft;

  const LearnItem({
    required this.glyph,
    required this.name,
    this.spoken,
    this.letter,
    this.number,
    this.group,
    this.accent = const Color(0xFFFFD23F),
    this.facesLeft = false,
  });

  String get voice => spoken ?? name;
}
