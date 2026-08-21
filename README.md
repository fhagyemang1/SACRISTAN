# SACRISTAN

An offline-first companion for Catholic sacristans — the laypeople and clergy
who prepare the sacristy, vestments, sacred vessels, and altar for Mass and
other liturgical celebrations. Built with Flutter for iOS, Android, and
Windows desktop from a single codebase. See `docs/ARCHITECTURE.md` for the
full stack decision and data model.

**Build status of this delivery:** the liturgical calendar engine, data
layer, dashboard, calendar-detail, checklist screens (now with multi-Mass
support), local calendar editor, admin PIN gate, inventory edit/delete +
CSV export, contacts/suppliers with SMS deep-links, local
reminders/notifications, a DB-backed and admin-editable reference library,
and a working language picker are all implemented and functional against
the local database. Windows notification toasts, and reminders'
repeat-rule ('weekly'/'yearly') option, are known gaps — stored in the
schema but not wired up end to end (see `docs/ARCHITECTURE.md` §4,
rounds 2 and 10). See that section for the full round-by-round
breakdown, including a real bug (`.equalsValue()`, not a real drift method)
caught and fixed during manual review in round 3, and — in round 4's full
line-by-line review of every screen — a genuinely user-visible bug where
every built-in checklist item was displaying a crude derived label instead
of its actual authored guidance text (now fixed), plus a Flutter
version-constraint mismatch (also fixed). **Round 5** found that the
Language picker changed nothing visible despite shipped French/Spanish
translations — `AppLocalizations` was never actually wired into the UI
(a stray comment had claimed otherwise). Navigation labels, the
liturgical color/rank/season vocabulary, and a few other chrome strings
now genuinely switch language; built-in checklist item text, most dialog
copy, and calendar celebration *names* remain English-only — see
`docs/ARCHITECTURE.md` §4 for the honest, current breakdown of what is
and isn't localized. **Round 6** reviewed the calendar engine itself
against the Missal's actual precedence rules and found Monday-Wednesday
of Holy Week had no entries at all — they showed as generic "Lenten
Weekday" and had no protection against being outranked by a local-calendar
solemnity, when in the real rubrics these three days outrank everything.
Both are now fixed, with new regression tests and an independent Python
date cross-check. **Round 7** ran a dedicated accessibility pass: found
and fixed 5 icon-only buttons across the app with no screen-reader label,
and verified (with an independent contrast calculation, not just by eye)
that every liturgical color pairing clears WCAG AA contrast — see
`docs/ARCHITECTURE.md` §4 and `docs/STORE_CHECKLIST.md`'s new
Accessibility section for what's verified versus what still needs a real
device/screen-reader pass. **Round 10** reviewed what CI's now-green
state genuinely can't check — cross-session and runtime-probabilistic
behavior — and found two real bugs: every table's primary-key generator
(`newId()`) relied on timing + `identityHashCode` for uniqueness, neither
of which is actually guaranteed, risking a crash on the app's very first
launch during its ~100-row seeding loop; and reminder notifications
derived their OS-level id from `.hashCode`, which Dart's own docs say
isn't guaranteed stable across app restarts — meaning a "canceled"
reminder could still fire after the app had been closed and reopened.
Both fixed, both with new regression tests. See `docs/ARCHITECTURE.md`
§4 ("Round 10") for the full reasoning.

## Real compiler feedback: CI is green

**CI is fully green as of round 9.** Both jobs —
`liturgical_calendar package — dart test` and `app-analyze` (pub get,
codegen, `flutter analyze`, `flutter test`) — pass clean, with real
tests and real lint rules enforced (no `continue-on-error`, no
`--fatal-infos` loosened to get there). This is the first time in this
project's life that's been true.

Getting here took six real CI runs in round 9 alone, each one catching
something a compiler can see and manual review can't: a precedence-engine
logic bug in the calendar's date-resolution tie-break, a drift API
misuse from round 3 that had gone undetected for six rounds (it turned
out `.equalsValue()` — the method round 3 had "fixed" away — was the
correct one all along), two missing imports, a Flutter framework
breaking change (`RadioListTile`'s API redesign), and five
`BuildContext`-used-after-`await` bugs. Full details, in the order the
compiler actually found them, are in `docs/ARCHITECTURE.md` §4 under
"Round 9."

**What green CI does and doesn't mean:** `flutter analyze` and
`dart test`/`flutter test` check types, lints, and this project's own
test assertions — they never launch the app on a device or simulator.
A clean run is necessary but not sufficient for "this app works." The
next-highest-value step is a real `flutter run` on an actual device or
emulator — the one thing no sandbox or CI job in this project's history
has done yet.

If you're starting fresh from this zip and want to see that CI pass
yourself (or extend it), here's the same setup used above — **no local
Flutter install required**, via GitHub Actions:

1. Create a new (empty) repository on GitHub — public or private, either
   works.
2. Push this project's contents to it (or use GitHub's "Add file → Upload
   files" web UI if you'd rather not use git from the command line — just
   drag the whole extracted `SACRISTAN` folder in).
3. Open the repo's **Actions** tab. `.github/workflows/ci.yml` (already
   included in this delivery) runs automatically on the first push. It
   installs Flutter fresh on GitHub's own runner (which has full internet
   access, unlike this sandbox), then runs `dart test` on the calendar
   engine and `flutter analyze` on the whole app — the two checks that
   matter most right now.
