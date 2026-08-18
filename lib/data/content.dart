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

  /// Vehicles. `group` encodes how it moves: air / ground / water, and
  /// `facesLeft` which way the emoji artwork points (see [LearnItem.facesLeft])
  /// so the Vehicles stage can mirror it to face its direction of travel.
  static final List<LearnItem> vehicles = [
    LearnItem(glyph: '🚗', name: 'Car', spoken: 'Car. Vroom vroom!', group: 'ground', accent: _accent(0), facesLeft: true),
    LearnItem(glyph: '🚌', name: 'Bus', spoken: 'Bus. Beep beep!', group: 'ground', accent: _accent(2), facesLeft: true),
    // Head-on artwork — mirroring it would change nothing.
    LearnItem(glyph: '🚆', name: 'Train', spoken: 'Train. Choo choo!', group: 'ground', accent: _accent(1)),
    LearnItem(glyph: '🚒', name: 'Fire truck', spoken: 'Fire truck. Wee ooo!', group: 'ground', accent: _accent(0), facesLeft: true),
    LearnItem(glyph: '🚓', name: 'Police car', spoken: 'Police car. Nee naw!', group: 'ground', accent: _accent(1), facesLeft: true),
    LearnItem(glyph: '🚜', name: 'Tractor', spoken: 'Tractor. Brrrm!', group: 'ground', accent: _accent(3), facesLeft: true),
    LearnItem(glyph: '✈️', name: 'Airplane', spoken: 'Airplane. Whoosh!', group: 'air', accent: _accent(1), facesLeft: true),
    LearnItem(glyph: '🚁', name: 'Helicopter', spoken: 'Helicopter. Chop chop!', group: 'air', accent: _accent(4), facesLeft: true),
    // The only one already drawn pointing right.
    LearnItem(glyph: '🚀', name: 'Rocket', spoken: 'Rocket. Blast off!', group: 'air', accent: _accent(0)),
    LearnItem(glyph: '⛵', name: 'Boat', spoken: 'Boat. Toot toot!', group: 'water', accent: _accent(1), facesLeft: true),
  ];

  /// Animals arranged A–Z — exactly one per letter — for the swipe-through
  /// deck. Each entry ties the letter to a big picture, the animal's name and
  /// the noise it makes, so a child learns all three together.
  static final List<LearnItem> animalsAZ = () {
    const rows = [
      ['A', 'Ant', '\u{1F41C}', 'March march!'],
      ['B', 'Bear', '\u{1F43B}', 'Grrrr!'],
      ['C', 'Cat', '\u{1F431}', 'Meow!'],
      ['D', 'Dog', '\u{1F436}', 'Woof woof!'],
      ['E', 'Elephant', '\u{1F418}', 'Trumpet!'],
      ['F', 'Frog', '\u{1F438}', 'Ribbit ribbit!'],
      ['G', 'Giraffe', '\u{1F992}', 'So tall!'],
      ['H', 'Horse', '\u{1F434}', 'Neigh!'],
      ['I', 'Iguana', '\u{1F98E}', 'Scurry scurry!'],
      ['J', 'Jellyfish', '\u{1FABC}', 'Wibble wobble!'],
      ['K', 'Kangaroo', '\u{1F998}', 'Hop hop!'],
      ['L', 'Lion', '\u{1F981}', 'Roooar!'],
      ['M', 'Monkey', '\u{1F435}', 'Ooh ooh ah ah!'],
      ['N', 'Nightingale', '\u{1F426}', 'Tweet tweet!'],
      ['O', 'Owl', '\u{1F989}', 'Hoo hoo!'],
      ['P', 'Panda', '\u{1F43C}', 'Munch munch!'],
      ['Q', 'Queen bee', '\u{1F41D}', 'Buzz buzz!'],
      ['R', 'Rabbit', '\u{1F430}', 'Hop hop!'],
      ['S', 'Snake', '\u{1F40D}', 'Sssssss!'],
      ['T', 'Tiger', '\u{1F42F}', 'Grrrowl!'],
      ['U', 'Unicorn', '\u{1F984}', 'Sparkle sparkle!'],
      ['V', 'Vulture', '\u{1F985}', 'Flap flap!'],
      ['W', 'Whale', '\u{1F433}', 'Splash!'],
      ['X', 'X-ray fish', '\u{1F420}', 'Blub blub!'],
      ['Y', 'Yak', '\u{1F403}', 'Moooo!'],
      ['Z', 'Zebra', '\u{1F993}', 'Neigh neigh!'],
    ];
    var i = 0;
    return rows.map((r) {
      return LearnItem(
        letter: r[0],
        name: r[1],
        glyph: r[2],
        spoken: '${r[0]}. ${r[1]}. ${r[3]}',
        accent: _accent(i++),
      );
    }).toList();
  }();
}
