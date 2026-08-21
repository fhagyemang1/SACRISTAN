import 'models.dart';
import 'season_engine.dart' show adventFirstSunday;

/// Resolves the three-year Sunday lectionary cycle (A/B/C) for [date].
///
/// The liturgical year that begins on a given First Sunday of Advent in
/// calendar year N uses the cycle determined by `(N + 1) % 3`:
/// remainder 1 -> A, remainder 2 -> B, remainder 0 -> C. For example the
/// liturgical year beginning Advent 2025 (N=2025) uses (2026 % 3 == 1) ->
/// Cycle A, matching the published USCCB/Vatican lectionary schedule.
SundayCycle sundayCycleFor(DateTime date) {
  final advent = adventFirstSunday(date.year);
  final n = date.isBefore(advent) ? date.year - 1 : date.year;
  final m = (n + 1) % 3;
  switch (m) {
    case 1:
      return SundayCycle.a;
    case 2:
      return SundayCycle.b;
    default:
      return SundayCycle.c;
  }
}

/// Resolves the two-year weekday lectionary cycle (I/II) for [date].
///
/// Unlike the Sunday cycle, the weekday cycle switches on January 1st, not
/// at Advent: odd calendar years use Cycle I, even calendar years use
/// Cycle II.
WeekdayCycle weekdayCycleFor(DateTime date) =>
    date.year.isOdd ? WeekdayCycle.i : WeekdayCycle.ii;
