# Kiddly — Play Store Release Requirements

Outstanding work required before Kiddly can be published on Google Play.
Audited against the project as of **17 August 2026**.

**Audit baseline (all currently passing):**

- Flutter 3.44.7 (stable) · Dart 3.12.2
- `flutter analyze` → No issues found
- `flutter test` → 6/6 passing
- `flutter build appbundle --release` → succeeds, `app-release.aab` (52.6 MB)
- Application ID `com.kiddly.app` · versionName `1.0.0` · versionCode `1`
- compileSdk/targetSdk **36**, minSdk 21 · No runtime permissions requested
- No `INTERNET` permission — the app is genuinely offline

> **Scope note:** This document covers Google Play only. App Store / iOS-specific
> requirements are deliberately excluded.

---

## Table of contents

1. [Hard blockers](#1-hard-blockers)
2. [Technical fixes before upload](#2-technical-fixes-before-upload)
3. [Play Console setup](#3-play-console-setup)
4. [Individual account — 14-day closed testing](#4-individual-account--14-day-closed-testing)
5. [Suggested order of work](#5-suggested-order-of-work)
6. [Pre-upload checklist](#6-pre-upload-checklist)

---

## 1. Hard blockers

These will cause rejection, removal, or account termination. None are optional.

### 1.1 Copyrighted third-party characters 🚩

**Severity: critical — risk of account termination, not just rejection.**

`lib/data/heroes.dart` references, and the AAB bundles, artwork of characters
owned by other companies:

| File | Character | Rights holder |
| --- | --- | --- |
| `spiderman.jpeg` | Spider-Man | Marvel / Disney |
| `hulk.jpeg` | Hulk | Marvel / Disney |
| `iron_man.jpeg` | Iron Man | Marvel / Disney |
| `batman.jpeg` | Batman | DC / Warner Bros. |
| `superman.jpeg` | Superman | DC / Warner Bros. |
| `tom.jpeg`, `tom_and_jerry.jpeg` | Tom & Jerry | Warner Bros. |
| `cocomelon.jpeg`, `melon_child.jpeg` | Cocomelon | Moonbug Entertainment |
| `motu_patlu.jpeg`, `motu_patlu_tow.jpeg` | Motu Patlu | Cosmos-Maya / Viacom18 |

Confirmed present in the built bundle under
`base/assets/flutter_assets/assets/images/heroes/`.

**Why this blocks release**

- Violates Google Play's **Impersonation and Intellectual Property** policy.
- Kiddly is child-directed, so it enters the **Families programme** and receives
  **manual human review** — this is caught reliably, not probabilistically.
- Marvel, DC, WB and Moonbug all run active takedown programmes against kids'
  apps. A takedown strike on an individual developer account can escalate to
  permanent account termination, which also bars re-registration.

**Required action**

- Replace every hero with **original artwork you own or have licensed**.
- The data model already supports this cleanly — each hero is one entry in
  `Heroes` needing only a name, an image path, and three colors, so this is an
  asset swap, not a code rewrite.
- Options: commission original characters, use a permissively-licensed set with
  documented provenance (keep the licence files), or revive the procedural
  `HeroPainter` path that already exists in `heroes.dart` as legacy code.
- Also review `assets/images/home_garden_bg.jpg` for the same problem, and any
  emoji-adjacent artwork added later.
- Keep written proof of ownership/licence for every asset — Play may ask for it
  during review.

### 1.2 Release build is signed with the debug key 🚩

`android/app/build.gradle.kts` still carries the Flutter template default:

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Play rejects debug-signed artifacts outright.

**Required action**

1. Generate an upload keystore:

   ```bash
   keytool -genkey -v -keystore ~/kiddly-upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (**never commit this**):

   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=/Users/<you>/kiddly-upload-keystore.jks
   ```

3. Wire it into `android/app/build.gradle.kts`:

   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       // ...
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String
               keyPassword = keystoreProperties["keyPassword"] as String
               storeFile = file(keystoreProperties["storeFile"] as String)
               storePassword = keystoreProperties["storePassword"] as String
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

4. Add to `.gitignore`:

   ```gitignore
   **/android/key.properties
   **/*.jks
   **/*.keystore
   ```

5. Back the keystore up somewhere durable. Losing it means you can never update
   the app under the same listing.
6. Enroll in **Play App Signing** (default for new apps) so Google holds the
   final app signing key and your upload key stays recoverable.

### 1.3 No hosted privacy policy URL 🚩

The policy text currently lives only inside the app, in the `_PrivacyNote`
widget in `lib/features/parent/parent_zone_screen.dart`. Play requires a
**publicly accessible URL**, entered in the Console, for every child-directed
app — in-app text does not satisfy this.

**Required action**

- A ready-to-host policy has been written to `docs/privacy-policy.html`.
- Fill in the placeholders marked in that file (developer name, contact email,
  effective date).
- Host it. Easiest free option — GitHub Pages from the `docs/` folder:
  push the repo, then *Settings → Pages → Source: main branch, `/docs` folder*.
  Resulting URL: `https://<username>.github.io/<repo>/privacy-policy.html`
- Verify the URL loads publicly in a private browser window, with no login.
- Enter it in **Play Console → Policy → App content → Privacy policy**, and in
  the store listing.
- Optionally link to it from the Parent Zone alongside the existing note.

---

## 2. Technical fixes before upload

### 2.1 Text-to-speech package visibility (Android 11+)

`flutter_tts` does not declare the TTS query itself — the merged release
manifest contains only the `PROCESS_TEXT` query. Under Android 11 package
visibility rules, TTS engine discovery can therefore fail on some devices, which
would silently break narration — a core feature.

Add to `android/app/src/main/AndroidManifest.xml`, inside the existing
`<queries>` block:

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.TTS_SERVICE" />
    </intent>
    <!-- existing PROCESS_TEXT intent stays here -->
</queries>
```

Test narration on a physical Android 11+ device after the change.

### 2.2 Remove dead assets from the bundle

`assets/images/heroes/` contains two unreferenced files that are still shipped:

- `batman.jpg` — 549 KB (unused; `batman.jpeg` is the referenced one)
- `spider_man.jpg` — 544 KB (unused; `spiderman.jpeg` is the referenced one)

Delete both. ~1.1 MB saved. This becomes moot if §1.1 is done first, but verify
no orphans remain afterwards.

### 2.3 Compress icon source artwork

- `assets/icon/icon.png` — ~1.0 MB
- `assets/icon/icon_foreground.png` — ~0.96 MB

These are generation-time inputs only and are not bundled, but they bloat the
repo. Compress and re-run:

```bash
dart run flutter_launcher_icons
```

Keep the foreground bubble at 90% of the canvas — the sizing rationale in
`pubspec.yaml` explains why, and shrinking it breaks the adaptive icon safe zone.

### 2.4 Declare backup behaviour explicitly

`android:allowBackup` is unset, so it defaults to `true`. Child profiles and
rewards stored via `shared_preferences` will sync to Google Backup. This is
legal and low-risk, but should be a decision rather than a default. Set it
explicitly on `<application>`:

```xml
android:allowBackup="false"
```

…if you would rather keep all child data strictly on-device. Whichever you
choose, make sure the privacy policy matches.

### 2.5 Put the project under version control

The project is not currently a git repository. Not a Play requirement, but you
should not ship a signed app with no history — and `.gitignore` needs to be
active *before* the keystore exists so it is never committed.

```bash
git init && git add . && git commit -m "Initial commit"
```

### 2.6 Confirm version numbers

`pubspec.yaml` is at `version: 1.0.0+1`. Correct for a first release. Remember
that **versionCode must strictly increase** on every upload — even for a
re-upload after a rejected review.

---

## 3. Play Console setup

Nothing below has been started yet. All items in §3.1 are mandatory gates.

### 3.1 App content declarations

**Policy → App content**

- [ ] **Privacy policy** — the hosted URL from §1.3
- [ ] **App access** — "All functionality is available without special access";
      note that the Parent Zone is behind a press-and-hold gate, not a login
- [ ] **Ads** — "No, my app does not contain ads" (accurate; no ad SDKs present)
- [ ] **Content rating** — complete the IARC questionnaire. Expect *Everyone / 3+*.
      Answer honestly: no violence, no user-generated content, no sharing, no
      purchases, no location, no external links
- [ ] **Target audience and content** — select the **children's age bands**.
      This is what puts the app into the **Families programme** and triggers
      manual review. Do not attempt to avoid this — the store listing and
      artwork make the target audience obvious, and misdeclaring is itself a
      policy violation
- [ ] **Data safety** — declare **no data collected and no data shared**. This
      is accurate: no `INTERNET` permission, everything persists locally via
      `shared_preferences`. If §2.4 leaves backup enabled, that is still not
      "collection" by Play's definition, but keep the answer consistent with
      the privacy policy
- [ ] **Government apps** — No
- [ ] **Financial features** — None
- [ ] **Health apps** — No
- [ ] **Advertising ID** — declare that the app does **not** use it (no SDK
      requests it)

### 3.2 Families programme specifics

Because the target audience includes children:

- [ ] App must comply with the **Designed for Families** requirements
- [ ] Any ads SDK would have to be on Google's self-certified list — **N/A**,
      Kiddly has none. Keep it that way; adding an arbitrary ad network later
      would break compliance
- [ ] No collection of personal or sensitive data from children — currently
      satisfied
- [ ] The privacy policy must specifically address children's data (the
      supplied `docs/privacy-policy.html` does)
- [ ] Interest-based advertising and remarketing to children are prohibited
- [ ] Expect a **longer review time** — plan for several days, not hours

### 3.3 Store listing assets

None of these exist in the project yet.

| Asset | Requirement |
| --- | --- |
| App icon | 512 × 512 PNG, 32-bit, **no alpha channel** |
| Feature graphic | 1024 × 500 PNG/JPEG, no transparency |
| Phone screenshots | 2–8 required. 16:9 or 9:16, 320–3840 px per side |
| 7" tablet screenshots | **Required** — the app supports tablets |
| 10" tablet screenshots | **Required** — the app supports tablets |
| App name | ≤ 30 characters |
| Short description | ≤ 80 characters |
| Full description | ≤ 4000 characters |

Notes:

- Tablet screenshots are mandatory here because nothing restricts the app to
  phones. If you would rather skip them, you must actively declare the app as
  phone-only — but a kids' app on a tablet is a strong use case, so produce them.
- Screenshots must show **actual app content**. Do not add promotional frames
  that misrepresent the UI, and do not show any character artwork from §1.1.
- Avoid words like "best", "#1", "top" in the listing — Play flags superlatives.
- Do not imply endorsement by any brand or franchise.

### 3.4 Release configuration

- [ ] Choose countries/regions for distribution
- [ ] Set pricing (free — note that a free app can never be switched to paid)
- [ ] Complete the US export compliance declaration
- [ ] Upload the signed AAB to the chosen track
- [ ] Write release notes for the first version

---

## 4. Individual account — 14-day closed testing

As an **individual developer account** registered after November 2023, Google
requires you to run a closed test before production access is granted:

- **12 testers minimum**, each having **opted in** to the closed test
- They must remain opted in **continuously for 14 days**
- Testers must be recruited via email list or Google Group in the Console
- Only after the 14 days can you **apply for production access**, which is
  itself a reviewed application asking about your testing and your app

**This is the longest lead time in the whole process — start it first.**

Practical guidance:

- Recruit 14–15 testers, not exactly 12, to absorb dropouts
- Testers must actually install from the Play testing link; adding an email
  without an install does not count
- The 14-day counter **resets** if you drop below 12 opted-in testers
- You can keep pushing new builds to the closed track during the 14 days —
  fixes do not restart the clock, only tester count does
- Note that §1.1 must still be fixed before you upload even to a closed test;
  the IP problem is not deferred by the track you choose

---

## 5. Suggested order of work

1. **Replace the hero artwork** (§1.1) — longest creative task and it blocks
   every upload, including closed testing.
2. **Set up release signing** (§1.2), add the **TTS query** (§2.1), and strip
   the **dead assets** (§2.2). Put the repo under git (§2.5) before the keystore
   exists.
3. **Host the privacy policy** (§1.3) and build a signed AAB:
   ```bash
   flutter build appbundle --release
   ```
4. **Upload to closed testing**, recruit 12+ testers, **start the 14-day clock**
   (§4). Everything after this runs in parallel with the waiting period.
5. **Fill in Console declarations** (§3.1, §3.2) and produce **listing assets**
   (§3.3) while the test runs.
6. **Apply for production access** once 14 days have elapsed, then promote the
   release.

---

## 6. Pre-upload checklist

Run through this immediately before every AAB upload.

**Code and build**

- [ ] All hero/background artwork is original or licensed, with proof retained
- [ ] `signingConfigs.getByName("release")` is wired up; no debug signing
- [ ] `key.properties` and `*.jks` are gitignored and not committed
- [ ] TTS `<queries>` entry added and narration verified on Android 11+ hardware
- [ ] Unused assets removed from `assets/`
- [ ] `android:allowBackup` set deliberately
- [ ] versionCode incremented past the last uploaded build
- [ ] `flutter analyze` clean
- [ ] `flutter test` passing
- [ ] `flutter build appbundle --release` succeeds
- [ ] Release AAB installed and smoke-tested on a physical device:
      splash → home → each of the 12 worlds → parent gate → rewards persistence

**Console**

- [ ] Privacy policy URL live and publicly reachable
- [ ] All App content declarations submitted
- [ ] Target audience set to children's age bands
- [ ] Data safety form matches the privacy policy exactly
- [ ] Content rating questionnaire completed
- [ ] Phone + 7" + 10" tablet screenshots uploaded
- [ ] Icon (512², no alpha) and feature graphic (1024 × 500) uploaded
- [ ] Short and full descriptions written, free of superlatives and brand claims
- [ ] Countries, pricing, and export compliance set