4. Whatever comes back red is real, actionable — paste the failing step's
   log back into this conversation (or share the repo link) and it can be
   fixed with actual compiler feedback instead of another round of manual
   reading.

If you already have Flutter installed locally, that's even faster: skip
GitHub entirely and just run the "First-time setup" commands below,
directly.

## Repository layout

```
SACRISTAN/
├── docs/ARCHITECTURE.md, STORE_CHECKLIST.md
├── packages/liturgical_calendar/   pure-Dart calendar engine + tests
├── app/                            the Flutter app (iOS/Android/Windows)
├── tools/                          dev-only verification & asset scripts
└── illustrations_preview.html      quick look at the bundled line-art
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22+ (includes Dart 3.3+)
- For iOS builds: a Mac with Xcode
- For Android builds: Android Studio / the Android SDK & a JDK
- For Windows builds: Windows 10/11 with Visual Studio (Desktop development with C++ workload)

Check `flutter doctor` after installing to confirm each target you plan to
build for is green.

## First-time setup

```bash
# 1. Get the pure-Dart calendar engine's dependencies and run its tests
cd packages/liturgical_calendar
dart pub get
dart test
cd ../..

# 2. Get the app's dependencies
cd app
flutter pub get

# 3. Generate the drift database code (creates lib/data/database.g.dart)
#    and the localization classes (creates lib/l10n/app_localizations.dart)
dart run build_runner build --delete-conflicting-outputs

# 4. Generate platform folders (ios/, android/, windows/) — these are not
#    checked into this delivery; `flutter create` regenerates the standard
#    platform scaffolding Flutter needs, then layers your existing pubspec.yaml
#    and lib/ on top of it.
flutter create . --platforms=ios,android,windows --org com.yourparish.sacristan
```

> **A note on how this repo was produced:** this project was scaffolded in a
> sandboxed build environment whose network policy allowlists a handful of
> package registries (npm, pub-adjacent proxies, PyPI, crates.io, the Go
> module proxy) but not `storage.googleapis.com` / `dl.google.com`, which is
> where the Dart and Flutter SDKs themselves are distributed. That means the
> Dart/Flutter toolchain could not be installed there, and steps 1–4 above
> (and `flutter run`, `flutter build`, `flutter analyze`) have **not** been
> executed inside that environment. What *was* verified by actual execution
> there: an independent Python re-implementation of the exact same Easter
> computus algorithm (`tools/verification/verify_calendar_engine.py`),
> checked against a 51-year ground-truth table (2000–2050, fetched live from
> a public reference) plus the historical year 1943, and a 60-year span of
> structural invariants (Easter always a Sunday, always within its canonical
> calendar window, Ordinary Time's last week always numbering 34). Run
> `python3 tools/verification/verify_calendar_engine.py` yourself to see
> that pass. The Dart test suite in
> `packages/liturgical_calendar/test/calendar_engine_test.dart` mirrors the
> same ground-truth table and additional structural/precedence checks — run
> it with `dart test` once you have the SDK installed (step 1 above) to get
> a directly-executed result. **Before you rely on this app in production,
> run that full test suite yourself and treat any newly-introduced code the
> same way — this note is not a substitute for your own CI run.**

## Running each target locally

```bash
cd app

# iOS (on a Mac, with a simulator open or a device attached)
flutter run -d ios

# Android (with an emulator running or a device attached, USB debugging on)
flutter run -d android

# Windows desktop (on Windows, after the C++ desktop workload is installed)
flutter run -d windows
```

## Running the calendar engine's tests only

The calendar engine has zero Flutter dependency, so its tests run with the
plain Dart SDK — no emulator, simulator, or Flutter install required:

```bash
cd packages/liturgical_calendar
dart test
```

## Building release artifacts

```bash
cd app

# Android App Bundle (what Play Console wants)
flutter build appbundle --release

# iOS (then open ios/Runner.xcworkspace in Xcode to archive & upload)
flutter build ios --release

# Windows installer — build the release binary, then package it with your
# installer tool of choice (e.g. Inno Setup, MSIX via `flutter pub run
# msix:create` if you add the `msix` package). Microsoft Store packaging via
# MSIX is a low-cost stretch goal noted in STORE_CHECKLIST.md.
flutter build windows --release
```

## Icons

`app_icon_source.png` under `app/assets/reference/` is a simple original
placeholder (a chalice + cross mark on the app's seed color). Regenerate
platform icons from it with:

```bash
cd app
dart run flutter_launcher_icons
```

Replace `app_icon_source.png` with your parish/organization's real icon
before submitting to either store — see `docs/STORE_CHECKLIST.md`.

## What remains before each store submission

See `docs/STORE_CHECKLIST.md` for the full punch list (icons, screenshots,
privacy policy text, listing copy, and store-specific gotchas).

## License / attribution

No copyrighted Missal or Lectionary text is bundled. See the in-app
**Settings → About & Attribution** screen (`app/lib/features/settings/settings_screen.dart`)
for the full attribution statement, and `docs/STORE_CHECKLIST.md` for the
privacy-policy text to publish alongside the store listings.
