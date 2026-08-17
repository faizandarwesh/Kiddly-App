# Kiddly 🎈

A bright, highly-animated, **offline-first learning playground for children ~1–5**.
Open it, tap anywhere, and something delightful happens — the whole app is built
around *play → explore → interact → discover → learn → celebrate*.

## Highlights

- **Interactive home world** — a living sky of sun, clouds, birds, butterflies,
  balloons and stars (each reacting to touch), above a scrollable tray of 12
  colorful worlds with staggered entrances and glossy shine sweeps.
- **Twelve playable worlds:**
  - *Learning:* ABC, Numbers (tap-to-count), Colors (find-the-color),
    Shapes (magic shape→object transform), Animals (habitat sounds),
    Food, Vehicles (drive/fly across the stage).
  - *Creative:* Music (rainbow xylophone + instruments, synthesized notes),
    Draw (finger-paint canvas with templates, palette, erase, clear).
  - *Games:* Puzzle (shape-sorter, snap-to-place), Match (memory pairs),
    Basket (drag & drop).
- **Bobbie the Bunny** — a hand-drawn (`CustomPainter`) mascot that breathes,
  blinks and cheers.
- **Fancy but subtle motion everywhere** — animated shifting gradients, idle
  floats, spring bounces, sparkle bursts, confetti, animated reward counters.
- **Positive-only** — no failure states; wrong taps get a friendly wiggle and a
  "Try again!". Correct actions get confetti, stars and praise.
- **Rewards** — collect ⭐ → 🌈 → 💖, persisted per child profile.
- **Parent Zone** — behind a press-and-hold gate: sound/music/voice toggles,
  child profiles, progress, and a privacy note.

## Design decisions

- **No binary assets.** All visuals are emoji + `CustomPainter` + gradients;
  all voice is device **text-to-speech**; all sound effects are **synthesized at
  runtime** as WAV bytes (`core/services/tone_synth.dart`). The app is fully
  self-contained and works offline.
- **Data-driven content.** Letters, numbers, animals, etc. are all instances of
  one `LearnItem` model (`data/`). Adding content = adding data, not screens.
- **Curated dependencies only:** `flutter_tts`, `shared_preferences`,
  `audioplayers`.

## Project layout

```text
lib/
  main.dart            # bootstrap: load settings/profiles, init audio
  app.dart             # MaterialApp + theme
  core/
    theme/             # colors, text styles, theme
    services/          # audio (TTS+SFX), tone synth, haptics, settings, profiles
    models/            # child profile
    widgets/           # bouncy, floaty, mascot, celebration, sparkle, HUD, scaffold
  data/                # LearnItem model + datasets (alphabet, numbers, animals)
  features/
    splash/  home/  parent/
    abc/  numbers/  colors/  shapes/  animals/  fruits/  vehicles/
    music/  drawing/  games/ (matching, drag_drop, puzzle)
```

Adding a new world is one entry in `lib/features/home/activities.dart` — the
home grid renders the rest.

## Run

```bash
flutter pub get
flutter run          # any device / emulator
flutter test         # unit tests for content + tone synth
```

## Roadmap (not yet built)

Interactive Story mode, and the world-unlock / worlds-map progression
(Forest → Ocean → Space …) remain, and fit the same data-driven architecture.
