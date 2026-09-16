// Run with: dart test
//
// See tools/verification/verify_calendar_engine.py in the repo root for an
// independent, already-executed cross-check of the Easter computus and its
// offsets against a live-fetched ground-truth table (see that script's
// docstring for why it exists alongside this file).
import 'package:liturgical_calendar/liturgical_calendar.dart';
import 'package:test/test.dart';

/// Ground truth Easter Sundays (Gregorian/Western), fetched live from
/// https://www.projectpluto.com/easter.htm during development
/// (2026-08-21). Spans 2000-2050 (51 years) plus 1943, the most recent
/// occurrence of the latest possible Easter date (April 25) — well beyond
/// the "at least a 20-year span" requirement.
const Map<int, (int, int)> knownEasterDates = {
  1943: (4, 25),
  2000: (4, 23), 2001: (4, 15), 2002: (3, 31), 2003: (4, 20), 2004: (4, 11),
  2005: (3, 27), 2006: (4, 16), 2007: (4, 8), 2008: (3, 23), 2009: (4, 12),
  2010: (4, 4), 2011: (4, 24), 2012: (4, 8), 2013: (3, 31), 2014: (4, 20),
  2015: (4, 5), 2016: (3, 27), 2017: (4, 16), 2018: (4, 1), 2019: (4, 21),
  2020: (4, 12), 2021: (4, 4), 2022: (4, 17), 2023: (4, 9), 2024: (3, 31),
  2025: (4, 20), 2026: (4, 5), 2027: (3, 28), 2028: (4, 16), 2029: (4, 1),
  2030: (4, 21), 2031: (4, 13), 2032: (3, 28), 2033: (4, 17), 2034: (4, 9),
  2035: (3, 25), 2036: (4, 13), 2037: (4, 5), 2038: (4, 25), 2039: (4, 10),
  2040: (4, 1), 2041: (4, 21), 2042: (4, 6), 2043: (3, 29), 2044: (4, 17),
  2045: (4, 9), 2046: (3, 25), 2047: (4, 14), 2048: (4, 5), 2049: (4, 18),
  2050: (4, 10),
};

