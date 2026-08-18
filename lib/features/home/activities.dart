import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../abc/abc_screen.dart';
import '../animals/animals_screen.dart';
import '../bubbles/bubble_screen.dart';
import '../colors/colors_screen.dart';
import '../drawing/drawing_screen.dart';
import '../fruits/fruits_screen.dart';
import '../games/drag_drop_screen.dart';
import '../games/matching_screen.dart';
import '../games/puzzle_screen.dart';
import '../games/sequence_screen.dart';
import '../music/music_screen.dart';
import '../numbers/numbers_screen.dart';
import '../shapes/shapes_screen.dart';
import '../sort/sort_screen.dart';
import '../vehicles/vehicles_screen.dart';

/// A single entry in the home playground grid. Adding a new world is just
/// adding one entry here — the home screen renders the rest.
class Activity {
  final String emoji;
  final String label;
  final List<Color> gradient;
  final WidgetBuilder builder;
  const Activity(this.emoji, this.label, this.gradient, this.builder);
}

/// Every playable world, in the order they appear on the home screen.
final List<Activity> kActivities = [
  Activity('🔤', 'ABC', AppColors.partyGradients[0], (_) => const AbcScreen()),
  Activity('🔢', 'Numbers', AppColors.partyGradients[1], (_) => const NumbersScreen()),
  Activity('🎨', 'Colors', AppColors.partyGradients[4], (_) => const ColorsScreen()),
  Activity('⭐', 'Shapes', AppColors.partyGradients[2], (_) => const ShapesScreen()),
  Activity('🐾', 'Animals', AppColors.partyGradients[3], (_) => const AnimalsScreen()),
  Activity('🍎', 'Food', AppColors.partyGradients[5], (_) => const FruitsScreen()),
  Activity('🚗', 'Vehicles', AppColors.partyGradients[1], (_) => const VehiclesScreen()),
  Activity('🎵', 'Music', AppColors.partyGradients[4], (_) => const MusicScreen()),
  Activity('✏️', 'Draw', AppColors.partyGradients[2], (_) => const DrawingScreen()),
  Activity('🧩', 'Puzzle', AppColors.partyGradients[0], (_) => const PuzzleScreen()),
  Activity('🃏', 'Match', AppColors.partyGradients[3], (_) => const MatchingScreen()),
  Activity('🧠', 'Memory', AppColors.partyGradients[1], (_) => const SequenceScreen()),
  Activity('🫧', 'Bubbles', AppColors.partyGradients[4], (_) => const BubbleScreen()),
  Activity('🧺', 'Basket', AppColors.partyGradients[5], (_) => const DragDropScreen()),
  Activity('🧮', 'Sort', AppColors.partyGradients[2], (_) => const SortScreen()),
];
