# SACRISTAN — Architecture & Stack Decision

## 1. Tech stack decision: Flutter

**Chosen stack: Flutter (Dart), targeting iOS, Android, and Windows desktop from one codebase.**

### Why Flutter over the alternatives

| Criterion | Flutter | .NET MAUI | React Native (+ RN Windows) |
|---|---|---|---|
| Offline local-database maturity | `sqlite3`/`sqflite` and `drift` (type-safe SQL, migrations, reactive streams) are mature, widely used, offline-first by design | SQLite via `sqlite-net-pcl`/EF Core is workable but EF Core's mobile story has more rough edges historically | SQLite via `op-sqlite`/`WatermelonDB`; solid, but RN Windows is a separate, less-maintained fork with lagging parity |
| Single-codebase parity across iOS/Android/Windows | Windows desktop is a first-class, actively maintained Flutter embedder (same as iOS/Android); genuinely one UI codebase | MAUI officially supports Windows (via WinUI) plus iOS/Android from one codebase — also strong here | React Native's Windows target (`react-native-windows`) is community-maintained by Microsoft but historically trails the core RN release cadence, and desktop layout/gesture parity is weaker |
| App-store review track record | Huge installed base of shipped Flutter apps on both stores; Apple/Google review teams are very familiar with Flutter's binary signature (no known systemic rejection patterns) | Good track record, smaller sample size than Flutter/RN | Good track record, but RN's JS-bridge architecture has occasionally drawn extra scrutiny for apps that dynamically load JS bundles (not our case, since we ship a static bundle) |
| Long-term maintainability by a small/volunteer team | One language (Dart) for all UI and business logic, one widget system, one styling model, hot reload for fast iteration, huge Stack Overflow/pub.dev ecosystem | C#/XAML — very approachable for teams with .NET background, but the Windows-first WinUI styling model doesn't always transfer cleanly to mobile idioms | JS/TS is the most widely known language, but bridging native modules (notifications, SMS, contacts) usually still requires touching native iOS/Android code, which raises the bar for a volunteer team |
| Accessibility (VoiceOver/TalkBack/Narrator) | Built-in `Semantics` widget tree maps directly to all three platforms' accessibility APIs | Strong, native accessibility tree | Strong, native accessibility tree, but a bit more manual wiring per platform historically |
| Package ecosystem for our specific needs (local notifications, SQLite, PDF/CSV export, SMS deep-links) | `flutter_local_notifications`, `drift`/`sqflite`, `pdf`/`csv`, `url_launcher` (for `sms:` deep links) are all mature, actively maintained, offline-capable | Equivalent MAUI packages exist but are less battle-tested in combination | Equivalent RN packages exist; SMS/notifications require native linking per platform |

**Verdict:** Flutter wins on the two criteria that matter most for this project — offline-database maturity and true single-codebase parity across all three required targets — while remaining the most learnable option for a small or volunteer team (one language, one widget model, excellent docs). This is the stack used for everything below.

