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
the local database. Windows notification toasts are a known gap (see
`docs/ARCHITECTURE.md` §4). See that section for the full round-by-round
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
device/screen-reader pass.

## Get real compiler feedback today (do this first)

**Update: round 9 — CI ran again after round 8's fixes were pushed, and
this time both jobs failed for real, toolchain-specific reasons.**
Neither failure was something manual review could have caught; both
only exist because of the exact SDK/lint versions GitHub's runner
installed. `app-analyze` failed at `flutter pub get`: `app/pubspec.yaml`
pinned `intl: ^0.19.0`, but the installed Flutter SDK's
`flutter_localizations` requires `intl ^0.20.3`, and an app can never
pin lower than what that framework package demands — fixed by bumping
the pin. `calendar-engine-tests` failed at `dart analyze` with 33
`prefer_const_constructors` issues in `general_roman_calendar.dart` —
a rule this package's own `analysis_options.yaml` explicitly opts into,
so the fix was adding `const` at 33 call sites, not loosening CI. See
`docs/ARCHITECTURE.md` §4 (Round 9) for the full detail. **These fixes
have not been re-verified by CI yet** — push them and re-run to confirm
green.

Those two fixes were pushed and CI ran a third time: both jobs got
further (confirming the `intl` and const-constructor fixes worked) and
then failed on two *different*, smaller real issues — an unused import
(`computus.dart`, dead code in `calendar_engine.dart`, removed) and
another version-solving conflict (`share_plus ^9.0.0` vs. `drift`'s `web`
dependency; bumped to `^13.3.0`, the exact version pub's own resolver
suggested).

Those were pushed and CI ran a fourth time: both jobs finally got past
dependency resolution entirely and reached real analysis/test execution
— and each found something new. `dart test` failed 3 tests, and this
time it's a genuine logic bug, not a toolchain quirk: the calendar
engine's precedence tie-break used a signal (`CalendarSource.computed`)
that's shared by both the generic day filler *and* every named movable
celebration (Easter, Pentecost, Palm Sunday...), so on days where a
named Sunday-rank celebration and the filler tied for precedence, which
one displayed could depend on `List.sort`'s (not-guaranteed-stable)
tie order — Easter Sunday could show `goldPermitted: false`, Pentecost
could show white instead of red. Fixed with an unambiguous key-based
check. Separately, `flutter analyze` ran for the very first time in this
project's life and found 42 issues; only the log's tail was visible, and
4 of those (one missing import in a test file) plus a share_plus
deprecation notice are fixed.

Pushed again, and CI ran a fourth time: `dart test` is now fully
**green** (confirming the precedence-engine fix), and searching the
`app-analyze` log for "error" surfaced three real compile errors rather
than just lints. Two are the same root cause: `.equals(anEnumValue)`
on a drift column that stores an enum as text needs `.equalsValue(...)`
instead — drift's own docs confirm `.equals()` expects the raw stored
type (`String`), not the converted enum. **This means round 3's original
finding (that `.equalsValue()` "isn't a real drift method") was itself
wrong** — round 9 is what finally caught it for real. Fixed both flagged
call sites plus one more of the same kind found by grepping for the
pattern. The third error was a missing import (`swatchFor()` called
without importing the file that defines it) — fixed there, plus one more
call site found the same way. Also constified all 16 entries of
`builtin_templates.dart`, the same `prefer_const_constructors` pattern
from earlier in this round. See `docs/ARCHITECTURE.md` §4 (Round 9,
fourth CI run) for the full detail — likely still more to find on the
next run.

Pushed again, and CI ran a fifth time: down to 11 issues (from 42), and
this time all of them fit in one screenshot. Only 1 was a real error —
`SemanticsFlag` undefined in a test file (needed a direct `import
'dart:ui'`, since this Flutter SDK version doesn't surface it through
`material.dart` the way it used to) — fixed, alongside silencing one
deprecation notice on the same line whose replacement API (a new
tri-state `CheckedState` type) isn't confirmable without a real
compiler. The rest were a genuine Flutter breaking change: `RadioListTile`'s
`groupValue`/`onChanged` are deprecated in favor of an ancestor
`RadioGroup` widget (confirmed against Flutter's own migration docs) —
migrated `language_screen.dart` to the new pattern. Plus two more
`prefer_const_constructors` spots. See `docs/ARCHITECTURE.md` §4 (Round
9, fifth CI run). Not confirmed green yet — the pattern so far is that
each "looks done" screenshot has had more waiting above the fold, so
don't be surprised by a sixth round.

There was a sixth round: down to 5 issues, and this time the full list
fit on screen. All 5 were the same real concern —
`use_build_context_synchronously`, using a screen's `BuildContext` after
an `await` without checking it's still `mounted` first, which can throw
or silently misbehave if the user navigated away in the meantime. Fixed
across `inventory_screen.dart` (4 spots) and `admin_pin_screen.dart` (1
spot, fixed by reordering code so the context read happens before the
await instead of after). See `docs/ARCHITECTURE.md` §4 (Round 9, sixth
CI run). If this comes back green, it's the first fully clean
`app-analyze` run this project has ever had.

Before that, round 8's CI run passed clean on both jobs — the whole app
compiled with `flutter analyze` and every calendar-engine test passed on
a real, executed Dart runtime for the first time — but going on to write
real widget tests surfaced a critical bug analyze couldn't catch:
`main.dart`'s `MaterialApp` was missing `AppLocalizations.delegate` from
its localization setup, which would have crashed the app on launch in
every language. It's fixed, with a regression test added specifically to
catch it if it ever comes back. (An earlier version of this workflow
briefly added a third job that produced an actual runnable Windows
`.exe`; it was removed by request, so the two analyze/test jobs below
are what's current.) The walkthrough below is kept for anyone starting
fresh from this zip.

Every round of work on this project before that had been careful manual
review — this sandbox cannot install the Dart/Flutter SDK, so nothing
here had ever actually been compiled. The fastest way to close that, with
**no local Flutter install required**, is GitHub Actions:

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