void main() {
  group('computeEasterSunday', () {
    knownEasterDates.forEach((year, expected) {
      test('$year -> ${expected.$1}/${expected.$2}', () {
        final easter = computeEasterSunday(year);
        expect(easter.month, expected.$1);
        expect(easter.day, expected.$2);
        expect(easter.weekday, DateTime.sunday);
      });
    });

    test('always falls between March 22 and April 25 (2000-2059)', () {
      for (var year = 2000; year <= 2059; year++) {
        final easter = computeEasterSunday(year);
        final lower = DateTime.utc(year, 3, 22);
        final upper = DateTime.utc(year, 4, 25);
        expect(!easter.isBefore(lower) && !easter.isAfter(upper), isTrue,
            reason: '$year: Easter $easter out of canonical range');
      }
    });
  });

  group('MovableDates offsets (2026)', () {
    final md = MovableDates.forYear(2026);
    test('Ash Wednesday is a Wednesday, 46 days before Easter', () {
      expect(md.ashWednesday.weekday, DateTime.wednesday);
      expect(md.easterSunday.difference(md.ashWednesday).inDays, 46);
    });
    test('Palm Sunday is a Sunday, 7 days before Easter', () {
      expect(md.palmSunday.weekday, DateTime.sunday);
      expect(md.easterSunday.difference(md.palmSunday).inDays, 7);
    });
    test('Good Friday is a Friday, 2 days before Easter', () {
      expect(md.goodFriday.weekday, DateTime.friday);
    });
    test('Pentecost is a Sunday, 49 days after Easter', () {
      expect(md.pentecost.weekday, DateTime.sunday);
      expect(md.pentecost.difference(md.easterSunday).inDays, 49);
    });
    test('Trinity Sunday is the Sunday after Pentecost', () {
      expect(md.trinitySunday.difference(md.pentecost).inDays, 7);
    });
  });

  group('resolveLiturgicalDay — spot checks', () {
    test('Christmas Day is always white/gold solemnity', () {
      for (final year in [2024, 2025, 2026, 2030]) {
        final day = resolveLiturgicalDay(DateTime(year, 12, 25));
        expect(day.color, LiturgicalColor.white);
        expect(day.rank, CelebrationRank.solemnity);
        expect(day.season, LiturgicalSeason.christmas);
      }
    });

    test('Ash Wednesday is violet, ferial rank, in Lent', () {
      final md = MovableDates.forYear(2026);
      final day = resolveLiturgicalDay(md.ashWednesday);
      expect(day.color, LiturgicalColor.violet);
      expect(day.season, LiturgicalSeason.lent);
    });

    test('Monday-Wednesday of Holy Week are named and violet, not generic '
        'Lenten weekday filler', () {
      final md = MovableDates.forYear(2026);
      final monday = resolveLiturgicalDay(md.mondayHolyWeek);
      final tuesday = resolveLiturgicalDay(md.tuesdayHolyWeek);
      final wednesday = resolveLiturgicalDay(md.wednesdayHolyWeek);
      expect(monday.primary.name, 'Monday of Holy Week');
      expect(tuesday.primary.name, 'Tuesday of Holy Week');
      expect(wednesday.primary.name, 'Wednesday of Holy Week');
      for (final day in [monday, tuesday, wednesday]) {
        expect(day.color, LiturgicalColor.violet);
        expect(day.season, LiturgicalSeason.lent);
      }
    });

    test('Monday of Holy Week outranks even a local-calendar solemnity '
        '(regression check for the round-6 precedence fix)', () {
      final md = MovableDates.forYear(2026);
      final entry = LocalCalendarEntry(
        id: 'wouldBeSolemnity',
        month: md.mondayHolyWeek.month,
        day: md.mondayHolyWeek.day,
        name: 'A Parish Patronal Solemnity That Happens to Land Here',
        rank: CelebrationRank.solemnity,
        color: LiturgicalColor.white,
      );
      final day = resolveLiturgicalDay(md.mondayHolyWeek,
          localSupplement: [entry]);
      expect(day.primary.name, 'Monday of Holy Week');
      // Still offered as an available option, just not primary — matching
      // how other top-precedence days (e.g. Ash Wednesday) behave.
      expect(
          day.celebrations.any((c) => c.name.contains('Patronal Solemnity')),
          isTrue);
    });

    test('Good Friday is red and in the Triduum', () {
      final md = MovableDates.forYear(2026);
      final day = resolveLiturgicalDay(md.goodFriday);
      expect(day.color, LiturgicalColor.red);
      expect(day.season, LiturgicalSeason.triduum);
      expect(day.rank, CelebrationRank.triduum);
    });

    test('Easter Sunday is white/gold and starts the Easter season', () {
      final md = MovableDates.forYear(2026);
      final day = resolveLiturgicalDay(md.easterSunday);
      expect(day.color, LiturgicalColor.white);
      expect(day.goldPermitted, isTrue);
      expect(day.season, LiturgicalSeason.easter);
      expect(day.weekOfSeason, 1);
    });

    test('Pentecost is red', () {
      final md = MovableDates.forYear(2026);
      final day = resolveLiturgicalDay(md.pentecost);
      expect(day.color, LiturgicalColor.red);
    });

    test('Gaudete Sunday (3rd Sunday of Advent) is rose', () {
      // Advent 2025's third Sunday.
      final advent1 = adventFirstSunday(2025);
      final gaudete = advent1.addDays(14);
      final day = resolveLiturgicalDay(gaudete);
      expect(day.season, LiturgicalSeason.advent);
      expect(day.weekOfSeason, 3);
      expect(day.color, LiturgicalColor.rose);
    });

    test('Laetare Sunday (4th Sunday of Lent) is rose', () {
      final md = MovableDates.forYear(2026);
      final lent1Sunday = md.ashWednesday.addDays(4);
      final laetare = lent1Sunday.addDays(21);
      final day = resolveLiturgicalDay(laetare);
      expect(day.season, LiturgicalSeason.lent);
      expect(day.weekOfSeason, 4);
      expect(day.color, LiturgicalColor.rose);
    });

    test('An ordinary weekday in July is green, ferial', () {
      final day = resolveLiturgicalDay(DateTime(2026, 7, 14)); // a Tuesday
      expect(day.season, LiturgicalSeason.ordinaryTime);
      expect(day.color, LiturgicalColor.green);
      expect(day.rank, CelebrationRank.ferial);
    });

    test('All Saints (Nov 1) is always a white solemnity regardless of weekday', () {
      for (final year in [2025, 2026, 2027, 2028]) {
        final day = resolveLiturgicalDay(DateTime(year, 11, 1));
        expect(day.rank, CelebrationRank.solemnity);
        expect(day.color, LiturgicalColor.white);
      }
    });

    test(
        'a Sunday of Advent outranks a General Roman Calendar solemnity '
        'fixed to the same date (round 11 regression)', () {
      // Confirmed via a plain day-of-week check (not assumed): Dec 8 (the
      // Immaculate Conception, a fixed solemnity) falls on a Sunday in
      // both 2024 and 2030 — and in both years it lands on the Second
      // Sunday of Advent specifically, not merely "some Sunday." Real
      // Church practice transfers the solemnity in that case, since the
      // Roman Missal's own Table of Liturgical Days ranks Sundays of
      // Advent/Lent/Easter (tier I.2) above General Calendar solemnities
      // (tier II.4). The engine's `_tier()` function used to grant tier-1
      // status to *every* candidate present on a Sunday of Advent/Lent/
      // Easter, not just the Sunday-rank candidate itself — so a fixed
      // solemnity landing on one of these Sundays would tie with the
      // Sunday at tier 1 and then win the tie-break (which prefers any
      // non-filler candidate over the generic filler), incorrectly
      // reporting the solemnity as `.primary` instead of the Sunday. No
      // prior test in this file exercised a fixed-date solemnity
      // coinciding with one of these Sundays, so this went undetected
      // across every round and CI run to date.
      for (final year in [2024, 2030]) {
        final dec8 = DateTime(year, 12, 8);
        expect(dec8.weekday, DateTime.sunday,
            reason: 'test setup assumption: Dec 8, $year must be a Sunday');
        final day = resolveLiturgicalDay(dec8);
        expect(day.season, LiturgicalSeason.advent);
        expect(day.weekOfSeason, 2);
        expect(day.primary.rank, CelebrationRank.sunday,
            reason: 'the Second Sunday of Advent must win as .primary — '
                'a solemnity fixed to this date must not displace it');
        expect(day.primary.key, isNot(contains('immaculateConception')));
        // The Immaculate Conception should still appear as a secondary
        // celebration (a real parish needs to know it's there, even
        // though the Sunday takes precedence) rather than disappearing
        // entirely.
        expect(
          day.celebrations.any((c) => c.key == 'immaculateConception'),
          isTrue,
          reason: 'the solemnity should still be listed among the day\'s '
              'celebrations, just not as .primary',
        );
      }
    });

    test(
        'a Sunday in Ordinary Time outranks a fixed Feast of a Saint on the '
        'General Roman Calendar (round 12 regression)', () {
      // Confirmed via a plain day-of-week check: Jan 25, 2026 is a Sunday.
      // The Baptism of the Lord 2026 falls on Jan 11, so Ordinary Time
      // begins Jan 12 and Jan 25 lands squarely in it (the 3rd Sunday) —
      // not the Christmas season. Jan 25 is also the fixed date of the
      // Conversion of St. Paul, a Feast, but of a saint, not of the Lord.
      // Per the Missal's Table of Liturgical Days, Sundays of Ordinary
      // Time (II.6) outrank Feasts of the Saints in the General Calendar
      // (II.7) — the Sunday must win as `.primary`. Before this fix,
      // every `CelebrationRank.feast` celebration — whether a Feast of
      // the Lord or an ordinary saint's feast — shared one
      // undifferentiated precedence tier that outranked the Sunday
      // filler outright, so St. Paul wrongly won `.primary` and the
      // Sunday was filtered out of `celebrations` entirely (not even
      // shown as secondary).
      final jan25 = DateTime(2026, 1, 25);
      expect(jan25.weekday, DateTime.sunday,
          reason: 'test setup assumption: Jan 25, 2026 must be a Sunday');
      final day = resolveLiturgicalDay(jan25);
      expect(day.season, LiturgicalSeason.ordinaryTime);
      expect(day.weekOfSeason, 3);
      expect(day.primary.rank, CelebrationRank.sunday,
          reason: 'the 3rd Sunday in Ordinary Time must win as .primary — '
              'a saint\'s feast fixed to this date must not displace it');
      expect(day.color, LiturgicalColor.green);
      expect(day.primary.key, isNot(contains('conversionOfStPaul')));
      expect(
        day.celebrations.any((c) => c.key == 'conversionOfStPaul'),
        isTrue,
        reason: 'the Conversion of St. Paul should still be listed as a '
            'secondary celebration, just not as .primary and not dropped',
      );
    });

    test(
        'Holy Family Sunday outranks a coinciding fixed Dec 26/28 feast '
        '(round 12 regression)', () {
      // Confirmed via a plain day-of-week check: Dec 28, 2025 is a Sunday.
      // `holyFamily(2025)` independently resolves to that same date (the
      // first Sunday found scanning Dec 26-31) — so Holy Family Sunday
      // coincides with the fixed Holy Innocents feast, also Dec 28. Holy
      // Family must always win: it is the proper title of that week's
      // Sunday within the Octave of Christmas, not an ordinary competing
      // feast of a saint. Before this fix, both were the same
      // undifferentiated `feast` tier, and the comparator's tie-break
      // couldn't distinguish two non-filler entries — an unresolved tie
      // silently decided by `List.sort`'s explicitly-not-guaranteed-stable
      // order, exactly the shape of bug rounds 6, 9, and 11 already found
      // elsewhere in this function.
      final dec28 = DateTime(2025, 12, 28);
      expect(dec28.weekday, DateTime.sunday,
          reason: 'test setup assumption: Dec 28, 2025 must be a Sunday');
      final hf = holyFamily(2025);
      expect(hf.month, 12);
      expect(hf.day, 28,
          reason: 'test setup assumption: Holy Family 2025 must fall on '
              'Dec 28, coinciding with the fixed Holy Innocents entry');
      final day = resolveLiturgicalDay(dec28);
      expect(day.primary.key, 'holyFamily');
      expect(day.color, LiturgicalColor.white);
      expect(
        day.celebrations.any((c) => c.key == 'holyInnocents'),
        isTrue,
        reason: 'Holy Innocents should still be listed as a secondary '
            'celebration, just not as .primary',
      );
    });

    test(
        'Ascension Thursday outranks even a local-calendar solemnity '
        '(round 12 regression)', () {
      // Ascension 2026 = Easter (Apr 5) + 39 days = May 14, a Thursday.
      // `topPrecedenceKeys` in calendar_engine.dart previously omitted
      // 'ascension' despite the doc comment above it already saying "the
      // four solemnities of the Lord" belong in that set — Ascension
      // only ever scored the ordinary solemnity tier, so it could tie
      // with (and lose to, depending on sort order) a same-date
      // local-calendar solemnity, unlike every other day in that set
      // (mirrors the existing "Monday of Holy Week outranks even a
      // local-calendar solemnity" regression test above).
      final md = MovableDates.forYear(2026);
      expect(md.ascensionThursday, DateTime.utc(2026, 5, 14),
          reason: 'test setup assumption: Ascension 2026 must be May 14');
      final entry = LocalCalendarEntry(
        id: 'wouldBeSolemnity',
        month: md.ascensionThursday.month,
        day: md.ascensionThursday.day,
        name: 'A Parish Patronal Solemnity That Happens to Land Here',
        rank: CelebrationRank.solemnity,
        color: LiturgicalColor.white,
      );
      final day = resolveLiturgicalDay(md.ascensionThursday,
          localSupplement: [entry]);
      expect(day.primary.key, 'ascension');
      // Still offered as an available option, just not primary.
      expect(
          day.celebrations.any((c) => c.name.contains('Patronal Solemnity')),
          isTrue);
    });

    test(
        'a General Roman Calendar feast fixed to a date within the Octave '
        'of Easter does not displace the Easter weekday (round 13+ '
        'regression)', () {
      // St. Mark the Evangelist is fixed to April 25 every year. Easter
      // Sunday falls on April 21 in 2030 (see knownEasterDates above), so
      // the Octave of Easter runs April 21-27 — April 25 (a Thursday)
      // lands inside it. The Roman Missal's Table of Liturgical Days
      // (General Norms n. 59, I.2) places every day within the Octave of
      // Easter at top precedence: nothing, not even a solemnity, may be
      // celebrated in its place — so St. Mark's feast must not become
      // `.primary` here, even though a Feast of a Saint (tier II.7)
      // ordinarily outranks a plain ferial weekday filler. Before this
      // fix, Easter-Octave weekdays were generic filler entries with no
      // special precedence protection at all (unlike the explicitly
      // top-tier Holy Week Monday-Wednesday), so they fell through to
      // the plain ferial-filler tier and lost to St. Mark's feast tier.
      final day = resolveLiturgicalDay(DateTime(2030, 4, 25));
      expect(day.season, LiturgicalSeason.easter);
      expect(day.weekOfSeason, 1,
          reason: 'test setup assumption: April 25, 2030 must fall within '
              'the Octave (week 1) of the Easter season');
      expect(day.primary.name, 'Easter Weekday, Week 1');
      expect(day.primary.key, isNot(contains('stMark')));
      // Still offered as a secondary option, matching how other days in
      // this app handle a lower-precedence candidate.
      expect(
        day.celebrations.any((c) => c.key == 'stMarkEvangelist'),
        isTrue,
        reason: 'St. Mark should still be listed as a secondary '
            'celebration, just not as .primary',
      );
    });

    test('Christ the King is the Sunday immediately before Advent begins', () {
      final ctk = christTheKing(2026);
      final advent1 = adventFirstSunday(2026);
      expect(advent1.difference(ctk).inDays, 7);
      final day = resolveLiturgicalDay(ctk);
      expect(day.rank, CelebrationRank.solemnity);
    });

    test('a far-future year (2075) resolves without error, offline', () {
      final day = resolveLiturgicalDay(DateTime(2075, 12, 25));
      expect(day.color, LiturgicalColor.white);
      final easter2075 = computeEasterSunday(2075);
      expect(easter2075.weekday, DateTime.sunday);
    });
  });

  group('Ordinary Time week numbering invariants (2000-2059)', () {
    for (var year = 2000; year <= 2059; year++) {
      test('$year: last OT week before Advent is always Week 34', () {
        final advent1 = adventFirstSunday(year);
        final lastOtSaturday = advent1.subtractDays(1);
        final day = resolveLiturgicalDay(lastOtSaturday);
        expect(day.season, LiturgicalSeason.ordinaryTime);
        expect(day.weekOfSeason, 34);
      });
    }
  });

  group('Lectionary cycles', () {
    test('Sunday cycle: liturgical year starting Advent 2025 is Cycle A', () {
      final advent1_2025 = adventFirstSunday(2025);
      expect(sundayCycleFor(advent1_2025), SundayCycle.a);
      expect(sundayCycleFor(DateTime(2026, 6, 1)), SundayCycle.a);
    });

    test('Sunday cycle: liturgical year starting Advent 2026 is Cycle B', () {
      final advent1_2026 = adventFirstSunday(2026);
      expect(sundayCycleFor(advent1_2026), SundayCycle.b);
    });

    test('Weekday cycle: odd calendar years are Cycle I, even are Cycle II', () {
      expect(weekdayCycleFor(DateTime(2025, 6, 1)), WeekdayCycle.i);
      expect(weekdayCycleFor(DateTime(2026, 6, 1)), WeekdayCycle.ii);
    });

    // Round 13+ fix: `resolveLiturgicalDay` used to set `sundayCycle` on
    // every solemnity-ranked primary celebration unconditionally — but
    // most solemnities are fixed-date and use one unchanging set of Mass
    // readings every year, so tagging them with an A/B/C cycle was simply
    // wrong data, not just an unused field. Only Sundays themselves, plus
    // the handful of movable solemnities of the Lord that carry genuine
    // proper year-A/B/C readings in the Roman Lectionary (Ascension,
    // Corpus Christi, the Most Sacred Heart of Jesus), should carry one.
    test('a fixed-date solemnity (Assumption) does not carry a Sunday cycle',
        () {
      final day = resolveLiturgicalDay(DateTime(2026, 8, 15));
      expect(day.rank, CelebrationRank.solemnity);
      expect(day.sundayCycle, isNull,
          reason: 'the Assumption\'s Mass readings never vary by the '
              'three-year Sunday cycle');
    });

    test('Christmas Day does not carry a Sunday cycle', () {
      final day = resolveLiturgicalDay(DateTime(2026, 12, 25));
      expect(day.rank, CelebrationRank.solemnity);
      expect(day.sundayCycle, isNull);
    });

    test('Ascension Thursday (not itself a Sunday) still carries the '
        'Sunday cycle', () {
      final md = MovableDates.forYear(2026);
      expect(md.ascensionThursday.weekday, DateTime.thursday,
          reason: 'test setup assumption: this app shows Ascension on its '
              'traditional Thursday date, not the transferred Sunday');
      final day = resolveLiturgicalDay(md.ascensionThursday);
      expect(day.primary.key, 'ascension');
      expect(day.sundayCycle, sundayCycleFor(md.ascensionThursday),
          reason: 'Ascension\'s proper readings vary by the three-year '
              'A/B/C cycle even though it is celebrated on a Thursday');
    });

    test('the Most Sacred Heart of Jesus (a Friday) still carries the '
        'Sunday cycle', () {
      final md = MovableDates.forYear(2026);
      expect(md.sacredHeartFriday.weekday, DateTime.friday,
          reason: 'test setup assumption: Sacred Heart always falls on a '
              'Friday (Easter + 68 days)');
      final day = resolveLiturgicalDay(md.sacredHeartFriday);
      expect(day.primary.key, 'sacredHeart');
      expect(day.sundayCycle, sundayCycleFor(md.sacredHeartFriday));
    });
  });

  group('Local supplementary calendar (offline)', () {
    test('a parish patronal solemnity overrides an Ordinary Time weekday', () {
      const entry = LocalCalendarEntry(
        id: 'patronal',
        month: 7,
        day: 16,
        name: 'Our Lady of Mount Carmel (Parish Patronal Feast)',
        rank: CelebrationRank.solemnity,
        color: LiturgicalColor.white,
      );
      final day = resolveLiturgicalDay(
        DateTime(2026, 7, 16),
        localSupplement: const [entry],
      );
      expect(day.primary.name, contains('Mount Carmel'));
      expect(day.color, LiturgicalColor.white);
    });

    test('an optional-memorial-level local entry does not override a Sunday', () {
      const entry = LocalCalendarEntry(
        id: 'diocesanOptional',
        month: 7,
        day: 19, // a Sunday in Ordinary Time 2026
        name: 'A Diocesan Optional Memorial',
        rank: CelebrationRank.optionalMemorial,
        color: LiturgicalColor.white,
      );
      final day = resolveLiturgicalDay(
        DateTime(2026, 7, 19),
        localSupplement: const [entry],
      );
      expect(day.rank, CelebrationRank.sunday);
      expect(day.color, LiturgicalColor.green);
      // still offered as an available option for that day:
      expect(day.celebrations.any((c) => c.name.contains('Diocesan Optional')),
          isTrue);
    });
  });
}
