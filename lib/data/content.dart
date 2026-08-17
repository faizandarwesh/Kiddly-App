import 'package:flutter/material.dart';

import 'learn_item.dart';

/// All learning datasets, kept as plain data so new content needs no new code.
class Content {
  Content._();

  static const _accents = [
    Color(0xFFF14B4B),
    Color(0xFF3E8EF7),
    Color(0xFFFF9A3D),
    Color(0xFF56C860),
    Color(0xFFA163E0),
    Color(0xFFFF8FC7),
    Color(0xFF57E0C0),
  ];

  static Color _accent(int i) => _accents[i % _accents.length];

  /// A–Z, each with a representative word + emoji.
  static final List<LearnItem> alphabet = () {
    const words = {
      'A': ['Apple', '🍎'],
      'B': ['Ball', '⚽'],
      'C': ['Cat', '🐱'],
      'D': ['Dog', '🐶'],
      'E': ['Egg', '🥚'],
      'F': ['Fish', '🐟'],
      'G': ['Grapes', '🍇'],
      'H': ['Hat', '🎩'],
      'I': ['Ice cream', '🍦'],
      'J': ['Jellyfish', '🪼'],
      'K': ['Kite', '🪁'],
      'L': ['Lion', '🦁'],
      'M': ['Moon', '🌙'],
      'N': ['Nest', '🪺'],
      'O': ['Orange', '🍊'],
      'P': ['Panda', '🐼'],
      'Q': ['Queen', '👑'],
      'R': ['Rainbow', '🌈'],
      'S': ['Sun', '☀️'],
      'T': ['Tree', '🌳'],
      'U': ['Umbrella', '☂️'],
      'V': ['Van', '🚐'],
      'W': ['Whale', '🐳'],
      'X': ['Xylophone', '🎼'],
      'Y': ['Yo-yo', '🪀'],
      'Z': ['Zebra', '🦓'],
    };
    var i = 0;
    return words.entries.map((e) {
      final word = e.value[0];
      final emoji = e.value[1];
      return LearnItem(
        letter: e.key,
        name: word,
        glyph: emoji,
        spoken: '${e.key}. $word',
        accent: _accent(i++),
      );
    }).toList();
  }();

  /// 1–10 with a fun countable emoji each.
  static final List<LearnItem> numbers = () {
    const glyphs = ['🎈', '🍎', '⭐', '🐟', '🌸', '🍓', '🦋', '🐤', '🍭', '🧁'];
    const words = [
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten'
    ];
    return List.generate(10, (i) {
      return LearnItem(
        number: i + 1,
        name: words[i],
        glyph: glyphs[i],
        spoken: words[i],
        accent: _accent(i),
      );
    });
  }();

  /// Animals grouped by habitat, each with the sound it makes.
  static final List<LearnItem> animals = [
    LearnItem(glyph: '🐄', name: 'Cow', spoken: 'Cow. Moooo!', group: 'Farm', accent: _accent(0)),
    LearnItem(glyph: '🐖', name: 'Pig', spoken: 'Pig. Oink oink!', group: 'Farm', accent: _accent(5)),
    LearnItem(glyph: '🐑', name: 'Sheep', spoken: 'Sheep. Baaa!', group: 'Farm', accent: _accent(2)),
    LearnItem(glyph: '🐔', name: 'Chicken', spoken: 'Chicken. Cluck cluck!', group: 'Farm', accent: _accent(3)),
    LearnItem(glyph: '🦁', name: 'Lion', spoken: 'Lion. Roooar!', group: 'Jungle', accent: _accent(2)),
    LearnItem(glyph: '🐒', name: 'Monkey', spoken: 'Monkey. Ooh ooh ah ah!', group: 'Jungle', accent: _accent(3)),
    LearnItem(glyph: '🐘', name: 'Elephant', spoken: 'Elephant. Trumpet!', group: 'Jungle', accent: _accent(1)),
    LearnItem(glyph: '🐸', name: 'Frog', spoken: 'Frog. Ribbit ribbit!', group: 'Jungle', accent: _accent(3)),
    LearnItem(glyph: '🐟', name: 'Fish', spoken: 'Fish. Blub blub!', group: 'Ocean', accent: _accent(1)),
    LearnItem(glyph: '🐙', name: 'Octopus', spoken: 'Octopus!', group: 'Ocean', accent: _accent(4)),
    LearnItem(glyph: '🐬', name: 'Dolphin', spoken: 'Dolphin. Eee eee!', group: 'Ocean', accent: _accent(1)),
    LearnItem(glyph: '🐢', name: 'Turtle', spoken: 'Turtle!', group: 'Ocean', accent: _accent(3)),
    LearnItem(glyph: '🐶', name: 'Dog', spoken: 'Dog. Woof woof!', group: 'Pets', accent: _accent(2)),
    LearnItem(glyph: '🐱', name: 'Cat', spoken: 'Cat. Meow!', group: 'Pets', accent: _accent(5)),
    LearnItem(glyph: '🐰', name: 'Rabbit', spoken: 'Rabbit. Hop hop!', group: 'Pets', accent: _accent(6)),
    LearnItem(glyph: '🦕', name: 'Dino', spoken: 'Dinosaur. Rawr!', group: 'Dino', accent: _accent(3)),
    LearnItem(glyph: '🦖', name: 'T-Rex', spoken: 'T-Rex. Roooar!', group: 'Dino', accent: _accent(0)),
  ];

