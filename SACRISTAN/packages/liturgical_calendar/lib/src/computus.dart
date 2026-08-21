/// Computation of the date of Easter Sunday (the "computus") and every
/// other movable date that is defined relative to it.
///
/// Uses the Anonymous Gregorian algorithm (also called the
/// Meeus/Jones/Butcher algorithm), which is valid for any Gregorian
/// calendar year and is the standard reference algorithm used by
/// astronomical almanacs and liturgical software alike. It requires no
/// external data and is exact — no approximation, no lookup table.
library;

/// Returns the Gregorian-calendar date of Easter Sunday for [year].
///
/// Valid for any year in the proleptic Gregorian calendar; the Roman
/// Catholic Church has used the Gregorian calendar for Easter reckoning
/// since the 1582 reform, so this is correct for all years the app will
/// realistically be asked about (the UI does not artificially limit how
/// far into the future a date can be queried, per the offline-first,
/// "works for years in the future" requirement).
DateTime computeEasterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31; // 3 = March, 4 = April
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime.utc(year, month, day);
}

extension DateShift on DateTime {
  DateTime addDays(int days) => DateTime.utc(year, month, day + days);
  DateTime subtractDays(int days) => addDays(-days);
}

/// Bundles all of the fixed-relative-to-Easter dates the engine needs,
/// computed once per year and reused.
class MovableDates {
  final int year;
  final DateTime easterSunday;

  // Lenten season
  final DateTime ashWednesday;
  final DateTime palmSunday;
  final DateTime mondayHolyWeek;
  final DateTime tuesdayHolyWeek;
  final DateTime wednesdayHolyWeek; // "Spy Wednesday"
  final DateTime holyThursday;
  final DateTime goodFriday;
  final DateTime holySaturday;

  // Easter season
  final DateTime divineMercySunday;
  final DateTime ascensionThursday;
  final DateTime ascensionSunday; // Thursday date transferred to the Sunday
  final DateTime pentecost;

  // Ordinary Time anchors that depend on Easter (Trinity/Corpus Christi/
  // Sacred Heart all count forward from Pentecost)
  final DateTime trinitySunday;
  final DateTime corpusChristiThursday;
  final DateTime corpusChristiSunday;
  final DateTime sacredHeartFriday;

  MovableDates._(this.year, this.easterSunday)
      : ashWednesday = easterSunday.subtractDays(46),
        palmSunday = easterSunday.subtractDays(7),
        mondayHolyWeek = easterSunday.subtractDays(6),
        tuesdayHolyWeek = easterSunday.subtractDays(5),
        wednesdayHolyWeek = easterSunday.subtractDays(4),
        holyThursday = easterSunday.subtractDays(3),
        goodFriday = easterSunday.subtractDays(2),
        holySaturday = easterSunday.subtractDays(1),
        divineMercySunday = easterSunday.addDays(7),
        ascensionThursday = easterSunday.addDays(39),
        ascensionSunday = easterSunday.addDays(42),
        pentecost = easterSunday.addDays(49),
        trinitySunday = easterSunday.addDays(56),
        corpusChristiThursday = easterSunday.addDays(60),
        corpusChristiSunday = easterSunday.addDays(63),
        sacredHeartFriday = easterSunday.addDays(68);

  factory MovableDates.forYear(int year) =>
      MovableDates._(year, computeEasterSunday(year));
}
