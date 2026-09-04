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
/// `calendar_engine.dart`'s `_defaultCelebration`). Round 6 flagged this
/// as a latent risk ("no reproducible bug was found from it") and
/// round 9's first real `dart test` run found the reproducible bug: a
/// named movable solemnity and the filler can land in the same
/// precedence tier (Easter Sunday, Pentecost — both top-tier and on a
/// Sunday), and a same-[source] tie-break couldn't tell them apart,
/// silently preferring whichever the (not-guaranteed-stable) sort left
/// first. `calendar_engine.dart` no longer uses [source] to identify the
/// filler — `_isGenericFiller()` there checks the filler's `key` prefix
/// (`'default'`) instead, which every filler celebration has and no
/// named one ever does. [source] itself is unchanged and still correctly
/// distinguishes [generalRomanCalendar]/[localSupplement] origin; only
/// the filler-vs-named distinction moved off of it.
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

  /// True only for a [CelebrationRank.feast] that is a genuine "Feast of
  /// the Lord in the General Calendar" (Table of Liturgical Days, General
  /// Norms n. 59, tier II.5) — e.g. the Presentation of the Lord, the
  /// Transfiguration, the Baptism of the Lord. Meaningless for any other
  /// rank (solemnities/memorials/etc. don't need this distinction; a
  /// solemnity already outranks every Sunday of Ordinary Time/Christmas
  /// regardless, and nothing below feast rank ever competes with a
  /// Sunday). Feasts of the BVM or of the Saints in the General Calendar
  /// (tier II.7) must leave this `false` (the default) — unlike Feasts of
  /// the Lord, they rank *below* Sundays of Ordinary Time and of the
  /// Christmas season, per `calendar_engine.dart`'s `_tier()`. See that
  /// function's doc comment for the concrete bug this distinction fixes.
  final bool isFeastOfTheLord;

  const Celebration({
    required this.key,
    required this.name,
    this.latinName,
    required this.rank,
    required this.color,
    required this.source,
    this.goldPermitted = false,
    this.isFeastOfTheLord = false,
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