**Local data layer:** [`drift`](https://drift.simonbinder.eu/) on top of `sqlite3_flutter_libs`/`sqflite`, giving compile-time-checked SQL, streaming queries (so the UI updates live as checklists are ticked), and a straightforward migration path. The bundled liturgical calendar dataset ships as a versioned Dart const dataset (not a database table) inside the pure-Dart `liturgical_calendar` package described below, so it can be improved in a future app release without any migration of user data.

**Package split:** the liturgical calendar engine lives in its own pure-Dart package (`packages/liturgical_calendar`) with **no Flutter dependency at all**. This is a deliberate architecture choice, not just tidiness:

- It can be unit-tested with the plain `dart test` runner — no emulator, simulator, or even Flutter SDK required — which is what makes the "20-year span of known correct dates" requirement actually verifiable in CI and in constrained environments.
- It is reusable outside the app (e.g. a future companion CLI or web reference tool) without dragging in Flutter.
- It keeps the hardest, most safety-critical logic (getting Easter and its dependent dates *right*) isolated from UI churn.

**Future cloud sync:** the `app/lib/data` layer talks to `drift` through repository classes (`ChecklistRepository`, `InventoryRepository`, …), never directly from UI code. A future optional sync feature would add a `SyncEngine` that watches the same repositories' change streams and pushes/pulls through a pluggable `SyncBackend` interface — no rewrite of screens or the local schema required. This is documented but **not implemented** in this build, per the offline-first requirement.

## 2. Data model

### 2.1 Calendar engine domain (pure Dart, no database — computed/looked up on demand)

```
LiturgicalDay
├─ date: DateTime (local, midnight)
├─ season: LiturgicalSeason (advent | christmas | ordinaryTime | lent | triduum | easter)
├─ weekOfSeason: int
├─ color: LiturgicalColor (violet | white | red | green | rose | gold | black)
├─ rank: CelebrationRank (solemnity | feast | memorial | optionalMemorial | sunday | ferial)
├─ celebrations: List<Celebration>   // can be >1 (e.g. optional memorial alongside a ferial)
├─ sundayCycle: SundayCycle? (A | B | C)   // set on Sundays and solemnities that borrow the Sunday readings
└─ weekdayCycle: WeekdayCycle? (I | II)    // set on ferial weekdays

Celebration
├─ name: String                 // localized via l10n keys, e.g. "stJosephTheWorker"
├─ latinName: String?
├─ rank: CelebrationRank
├─ color: LiturgicalColor
├─ isProper: bool               // true if from a local/diocesan supplementary calendar
└─ source: CalendarSource (generalRomanCalendar | localSupplement)

LocalCalendarEntry (user-editable, imported/edited fully offline)
├─ id, month, day (or movable-date rule for a handful of cases), name, latinName, rank, color, notes
└─ stored in the drift database (`local_calendar_entries` table), layered on top of the bundled GRC at resolution time
```

### 2.2 App/user data (SQLite via `drift`, `app/lib/data/database.dart`)

```
profiles            id, display_name, role (admin | volunteer), pin_hash?, locale, created_at
parishes            id, name, address, timezone_note
suppliers           id, name, contact_name, phone, notes
masses              id, date, label ("8:00 AM Sunday Mass"), mass_type (sunday|weekday|funeral|
                        wedding|baptism|benediction|holyWeek), celebrant_name?, notes
checklist_templates id, name, mass_type, phase (pre|post), is_builtin, locale
checklist_items     id, template_id, sort_order, label_key, label_custom?, latin_term?
checklist_instances id, mass_id, template_id, created_at
checklist_ticks     id, instance_id, item_id, is_done, done_at, done_by_profile_id
inventory_items     id, category (chasuble|stole|alb|linen|vessel|candle|incense|hosts|wine|other),
                        name, color, condition, storage_location, quantity, low_stock_threshold,
                        low_stock_flag, notes
notes               id, linked_type (date|mass|checklist_item), linked_id, body, created_at
reminders           id, title, body, trigger_at, repeat_rule?, linked_note_id?, is_active
contacts            id, role (pastor|sacristan|serverLeader), name, phone
reference_entries   id, category (girmExcerpt|glossaryTerm|rubricNote), title, body_md,
                        source_citation, illustration_asset?
app_settings        key, value   // locale, theme, admin_pin_hash, etc.
```

All tables are created and versioned through `drift`'s schema migration system (`schemaVersion`, `MigrationStrategy`), so future columns/tables (e.g. a `sync_state` column) can be added without destructive migrations.

### 2.3 Why the calendar engine is *not* in SQLite

Feast dates depend on Easter, which depends on the year, which is unbounded ("years in the future" is an explicit requirement). Storing a flat table of dates would mean either shipping a finite pre-computed table (breaks for far-future years, or is enormous) or recomputing anyway. Instead the engine computes `LiturgicalDay` objects on demand for any `DateTime`, in well under a millisecond, and the *only* things persisted to SQLite are (a) the small, versioned local-supplement table a parish edits, and (b) references from user data (masses, notes) to plain `DateTime`s — never to a precomputed feast-date table.

## 3. Repository layout

```
SACRISTAN/
├── docs/
│   ├── ARCHITECTURE.md            (this file)
│   └── STORE_CHECKLIST.md
├── packages/
│   └── liturgical_calendar/       (pure Dart, zero Flutter dependency)
│       ├── lib/
│       │   ├── liturgical_calendar.dart      (public API barrel)
│       │   └── src/
│       │       ├── models.dart               (LiturgicalDay, Celebration, enums)
│       │       ├── computus.dart              (Easter date algorithm)
│       │       ├── season_engine.dart         (season/week/color/rank resolution)
│       │       ├── cycles.dart                 (Sunday A/B/C, weekday I/II)
│       │       ├── general_roman_calendar.dart (bundled GRC fixed-date dataset)
│       │       └── local_calendar.dart         (merges an optional local supplement)
│       ├── test/
│       │   └── calendar_engine_test.dart
│       └── pubspec.yaml
├── app/                            (Flutter app — iOS + Android + Windows)
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme/app_theme.dart
│   │   ├── l10n/ (en, fr, es .arb files)
│   │   ├── data/ (drift database + repositories)
│   │   └── features/
│   │       ├── dashboard/
│   │       ├── calendar_detail/
│   │       ├── checklists/
│   │       ├── inventory/
│   │       ├── reference/
│   │       ├── notes/
│   │       ├── settings/
│   │       └── common/ (shared widgets: big touch-target checkbox, color chip, etc.)
│   └── assets/reference/ (original SVG line-art)
├── tools/verification/             (Python cross-check script used only during development,
│                                      not shipped in the app — see README)
└── README.md
```

## 4. Build-depth note for this delivery

**Round 1** (initial MVP+ scope): the calendar engine, data layer, dashboard, calendar-detail, and checklist screens fully implemented and functional against the local database. Inventory, reference library, notes/reminders, and settings screens scaffolded with working navigation, models, and sample data.

**Round 2** (this pass): filled in most of the round-1 scaffolding —
- **Local calendar editor** (Settings → Parish/Diocesan Calendar): add/delete offline supplementary-calendar entries, live on the Dashboard/Calendar immediately.
- **Admin PIN gate** (`data/admin_session.dart`, `features/settings/admin_pin_screen.dart`): salted-hash PIN (never stored in plaintext), in-memory unlock per app session, gating Inventory edit/delete as a worked example of the pattern — apply the same `AdminSession.isUnlocked` check to any other admin-only action.
- **Inventory edit/delete** and a **low-stock CSV shopping-list export** (`share_plus` hands the file to whatever app the user picks — Mail, Messages, Files — no bundled server).
- **Contacts & Suppliers** screen, plus a **"text a low-stock alert"** action on Inventory: both use `url_launcher`'s `sms:` deep link to open the device's own Messages app pre-filled — not an SMS gateway integration, no account or API key involved.
- **Reminders**, scheduled through `flutter_local_notifications` on Android/iOS/macOS/Linux. **Known gap: Windows has no native notification backend in that package** — reminders still save and list correctly on Windows, they just can't pop a system toast there; see the doc comment in `data/notifications_service.dart` for the swap-in fix (`local_notifier`) if that matters for your parish's desktop use.

Reference library content and locale coverage (beyond the en/fr/es strings already shipped) remain the same additive next-step work described in round 1.

**Round 3** (this pass):
- **Reference Library is now DB-backed**: bundled glossary/GIRM/rubric entries seed into the `ReferenceEntries` table on first launch; a parish can add its own entries (admin-gated) or delete any entry — the static lists in `reference_data.dart` are now only the seed source, not the runtime source of truth.
- **Language picker** (Settings → Language): persists the chosen locale to `AppSettings` via a new `LocaleController`, applied through `MaterialApp.locale` — switching is immediate and survives an app restart.
- **Multi-Mass support for checklists**: tapping a template now looks up today's existing Masses of that type via the new `MassRepository`; with zero or one Mass it proceeds immediately (no extra tap for the common single-Mass-parish case), with more than one it prompts "Which Mass?" (including "New Mass…"). `ChecklistRepository.findOrCreateInstance` also fixes a real bug from round 1/2: re-opening a checklist previously always created a brand-new blank instance, silently orphaning prior progress — it now resumes the existing instance for that (Mass, template) pair.
- **Bug fix**: several database queries (`repositories.dart`, `admin_pin_screen.dart`) called a method, `.equalsValue()`, that isn't part of drift's real API — a mistake introduced in round 2, corrected to `.equals()` in this pass. Caught by manual review, not by compilation (still no Dart SDK in this sandbox — see below).
- **Second attempt at installing the Dart SDK**: the sandbox's egress allowlist blocks `pub.dev`, `dart.dev`, and the GitHub releases API outright (not just the storage host tried in round 1), confirming this is a deliberate policy exclusion rather than one blocked host. No further attempts are likely to succeed from this environment; the Python cross-check from round 1 remains the standing executed verification of the calendar engine, and manual review remains the verification method for the Flutter/drift code — **run `dart test` and `flutter analyze` yourself before relying on this in production.**

**Round 4** (this pass): a full line-by-line manual review of every file under `app/lib`, cross-checking each repository method's signature against every call site (still the only verification method available — see above; the Dart/Flutter SDK remains unavailable in this sandbox). Findings, most significant first:
- **User-visible bug fixed: built-in checklist item text was never displayed.** `main.dart`'s `seedBuiltinTemplatesIfNeeded()` stored each built-in item's `labelKey` (a machine key, e.g. `"missalRibbons"`) and `latinTerm`, but never stored `item.label` — the actual authored guidance text (e.g. *"Missal and ribbons set to today's readings"*). `checklist_detail_screen.dart`'s fallback for a missing localization silently prettified the raw key into Title Case instead (`"Missal Ribbons"`), so every built-in checklist across all seven Mass types was showing crude derived labels rather than the real guidance that was written for them. Fixed by adding `labelCustom: Value(item.label)` to the seeding insert — `labelCustom` already took display priority over the key fallback, so the real text now shows immediately with no other code changes needed.
- **Version-constraint bug fixed**: the UI (`app_theme.dart` and three other files) uses `Color.withValues(alpha: ...)`, a Flutter 3.27+ API, but `pubspec.yaml` declared a Flutter 3.22+ minimum — meaning a build against the stated minimum could fail to resolve that method. Fixed by raising `environment.flutter` to `>=3.27.0` and `environment.sdk` to `>=3.6.0 <4.0.0`.
- **Two smaller defensive fixes in `admin_pin_screen.dart`**: an immediately-invoked async function expression was rewritten with explicit parentheses (`await (() async {...})()`) for unambiguous parsing rather than relying on Dart accepting the unparenthesized form; and `_adminProfile` is now updated locally right after a new admin profile/PIN is created, so the screen's `_hasPin` check stays correct even if a future edit removes the immediate `Navigator.pop()`.
- **Everything else reviewed clean**: `database.dart`, `repositories.dart` (all thirteen repository classes, cross-checked against every screen that calls them), `dashboard_screen.dart`, `calendar_detail_screen.dart`, `app_shell.dart`, `color_chip.dart`, `big_checkbox_tile.dart`, `sms_helper.dart`, `notes_screen.dart`, `inventory_screen.dart`, `reference_screen.dart` + `reference_data.dart`, `contacts_suppliers_screen.dart`, `local_calendar_editor_screen.dart`, `profiles_screen.dart`, `reminders_screen.dart`, `language_screen.dart`, `settings_screen.dart`, `checklist_list_screen.dart`, `builtin_templates.dart`, `locale_controller.dart`, `admin_session.dart`, and `notifications_service.dart` — no further bugs found. Notably, the `DropdownButtonFormField(initialValue: ...)` pattern used across six screens is applied consistently everywhere in the app (no screen still uses the older `value:` parameter), so if that pattern needs adjusting for a specific Flutter version it is a single, uniform find-and-replace.
- As in round 3: this pass is manual review, not compilation. **Run `dart test`, `flutter analyze`, and `flutter run` yourself before relying on this in production** — that remains the one step this sandbox cannot perform for you.

**Round 5** (this pass): a documentation-vs-code discrepancy check found and fixed a second genuinely user-visible gap, on top of continuing the review pattern established in round 4.
- **Localization was claimed but not actually wired.** `app_en.arb`/`app_fr.arb`/`app_es.arb` have shipped since round 1 with translations for navigation labels, liturgical color/rank/season vocabulary, and a few other strings, and a stray code comment in `checklist_detail_screen.dart` claimed this was "wired through AppLocalizations for the primary navigation and dashboard strings." It wasn't — a repo-wide search found exactly zero call sites using `AppLocalizations` outside that one comment. The Language picker (Settings → Language) changed `MaterialApp.locale`, which affects built-in Material widgets (date pickers, etc.) but none of the app's own text — switching to French or Spanish visibly changed nothing. **Fixed**: `color_chip.dart`'s `rankLabel`/`seasonLabel`/color-name functions, `app_shell.dart`'s bottom-nav labels and app-bar title/tooltips, `settings_screen.dart`'s title, the checklist list's "Before/After Mass" subtitle, and the Inventory/Notes "Add" button labels now all read through `AppLocalizations`, matching every key the ARB files already defined. Verified by re-checking every call site of the two changed function signatures (`rankLabel`/`seasonLabel` now take `BuildContext`).
- **What's still English-only, documented honestly rather than re-claimed as done**: the ~130 built-in checklist item labels, remaining dialog/screen copy (titles, hints, error messages), and — the bigger structural item — the celebration/feast *names* themselves, which live in the pure-Dart `liturgical_calendar` package as plain English strings and are outside Flutter's l10n system entirely. Translating ~45+ liturgical celebration names accurately is a content task for a bilingual reviewer familiar with liturgical terminology, not a mechanical string-table swap, and was deliberately not attempted here. See the updated doc comment in `checklist_detail_screen.dart` for the full, current, accurate status — replacing the round-1 comment that overstated it.
- Manual review only, as in every prior round — **run `dart test` / `flutter analyze` / `flutter run` yourself.**

**Round 6** (this pass): shifted focus to the pure-Dart `liturgical_calendar` package itself — the safety-critical core that round 1's Python cross-check only verified for Easter's *date*, not for season/rank/precedence logic. A full read of `computus.dart`, `season_engine.dart`, `calendar_engine.dart`, `general_roman_calendar.dart`, `cycles.dart`, and `models.dart` against the Roman Missal's General Norms for the Liturgical Year, n. 59 (Table of Liturgical Days).
- **Real content/precedence gap found and fixed**: Monday, Tuesday, and Wednesday of Holy Week had no explicit entries anywhere — they fell through to the generic Lenten-weekday filler, so a sacristan checking, say, Holy Tuesday would see "Lenten Weekday, Week 6" rather than anything naming Holy Week. Worse, per the Missal's General Norms n. 59, these three days sit in the very top precedence tier (I.2) alongside Ash Wednesday and the four great solemnities — nothing may be celebrated in their place, not even a solemnity — but the engine's precedence table (`_tier` in `calendar_engine.dart`) had no rule protecting them, so a parish adding a patronal solemnity via the local calendar editor that happened to land on one of these three days in a given year would have incorrectly displayed that solemnity as primary instead of "Monday/Tuesday/Wednesday of Holy Week." **Fixed**: added `mondayHolyWeek`/`tuesdayHolyWeek`/`wednesdayHolyWeek` to `MovableDates` (`computus.dart`), three new named movable celebrations in `general_roman_calendar.dart`, and extended the top-precedence key set in `_tier()` (renamed from `topSolemnityKeys` to `topPrecedenceKeys` for accuracy, since Ash Wednesday and these three days are ferial in *rank* but top-tier in *precedence*) to include them. Added regression tests (`calendar_engine_test.dart`) covering both the naming and the local-calendar-can't-override behavior; independently re-verified the three new day-of-week offsets in Python across five years (all Monday/Tuesday/Wednesday as expected, cross-checked against the same computus formula).
- **Documented, not changed, a subtler structural note**: `CalendarSource.computed` is shared by both movable named celebrations (Ash Wednesday, Easter, Trinity Sunday, etc.) and the generic per-day filler — meaning the source-based tie-break in `resolveLiturgicalDay` doesn't actually distinguish a movable celebration from filler by source (precedence tiering handles that correctly instead). This only matters in the rare case of two same-tier candidates from different sources on one day; no reproducible bug was found from it, so a source-enum split was deliberately not attempted without a compiler to verify the refactor — see the doc comment now on `CalendarSource` in `models.dart`.
- Everything else in the package (`computeEasterSunday`, `adventFirstSunday`, `baptismOfTheLord`, `holyFamily`, `christTheKing`, `weekStartingSunday`, the Ordinary Time part-1/part-2 week-numbering algorithms, the Sunday/weekday lectionary cycle logic) was traced by hand against the real liturgical rules and found correct, including the backward-from-34 Ordinary Time Part 2 numbering technique, which is the right approach and matches the round-1 60-year invariant test already in place.
- Manual review only — **run `dart test` yourself**; the three new day fixtures above are new since round 1's Python cross-check and have not been executed by any test runner.

**Round 7** (this pass): a dedicated accessibility pass — the original spec calls for accessibility compliance, and no round so far had checked it as its own focused item (only individual widgets like `BigCheckboxTile` had accessibility considerations baked in from round 1).
- **Icon-only buttons missing accessibility labels, found and fixed**: a repo-wide sweep for every `IconButton` found 5 of 17 with no `tooltip` set — on `IconButton`, Flutter uses `tooltip` as both the visible long-press hint *and* the screen-reader semantic label, so a missing one means a screen-reader user hears nothing useful for that control. Fixed: the delete buttons on Profiles, Contacts, and Suppliers now say "Delete {name}" (naming the specific item, not just "Delete"), and the inventory quantity +/- steppers now say "Decrease/Increase quantity."
- **Contrast checked, not just assumed**: every `swatchFor()` background/foreground color pairing in `theme/app_theme.dart` was run through the actual WCAG relative-luminance contrast formula in an independent Python script (not eyeballed) — all seven liturgical colors clear 6.5:1, comfortably above the 4.5:1 AA threshold for normal text. No fix needed here; documented as verified rather than left as an unchecked assumption.
- **`docs/STORE_CHECKLIST.md` gained an Accessibility section** listing what's verified (color+text pairing, contrast, touch targets, icon-button labels) versus what still needs a real device pass (an actual screen reader, and system text-scaling/layout overflow) — neither of which this sandbox can perform without a Flutter runtime.
- Manual review + one independently-executed contrast calculation — same standing caveat as every round: **a real screen-reader pass on a physical device remains the step this sandbox cannot do for you.**

**Round 8** (this pass): a user actually ran this project's CI on GitHub Actions — the first real, executed compiler/test feedback this project has ever gotten. Both jobs came back green (`dart test` on the calendar engine, `flutter analyze` on the whole app). That's genuinely good news, but it also proved a point made throughout this document: static analysis passing is not the same as the app working, because this round found a bug analyze could never have caught.
- **Critical runtime bug found and fixed**: `main.dart`'s `MaterialApp` never included `AppLocalizations.delegate` in its `localizationsDelegates` list — only the three Flutter-framework delegates (Material/Widgets/Cupertino). Every `AppLocalizations.of(context)!` call added in round 5 (the nav bar, `rankLabel`/`seasonLabel`, several screen titles and buttons) uses a null-assertion on that call's result. Without the delegate registered, `Localizations.of<AppLocalizations>(context, AppLocalizations)` always returns null — meaning `AppShell.build()`, which calls this on its very first line, would have thrown "Null check operator used on a null value" and crashed the app immediately on launch, in every locale, every single time. This is a real, severe, previously-undiscovered defect that seven prior rounds of manual review — including the round-5 pass that did the localization wiring itself — missed, because it's a *runtime widget-registration* problem, not a type error, and nothing short of actually running the app (or a targeted widget test) surfaces it. Fixed by adding the import and the delegate to the list, with a comment explaining exactly why.
- **Real app-level tests added** (`app/test/`, previously empty — the CI `flutter test` step existed since round 6 but was `continue-on-error: true` for lack of anything to run): `l10n_delegate_test.dart` pumps a `MaterialApp` with the app's real delegate list and asserts `AppLocalizations.of(context)` actually resolves in all three shipped locales — a direct regression test for the bug above, so it cannot silently reappear. `theme/app_theme_contrast_test.dart` ports round 7's one-off external Python contrast check into a permanent `flutter test` against the real `swatchFor()` function, so every liturgical color pairing is re-verified on every CI run instead of relying on a script outside the repo. `features/common/big_checkbox_tile_test.dart` covers the tap-to-toggle interaction and checked-state semantics of the core checklist widget. The CI workflow's `flutter test` step no longer has `continue-on-error: true` — it now genuinely gates the build.
- This is the clearest evidence yet for the standing message in this document: **manual review has a ceiling, and running the actual app is not optional.** The next most valuable step is a real device/emulator smoke test (`flutter run`) — nothing shy of that would have caught this bug before a real sacristan did.

**Round 9** (this pass): the user pushed round 8's fixes to their GitHub repo and re-ran CI — this time both jobs actually failed, and unlike round 8's find, neither failure was something manual review had a chance of catching: both only exist because of specifics of the installed toolchain versions on the runner. This is the first round where every finding came purely from a real, executed build/test run rather than any reading of the code.
- **`app-analyze` job failed at `flutter pub get`** with a version-solving error: `app/pubspec.yaml` pinned `intl: ^0.19.0`, but the Flutter SDK version GitHub's runner installed ships a `flutter_localizations` that itself depends on `intl ^0.20.3` — an app can never pin a lower `intl` than what `flutter_localizations` (a framework package, not something this repo controls) demands. **Fixed**: bumped the pin to `intl: ^0.20.3` in `app/pubspec.yaml`, with a comment noting that if a future Flutter upgrade shifts this requirement again, `flutter pub get`'s own error message names the exact version to use — it's not a value to guess at. No app code imports `intl` directly (only the generated localization code and `flutter_localizations` itself use it), so this was a safe, contained fix.
- **`calendar-engine-tests` job failed at `dart analyze`** with 33 `prefer_const_constructors` issues, all in `packages/liturgical_calendar/lib/src/general_roman_calendar.dart`. Every entry in `generalRomanCalendarFixed` was written as `FixedCelebration(month, day, const Celebration(...))` — the inner `Celebration(...)` was already `const`, but the outer `FixedCelebration(...)` call (itself a `const` constructor, being fed only integer literals and a const `Celebration`) was not, so it could have been `const` and the linter said so. This is exactly the rule this package's own `analysis_options.yaml` explicitly opts into (`prefer_const_constructors: true`, not just whatever `package:lints/recommended.yaml` defaults to) — so the correct fix was the code, not loosening the CI's `--fatal-infos` flag to let the repo's own declared lint rule go unenforced. **Fixed**: all 33 call sites now read `const FixedCelebration(month, day, Celebration(...))` — `const` moved to the outer call, redundant inner `const` removed. Every non-`const` object allocation on every calendar lookup is now avoided, a small but real performance benefit alongside satisfying the linter.
- Both fixes were verified by direct inspection against the CI's own logged error messages (the exact `intl` version the resolver named, and the exact rule/line pattern the analyzer flagged) rather than guessed at — but, as always, **this sandbox still cannot run `flutter pub get` or `dart analyze` itself to confirm; the next CI run is the real confirmation.**
- Manual review only, verified line-for-line against the round-8 CI failure screenshots — **push these two fixes and re-run CI to get the real confirmation.**
