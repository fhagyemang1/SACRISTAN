import 'computus.dart';
import 'models.dart';

/// Returns the First Sunday of Advent for [year]: the Sunday closest to the
/// Feast of St. Andrew (Nov 30), i.e. the Sunday falling between Nov 27 and
/// Dec 3 inclusive of [year].
DateTime adventFirstSunday(int year) {
  for (var day = 27; day <= 30; day++) {
    final d = DateTime.utc(year, 11, day);
    if (d.weekday == DateTime.sunday) return d;
  }
  for (var day = 1; day <= 3; day++) {
    final d = DateTime.utc(year, 12, day);
    if (d.weekday == DateTime.sunday) return d;
  }
  throw StateError('unreachable: no Sunday found in Nov27-Dec3 for $year');
}

/// Returns the date of the Baptism of the Lord for [year], observed on the
/// General Roman Calendar's fixed Jan 6 Epiphany: the Sunday after Jan 6,
/// except that when Jan 6 itself falls on a Sunday, the Baptism of the Lord
/// is kept the following Monday (Jan 7).
DateTime baptismOfTheLord(int year) {
  final jan6 = DateTime.utc(year, 1, 6);
  if (jan6.weekday == DateTime.sunday) return jan6.addDays(1);
  final offset = (7 - jan6.weekday) % 7;
  return jan6.addDays(offset == 0 ? 7 : offset);
}

/// Returns the date of the Feast of the Holy Family: the Sunday within the
/// Octave of Christmas (Dec 26-31), or Dec 30 in years when Christmas Day
/// itself falls on a Sunday (leaving no other Sunday in the octave).
DateTime holyFamily(int year) {
  for (var day = 26; day <= 31; day++) {
    final d = DateTime.utc(year, 12, day);
    if (d.weekday == DateTime.sunday) return d;
  }
  return DateTime.utc(year, 12, 30);
}

/// The Solemnity of Christ the King: the last Sunday of Ordinary Time,
/// i.e. the Sunday immediately before the First Sunday of Advent.
DateTime christTheKing(int year) => adventFirstSunday(year).subtractDays(7);

/// The Sunday (Sun-Sat week) that "owns" [date]: for a Sunday this is the
/// date itself, for any other weekday it is the most recent preceding
/// Sunday.
DateTime weekStartingSunday(DateTime date) {
  final offset = date.weekday % 7; // Sunday(7)->0, Monday(1)->1, ... Sat(6)->6
  return date.subtractDays(offset);
}

/// Resolved season + week-of-season for [date], independent of which
/// specific celebration falls on the day (that's layered on top by
/// `calendar_engine.dart`).
class SeasonResolution {
  final LiturgicalSeason season;
  final int weekOfSeason;
  const SeasonResolution(this.season, this.weekOfSeason);
}

SeasonResolution resolveSeason(DateTime date) {
  final year = date.year;
  final md = MovableDates.forYear(year);
  final christmasThisYear = DateTime.utc(year, 12, 25);
  final advent1ThisYear = adventFirstSunday(year);

  // --- January: either tail end of Christmas season, or early Ordinary Time ---
  if (date.month == 1) {
    final baptism = baptismOfTheLord(year);
    if (!date.isAfter(baptism)) {
      return const SeasonResolution(LiturgicalSeason.christmas, 1);
    }
    // Ordinary Time, Part 1: week 1 begins the day after the Baptism.
    return SeasonResolution(
      LiturgicalSeason.ordinaryTime,
      _otPart1Week(date, baptism),
    );
  }

  // --- Lent: Ash Wednesday through the day before Holy Thursday ---
  if (!date.isBefore(md.ashWednesday) && date.isBefore(md.holyThursday)) {
    return SeasonResolution(LiturgicalSeason.lent, _lentWeek(date, md));
  }

  // --- Triduum: Holy Thursday through Holy Saturday (Easter Vigil begins
  //     the Easter season proper at nightfall; day-granularity treats
  //     Easter Sunday itself as day 1 of Easter, below) ---
  if (!date.isBefore(md.holyThursday) && date.isBefore(md.easterSunday)) {
    return const SeasonResolution(LiturgicalSeason.triduum, 1);
  }

  // --- Easter season: Easter Sunday through Pentecost inclusive ---
  if (!date.isBefore(md.easterSunday) && !date.isAfter(md.pentecost)) {
    final daysSince = date.difference(md.easterSunday).inDays;
    final week = 1 + (daysSince ~/ 7);
    return SeasonResolution(LiturgicalSeason.easter, week > 7 ? 7 : week);
  }

  // --- Late in the year: Ordinary Time part 2, Advent, or early Christmas ---
  if (date.month >= 11 || date.month == 12) {
    if (date.isBefore(advent1ThisYear)) {
      return SeasonResolution(
        LiturgicalSeason.ordinaryTime,
        _otPart2Week(date, year),
      );
    }
    if (date.isBefore(christmasThisYear)) {
      final daysSince = date.difference(advent1ThisYear).inDays;
      final week = 1 + (daysSince ~/ 7);
      return SeasonResolution(LiturgicalSeason.advent, week > 4 ? 4 : week);
    }
    return const SeasonResolution(LiturgicalSeason.christmas, 1);
  }

  // --- Everything else between Pentecost and late-Nov Ordinary Time part 2 ---
  return SeasonResolution(
    LiturgicalSeason.ordinaryTime,
    _otPart2Week(date, year),
  );
}

int _lentWeek(DateTime date, MovableDates md) {
  final lent1Sunday = md.ashWednesday.addDays(4); // 1st Sunday of Lent
  if (date.isBefore(lent1Sunday)) return 0; // days right after Ash Wednesday
  final daysSince = date.difference(lent1Sunday).inDays;
  return 1 + (daysSince ~/ 7);
}

int _otPart1Week(DateTime date, DateTime baptism) {
  // The day after the Baptism begins "Week 1" (no Sunday of its own — the
  // Baptism of the Lord occupies that slot); the next Sunday begins Week 2.
  final anchorSunday = weekStartingSunday(baptism);
  final weekSunday = weekStartingSunday(date);
  final weeksSince = weekSunday.difference(anchorSunday).inDays ~/ 7;
  return 1 + weeksSince;
}

int _otPart2Week(DateTime date, int year) {
  final md = MovableDates.forYear(year);
  final advent1 = adventFirstSunday(year);
  final lastOtSaturday = advent1.subtractDays(1);
  final week34Sunday = weekStartingSunday(lastOtSaturday);
  final trinitySunday = md.trinitySunday;
  final numWeeksPart2 =
      (week34Sunday.difference(trinitySunday).inDays ~/ 7) + 1;
  final firstWeek = 34 - numWeeksPart2 + 1;
  final weekSunday = weekStartingSunday(date);
  final weeksSinceTrinity = weekSunday.difference(trinitySunday).inDays ~/ 7;
  return firstWeek + weeksSinceTrinity;
}
