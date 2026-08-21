/// SACRISTAN's offline Roman Catholic liturgical calendar engine.
///
/// Pure Dart, no network access, no Flutter dependency. See
/// `docs/ARCHITECTURE.md` in the repo root for the design rationale.
library liturgical_calendar;

export 'src/calendar_engine.dart' show resolveLiturgicalDay;
export 'src/computus.dart' show computeEasterSunday, MovableDates, DateShift;
export 'src/cycles.dart' show sundayCycleFor, weekdayCycleFor;
export 'src/general_roman_calendar.dart'
    show
        FixedCelebration,
        generalRomanCalendarFixed,
        movableCelebrationsForYear;
export 'src/local_calendar.dart' show LocalCalendarEntry;
export 'src/models.dart';
export 'src/season_engine.dart'
    show
        adventFirstSunday,
        baptismOfTheLord,
        holyFamily,
        christTheKing,
        resolveSeason,
        SeasonResolution;
