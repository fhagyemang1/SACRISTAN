# SACRISTAN 1.1.0 — Release Notes

**Released:** October 2026
**Tag:** `v1.1.0` · **Installer:** `SACRISTAN-Setup-1.1.0.exe`

## What's new

### The liturgical calendar is now complete for fixed dates (Round 16)

A sacristan opened the app on **October 1, 2026** and saw an ordinary green
weekday where the Church keeps the **Memorial of St. Thérèse of the Child
Jesus** (white) — and the same the next day for the **Holy Guardian Angels**.
The app's calendar data simply didn't have those dates yet.

This release fixes that, and goes much further:

- **Fixed-date coverage grew from 37 to 150 celebrations.** Every fixed date
  in the parish reference calendar we crosschecked against — a Ghana
  Catholic Church perpetual liturgical calendar on the General Roman
  Calendar base — is now represented in the app, including all the
  memorials, feasts, and optional memorials the previous subset skipped.
- **Colors now display correctly year-round.** Memorial-rank and above
  entries drive the day's color (white for confessors and Marian days, red
  for martyrs, and so on), so a date like Oct 1 no longer renders as plain
  Ordinary Time green.
- **Optional memorials are listed but never override the day.** By the
  Roman Missal's own precedence rules, an optional memorial is an
  *option*, not the day's celebration — the app now shows them the same
  way: offered, not imposed.

## What was verified before release

Every one of these claims was confirmed by real runs, not assumed:

- `dart analyze --fatal-infos` on the calendar package: no issues.
- `dart test` on the calendar package: **162/162 tests pass**, including
  new Round 16 regression tests pinning Oct 1/Oct 2 across three years
  *and* pinning the precedence outcomes on the harder dates (Sundays,
  Lenten weekdays, and Holy Family Sunday must still win over the new
  entries — the saints stay visible as secondaries, never dropped).
- `flutter analyze` and `flutter test` on the app: no issues, **44/44 pass**.
- The Windows installer (`SACRISTAN-Setup-1.1.0.exe`) was rebuilt from the
  tested source, replacing the 1.0.0 build.

## Notes for upgrading

- No breaking changes, no data migration. The calendar dataset ships as
  app data, not a database table, so updating the app updates the calendar.
- If you have parish-specific dates entered in the local calendar editor,
  they are untouched and continue to take whatever precedence their rank
  deserves, exactly as before.
- Reminder behavior (exact alarms, battery-optimization guidance) is
  unchanged from 1.0.0.

## Known limitations (unchanged)

- Celebration *names* remain English-only; the scoped French/Spanish
  localization from Round 14 covers navigation and vocabulary, not
  proper names.
- The optional-memorial color recorded in the dataset is not load-bearing
  by design — only Memorial rank and above change the day's color.