  static List<String> get animalGroups =>
      ['Farm', 'Jungle', 'Ocean', 'Pets', 'Dino'];

  /// Fruits & food. `spoken` adds a playful action hint for the tap reaction.
  static final List<LearnItem> fruits = [
    LearnItem(glyph: '🍎', name: 'Apple', spoken: 'Apple!', accent: _accent(0)),
    LearnItem(glyph: '🍌', name: 'Banana', spoken: 'Banana!', accent: _accent(2)),
    LearnItem(glyph: '🍊', name: 'Orange', spoken: 'Orange!', accent: _accent(2)),
    LearnItem(glyph: '🍓', name: 'Strawberry', spoken: 'Strawberry!', accent: _accent(0)),
    LearnItem(glyph: '🍉', name: 'Watermelon', spoken: 'Watermelon!', accent: _accent(3)),
    LearnItem(glyph: '🍇', name: 'Grapes', spoken: 'Grapes!', accent: _accent(4)),
    LearnItem(glyph: '🍍', name: 'Pineapple', spoken: 'Pineapple!', accent: _accent(2)),
    LearnItem(glyph: '🥝', name: 'Kiwi', spoken: 'Kiwi!', accent: _accent(3)),
    LearnItem(glyph: '🍒', name: 'Cherry', spoken: 'Cherry!', accent: _accent(0)),
    LearnItem(glyph: '🥕', name: 'Carrot', spoken: 'Carrot!', accent: _accent(2)),
    LearnItem(glyph: '🌽', name: 'Corn', spoken: 'Corn!', accent: _accent(2)),
    LearnItem(glyph: '🍩', name: 'Donut', spoken: 'Yummy donut!', accent: _accent(5)),
  ];

  /// Vehicles. `group` encodes how it moves: air / ground / water.
  static final List<LearnItem> vehicles = [
    LearnItem(glyph: '🚗', name: 'Car', spoken: 'Car. Vroom vroom!', group: 'ground', accent: _accent(0)),
    LearnItem(glyph: '🚌', name: 'Bus', spoken: 'Bus. Beep beep!', group: 'ground', accent: _accent(2)),
    LearnItem(glyph: '🚆', name: 'Train', spoken: 'Train. Choo choo!', group: 'ground', accent: _accent(1)),
    LearnItem(glyph: '🚒', name: 'Fire truck', spoken: 'Fire truck. Wee ooo!', group: 'ground', accent: _accent(0)),
    LearnItem(glyph: '🚓', name: 'Police car', spoken: 'Police car. Nee naw!', group: 'ground', accent: _accent(1)),
    LearnItem(glyph: '🚜', name: 'Tractor', spoken: 'Tractor. Brrrm!', group: 'ground', accent: _accent(3)),
    LearnItem(glyph: '✈️', name: 'Airplane', spoken: 'Airplane. Whoosh!', group: 'air', accent: _accent(1)),
    LearnItem(glyph: '🚁', name: 'Helicopter', spoken: 'Helicopter. Chop chop!', group: 'air', accent: _accent(4)),
    LearnItem(glyph: '🚀', name: 'Rocket', spoken: 'Rocket. Blast off!', group: 'air', accent: _accent(0)),
    LearnItem(glyph: '⛵', name: 'Boat', spoken: 'Boat. Toot toot!', group: 'water', accent: _accent(1)),
  ];
}
