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
a working language picker, and (new in round 11) an admin-gated Checklist
Template Editor — add templates, add/delete/reorder their items — are all
implemented and functional against the local database. Windows notification toasts, reminders'
repeat-rule ('weekly'/'yearly') option, inventory's low-stock
*threshold* (as opposed to the manual low-stock toggle, which works),
and per-sacristan checklist attribution (`doneByProfileId`, and Sacristan
Profiles generally beyond the one used for the admin PIN) are
known gaps — each is stored in the schema but not wired up end to end
(see `docs/ARCHITECTURE.md` §4, rounds 2, 10, and 11). See that section
for the full round-by-round
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
Both fixed, both with new regression tests, and **confirmed green** —
these fixes and their tests have now actually run in CI, not just been
reasoned through. See `docs/ARCHITECTURE.md` §4 ("Round 10") for the
full reasoning. **Round 11** chased down one loose thread round 10 left
open — whether hardcoding the reminders' time zone to UTC could make
reminders fire at the wrong wall-clock time — and, by reading the
`timezone` package's own source for `TZDateTime.from`, confirmed it's
**not** a bug (the app already builds reminder times from the device's
real local clock; the hardcoded zone only affects a display label
nothing in the app reads back). It also found a second dead-schema gap
(inventory's `lowStockThreshold` column, unused end to end — same shape
as the reminders `repeatRule` gap), confirmed the CSV export's escaping
is handled correctly by the `csv` package, and — the round's biggest
find — every "Add" dialog in the app (plus the checklist-list's
tap-to-open flow) could create a duplicate row on a rapid double-tap,
since nothing disabled the triggering button while its `await`-based
insert was in flight. Fixed across all nine affected screens, plus the
underlying repository-level race in `ChecklistRepository
.findOrCreateInstance` (now lock-protected and covered by a new test
that opens a real, if temporary, in-memory database — the first test in
this project to do that instead of testing pure functions only). The
same round then found the identical race in the app's single most-used
interaction — `ChecklistRepository.setTick`, called on every checklist
checkbox tap — since the checkbox widget has no debounce and two fast
taps on the same row can both fire before either write lands; a
duplicate tick row there doesn't just create clutter, it makes every
later tap on that item throw instead of toggling. Fixed with an
order-preserving per-item lock (distinct from `findOrCreateInstance`'s
fix, since two taps can carry different intended values that must both
apply) and covered by its own new test. It also verified the pure-Dart
calendar engine's lectionary-cycle logic against USCCB's own FAQ rather
than assuming it (found correct, no change needed), and fixed a real UX
gap where the SMS "text this contact" buttons failed completely
silently on this app's Windows build (no `sms:` handler there) with no
feedback to the user. It also closed a real, actively-misleading gap:
two existing screens (`checklist_detail_screen.dart`'s empty-state text,
Settings' own "Admin PIN" subtitle) had always pointed sacristans to
"Settings > Manage Checklist Templates" — but that screen never existed;
every template a parish could use was exactly the built-in seed, with no
way to add, adjust, or extend it without a developer. Built the missing
screen (`ChecklistTemplateEditorScreen` + `TemplateItemsEditorScreen`,
wired into Settings under a new "Checklists" section), admin-gated the
same way the Reference Library already is, and — since the new
add/delete/reorder-item repository methods have the identical
check-then-write shape already found and fixed twice elsewhere this
round — serialized all three per template with the same
chain-onto-the-previous-call lock pattern `setTick` uses, with its own
new regression test covering the race directly. Deliberately did **not**
add template *deletion*: `ChecklistInstances.templateId` isn't
cascade-configured (unlike `ChecklistItems.templateId`), so deleting a
template any Mass has used would hit a foreign-key violation —
handling that well is a product decision left for a future round, not
guessed at here. See `docs/ARCHITECTURE.md` §4 ("Round 11") for
the full reasoning. Finally, found and fixed a real precedence-engine bug
in the calendar package itself — the same class of bug round 9's CI runs
caught twice, but this specific instance had survived every round since,
undetected by any existing test: a fixed General Roman Calendar solemnity
landing on a Sunday of Advent, Lent, or Easter (verified concretely: the
Immaculate Conception, Dec 8, falls on the Second Sunday of Advent in
2024 and 2030) could incorrectly outrank that Sunday as the day's primary
celebration, backwards from the Missal's own precedence rules and from
actual Church practice. Fixed with a new regression test covering both
years. Also found, but deliberately left undecided (a product question,
not a bug): `ChecklistTicks.doneByProfileId` — meant to record which
sacristan checked an item off — is never actually set to anything but
`null`, because nothing in the app lets a sacristan identify themselves
before checking items off; pulling on that thread, Sacristan Profiles
(other than the one used for the admin PIN) turn out to be stored but
never read anywhere else in the app. See `docs/ARCHITECTURE.md` §4 for
the reasoning. Last, found and fixed a real silent-data-loss-shaped bug:
the Parish/Diocesan Calendar editor's "Add entry" dialog let you pick a
Day (1-31) independent of the selected Month, with zero validation
anywhere — so saving, say, "February 31" succeeded silently, and that
entry would then never appear on the Dashboard or Calendar on any real
date, ever. Fixed by filtering the Day dropdown to the selected month's
real length and clamping an already-selected day down when the month
changes to one that's too short for it, with a new widget test (this
project's first to exercise a real dialog against a real, if temporary,
database) proving the clamp actually happens and only a real date gets
saved. None of round 11's fixes have been through a real CI run yet (the
last confirmed-green run was round 10's) — that's the next step,
followed by the real device/emulator smoke test this project has never
had.

