/// Core domain types for the liturgical calendar engine.
///
/// Kept deliberately free of any Flutter dependency so this package can be
/// unit tested with the plain `dart test` runner.
library;

/// The six liturgical seasons of the Roman Rite calendar.
enum LiturgicalSeason {
  advent,
  christmas,
  ordinaryTime,
  lent,
  triduum,
  easter,
}

/// Liturgical colors used in the Roman Rite.
///
/// [gold] is treated as a permitted substitute for [white] on especially
/// solemn days (most commonly Christmas and Easter) rather than as a
/// distinct required color — the engine marks eligibility via
/// [LiturgicalDay.goldPermitted] instead of asserting gold outright, since
/// whether a parish actually has gold vestments varies.
enum LiturgicalColor { violet, white, red, green, rose, gold, black }

/// The rank (degree of solemnity) of a celebration, per the Roman Missal's
/// General Norms for the Liturgical Year and the Roman Calendar.
///
/// Ordered here from highest to lowest so `index` can be used as a rough
/// precedence signal where a finer-grained precedence table isn't needed.
enum CelebrationRank {
  triduum,
  solemnity,
  feast,
  sunday,
  memorial,
  optionalMemorial,
  ferial,
}

/// Which source a celebration came from — the bundled General Roman
/// Calendar, or a parish/diocesan local supplement entered offline.
///
/// Note: [computed] covers two different things that share one value —
/// movable, Easter-dependent named celebrations (Ash Wednesday, Easter,
/// Pentecost, Trinity Sunday, etc. — see `general_roman_calendar.dart`'s
/// `movableCelebrationsForYear`) *and* the generic per-day filler
/// ("5th Sunday in Ordinary Time", "Lenten Weekday, Week 3" — see
/// `calendar_engine.dart`'s `_defaultCelebration`). `calendar_engine.dart`
/// relies on its precedence *tier* (not this source value) to prefer a
/// named movable celebration over the generic filler when both land on
/// the same day; the source-based tie-break in `resolveLiturgicalDay`
/// only meaningfully distinguishes [generalRomanCalendar]/[localSupplement]
/// entries from a same-tier [computed] one, not movable celebrations from
/// filler among themselves. Splitting this into two distinct enum values
/// (e.g. `movable` vs `defaultFiller`) would be a cleaner design but is
/// deferred as a non-trivial refactor across every use of `_mv`/
/// `_defaultSource` — flagged here rather than attempted without a
/// compiler to verify the change.
enum CalendarSource { generalRomanCalendar, computed, localSupplement }

/// Sunday lectionary cycle (three-year cycle of Sunday readings).
enum SundayCycle { a, b, c }

/// Weekday lectionary cycle (two-year cycle of weekday readings).
enum WeekdayCycle { i, ii }

/// A single celebration that may occur on a given date (a solemnity, feast,
/// memorial, optional memorial, or the "ferial"/plain-weekday designation).
///
/// A [LiturgicalDay] may carry more than one [Celebration] — for example an
/// optional memorial that is available but outranked by the ferial weekday
/// of a privileged season, or several optional memorials offered on the
/// same day.
class Celebration {
  /// Stable key used for localization lookups, e.g. `"stJosephTheWorker"`.
  final String key;

  /// English display name (fallback / default locale).
  final String name;

  /// Traditional Latin name, when one is customarily used, e.g.
  /// `"Nativitas Domini"`.
  final String? latinName;

  final CelebrationRank rank;
  final LiturgicalColor color;
  final CalendarSource source;

  /// True if the vestment color may be gold in place of [color] (only ever
  /// set alongside [LiturgicalColor.white]).
  final bool goldPermitted;

  const Celebration({
    required this.key,
    required this.name,
    this.latinName,
    required this.rank,
    required this.color,
    required this.source,
    this.goldPermitted = false,
  });

  @override
  String toString() => '$name (${rank.name}, ${color.name})';
}

/// The fully-resolved liturgical description of a single calendar date.
class LiturgicalDay {
  final DateTime date;
  final LiturgicalSeason season;

  /// 1-based week number within the season, where applicable
  /// (e.g. "2nd Sunday of Advent" -> weekOfSeason == 2). For the Triduum
  /// this is always 1.
  final int weekOfSeason;

  /// All celebrations offered on this day, ordered by precedence
  /// (highest precedence first). [primary] is always `celebrations.first`.
  final List<Celebration> celebrations;

  final SundayCycle? sundayCycle;
  final WeekdayCycle? weekdayCycle;

  const LiturgicalDay({
    required this.date,
    required this.season,
    required this.weekOfSeason,
    required this.celebrations,
    this.sundayCycle,
    this.weekdayCycle,
  });

  Celebration get primary => celebrations.first;

  LiturgicalColor get color => primary.color;
  CelebrationRank get rank => primary.rank;
  bool get goldPermitted => primary.goldPermitted;

  bool get isSunday => date.weekday == DateTime.sunday;

  @override
  String toString() =>
      '${date.toIso8601String().substring(0, 10)}: ${primary.name} '
      '[${season.name} wk$weekOfSeason, ${primary.rank.name}, ${primary.color.name}]';
}