**Round 12: the app ran on a real device for the first time — and crashed
on launch.** The user, new to Flutter, was walked through installing the
whole toolchain from scratch (Flutter SDK, Visual Studio's C++ desktop
workload, Windows Developer Mode for plugin symlink support) and running
`flutter run -d windows`. Twelve rounds and a green CI pipeline in, this
was the very first time SACRISTAN had ever actually executed — and it hit
a "red screen of death" before a single screen rendered: `AppTheme.light()`
/`.dark()` built its `textTheme` by calling `.apply(fontSizeFactor: 1.05)`
directly on `Typography.material2021(...).black`, which — confirmed by
reading Flutter's own SDK source rather than guessing — is a deliberately
*color-only* theme with no `fontSize` set on any of its 15 text styles;
`TextStyle.apply()` asserts `fontSize != null` whenever scaling by
anything other than 1.0, so this failed on every single field, on every
platform, every time. No round before this one had a compiler at all
(rounds 1-7), and CI (rounds 8-11) only ever ran static analysis and pure
unit tests — nothing had rendered a widget tree under the app's real theme
until now. **Fixed** by explicitly merging in the matching font-geometry
theme (`.merge(typography.englishLike)`) before scaling, and added
`app/test/theme/app_theme_builds_without_crashing_test.dart` — this
project's first test to actually pump a `MaterialApp` under
`AppTheme.light()`/`.dark()` and assert nothing throws. Also: this repo
had never had a `windows/` platform folder committed (nothing before this
round had a working `flutter` toolchain to generate one with), so
`flutter create --platforms=windows .` had to be run once first — not a
code bug, just a missing setup step, now documented so a fresh clone
doesn't hit the same confusing "No windows desktop project configured"
error blind. With the crash fixed, the app now genuinely launches and
renders on a real Windows machine.

**The same round then went on to a real Android phone too, over USB —
and SACRISTAN now runs on both of its testable platforms for the first
time.** Along the way: the same missing-platform-folder issue as Windows
(no one had ever run `flutter create --platforms=android .` either, same
root cause, same fix); a genuinely new Android SDK tool transition
(Google replacing `sdkmanager` with a new `android` CLI) that Flutter
3.47.0 hasn't fully caught up with yet, worked around by writing the
standard license-acceptance hash files directly (the same trick CI
systems use); Gradle's NDK auto-download crashing outright on this
machine, fixed by pinning `ndkVersion` in `android/app/build.gradle.kts`
to a version already installed rather than the one Flutter defaults to;
and one real, permanent, non-environmental fix — `flutter_local_notifications`
requires "core library desugaring," a genuine documented Android
requirement never triggered before because this was the project's first
real Android build. See `docs/ARCHITECTURE.md` §4 ("Round 12") for the
full reasoning on all of it. Further screens haven't been clicked
through by hand on either platform yet past initial launch, so that
remains the next real step, same as it's been since round 10.

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

# Windows installer — build the release binary, then compile
# installer/sacristan.iss with Inno Setup (see that file's own header
# comment for the one-time setup + build steps) to get a distributable
# SACRISTAN-Setup-<version>.exe. Microsoft Store packaging via MSIX is a
# separate, lower-priority stretch goal noted in STORE_CHECKLIST.md.
flutter build windows --release
```

## Icons

`app_icon_source.png` under `app/assets/reference/` is the app's real icon
(round 13) — a navy/gold monogram (a stylized "S" incorporating a cross,
chalice with host, thurible, and stole) full-bleed on white, matching the
user's original artwork. `app_icon_foreground.png` is a second,
transparent-background layer of the same artwork, inset further so it
isn't clipped by circular or squircle Android launcher masks —
`pubspec.yaml`'s `flutter_launcher_icons` block points
`adaptive_icon_foreground` at it and sets `adaptive_icon_background` to
`#FFFFFF` to match. Regenerate every platform-specific icon file from
these two sources with:

```bash
cd app
dart run flutter_launcher_icons
```

If the icon ever changes again, replace both files (keeping the foreground
layer's extra inset margin) and re-run the command above — see
`docs/ARCHITECTURE.md`'s round 13 entry for why the source needed real
image prep rather than being used as supplied.

## What remains before each store submission

See `docs/STORE_CHECKLIST.md` for the full punch list. As of round 13, the
privacy policy is drafted and hosted (published as a standalone page — ask
in the project for the current URL) and the icon is finished; screenshots,
listing-copy review, and both stores' paid developer-account steps remain
open.

## License / attribution

No copyrighted Missal or Lectionary text is bundled. See the in-app
**Settings → About & Attribution** screen (`app/lib/features/settings/settings_screen.dart`)
for the full attribution statement, and `docs/STORE_CHECKLIST.md` for the
privacy-policy text to publish alongside the store listings.
