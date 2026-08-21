import 'computus.dart';
import 'cycles.dart';
import 'general_roman_calendar.dart';
import 'local_calendar.dart';
import 'models.dart';
import 'season_engine.dart';

const _defaultSource = CalendarSource.computed;

/// Precedence tiers, loosely modeled on the Roman Missal's "Table of
/// Liturgical Days" (General Norms for the Liturgical Year, nn. 59-61),
/// simplified to what a parish sacristan app actually needs to get right.
/// Lower number = higher precedence = wins as [LiturgicalDay.primary].
///
/// Known simplification: the real Table of Liturgical Days has ~13 finely
/// graded tiers (distinguishing e.g. feasts of the Lord from feasts of
/// saints, and several classes of memorial). This 8-tier version is
/// accurate for the overwhelming majority of days a sacristan will
/// encounter; edge cases at the boundary between two close tiers should be
/// confirmed against the parish's printed Ordo.
int _tier(Celebration c, {required bool isSunday, required LiturgicalSeason season}) {
  // Days that sit in the Roman Missal's top precedence tier (General Norms
  // n. 59, "I.2") even though most of them are not solemnities by rank:
  // the four solemnities of the Lord/Pentecost/Epiphany, Ash Wednesday,
  // and Monday-Wednesday of Holy Week. Nothing else — not even a
  // solemnity added via the local parish/diocesan calendar — may be
  // celebrated in their place. (Named `topPrecedenceKeys`, not
  // `topSolemnityKeys`, precisely because Ash Wednesday and the Holy Week
  // weekdays are ferial in *rank* but top-tier in *precedence*.)
  final topPrecedenceKeys = {
    'christmas', 'easterSunday', 'epiphany', 'pentecost', 'ashWednesday',
    'holyMonday', 'holyTuesday', 'holyWednesday',
  };
  if (c.rank == CelebrationRank.triduum) return 1;
  if (isSunday &&
      (season == LiturgicalSeason.advent ||
          season == LiturgicalSeason.lent ||
          season == LiturgicalSeason.easter)) {
    return 1;
  }
  if (topPrecedenceKeys.contains(c.key)) return 1;
  if (c.rank == CelebrationRank.solemnity) return 2;
  if (c.rank == CelebrationRank.feast) return 3;
  if (c.source == _defaultSource && c.key.startsWith('default.privileged')) {
    return 4;
  }
  if (isSunday) return 5;
  if (c.rank == CelebrationRank.memorial) return 6;
  if (c.source == _defaultSource) return 7; // plain ferial default
  if (c.rank == CelebrationRank.optionalMemorial) return 8;
  return 9;
}

bool _isPrivilegedFerial(DateTime date, LiturgicalSeason season) {
  if (season == LiturgicalSeason.lent) return true;
  if (season == LiturgicalSeason.advent && date.month == 12 && date.day >= 17) {
    return true;
  }
  if (season == LiturgicalSeason.christmas && date.month == 12 && date.day >= 25) {
    return true;
  }
  return false;
}

Celebration _defaultCelebration(
    DateTime date, LiturgicalSeason season, int weekOfSeason, bool isSunday) {
  final privileged = _isPrivilegedFerial(date, season);
  final keyPrefix = privileged ? 'default.privileged' : 'default';

  switch (season) {
    case LiturgicalSeason.advent:
      if (isSunday) {
        final isGaudete = weekOfSeason == 3;
        return Celebration(
          key: '$keyPrefix.adventSunday$weekOfSeason',
          name: isGaudete
              ? 'Third Sunday of Advent (Gaudete Sunday)'
              : '${_ordinal(weekOfSeason)} Sunday of Advent',
          rank: CelebrationRank.sunday,
          color: isGaudete ? LiturgicalColor.rose : LiturgicalColor.violet,
          source: _defaultSource,
        );
      }
      return Celebration(
        key: '$keyPrefix.adventWeekday',
        name: date.day >= 17
            ? 'Advent Weekday (Dec 17–24)'
            : 'Advent Weekday, Week $weekOfSeason',
        rank: CelebrationRank.ferial,
        color: LiturgicalColor.violet,
        source: _defaultSource,
      );
    case LiturgicalSeason.christmas:
      if (isSunday) {
        return Celebration(
          key: '$keyPrefix.christmasSunday',
          name: 'Sunday within the Christmas Season',
          rank: CelebrationRank.sunday,
          color: LiturgicalColor.white,
          source: _defaultSource,
        );
      }
      return Celebration(
        key: '$keyPrefix.christmasWeekday',
        name: 'Christmas Weekday',
        rank: CelebrationRank.ferial,
        color: LiturgicalColor.white,
        source: _defaultSource,
      );
    case LiturgicalSeason.lent:
      if (isSunday) {
        final isLaetare = weekOfSeason == 4;
        return Celebration(
          key: '$keyPrefix.lentSunday$weekOfSeason',
          name: isLaetare
              ? 'Fourth Sunday of Lent (Laetare Sunday)'
              : '${_ordinal(weekOfSeason)} Sunday of Lent',
          rank: CelebrationRank.sunday,
          color: isLaetare ? LiturgicalColor.rose : LiturgicalColor.violet,
          source: _defaultSource,
        );
      }
      return Celebration(
        key: '$keyPrefix.lentWeekday',
        name: weekOfSeason == 0
            ? 'Weekday after Ash Wednesday'
            : 'Lenten Weekday, Week $weekOfSeason',
        rank: CelebrationRank.ferial,
        color: LiturgicalColor.violet,
        source: _defaultSource,
      );
    case LiturgicalSeason.triduum:
      // Always superseded by the specific movable-date entry for the day;
      // this branch is only a defensive fallback.
      return const Celebration(
        key: 'default.triduum',
        name: 'The Sacred Triduum',
        rank: CelebrationRank.triduum,
        color: LiturgicalColor.red,
        source: _defaultSource,
      );
    case LiturgicalSeason.easter:
      if (isSunday) {
        return Celebration(
          key: '$keyPrefix.easterSunday$weekOfSeason',
          name: '${_ordinal(weekOfSeason)} Sunday of Easter',
          rank: CelebrationRank.sunday,
          color: LiturgicalColor.white,
          source: _defaultSource,
        );
      }
      return Celebration(
        key: '$keyPrefix.easterWeekday',
        name: 'Easter Weekday, Week $weekOfSeason',
        rank: CelebrationRank.ferial,
        color: LiturgicalColor.white,
        source: _defaultSource,
      );
    case LiturgicalSeason.ordinaryTime:
      if (isSunday) {
        return Celebration(
          key: '$keyPrefix.otSunday$weekOfSeason',
          name: '${_ordinal(weekOfSeason)} Sunday in Ordinary Time',
          rank: CelebrationRank.sunday,
          color: LiturgicalColor.green,
          source: _defaultSource,
        );
      }
      return Celebration(
        key: '$keyPrefix.otWeekday',
        name: '${_ordinal(weekOfSeason)} Week in Ordinary Time — Weekday',
        rank: CelebrationRank.ferial,
        color: LiturgicalColor.green,
        source: _defaultSource,
      );
  }
}

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

/// Resolves the full liturgical description of [date].
///
/// [localSupplement] is an optional, entirely-offline parish/diocesan
/// calendar layered on top of the bundled General Roman Calendar. Passing
/// a different [localSupplement] never requires network access — it's
/// expected to come from the local database (see the app's
/// `local_calendar_entries` table).
LiturgicalDay resolveLiturgicalDay(
  DateTime date, {
  List<LocalCalendarEntry> localSupplement = const [],
}) {
  final normalized = DateTime.utc(date.year, date.month, date.day);
  final seasonRes = resolveSeason(normalized);
  final isSunday = normalized.weekday == DateTime.sunday;

  final candidates = <Celebration>[
    _defaultCelebration(normalized, seasonRes.season, seasonRes.weekOfSeason, isSunday),
  ];

  for (final fc in generalRomanCalendarFixed) {
    if (fc.month == normalized.month && fc.day == normalized.day) {
      candidates.add(fc.celebration);
    }
  }
  for (final fc in movableCelebrationsForYear(normalized.year)) {
    if (fc.month == normalized.month && fc.day == normalized.day) {
      candidates.add(fc.celebration);
    }
  }
  for (final entry in localSupplement) {
    if (entry.month == normalized.month && entry.day == normalized.day) {
      candidates.add(entry.toCelebration());
    }
  }

  candidates.sort((a, b) {
    final ta = _tier(a, isSunday: isSunday, season: seasonRes.season);
    final tb = _tier(b, isSunday: isSunday, season: seasonRes.season);
    if (ta != tb) return ta.compareTo(tb);
    // Tie-break: a named (non-default) entry is shown ahead of the
    // generic filler default when they'd otherwise be equal.
    final aIsDefault = a.source == _defaultSource;
    final bIsDefault = b.source == _defaultSource;
    if (aIsDefault != bIsDefault) return aIsDefault ? 1 : -1;
    return 0;
  });

  // Drop the generic default filler when a same-or-better-ranked named
  // celebration already represents the day (it would just be redundant
  // noise in the UI). It is kept when it remains the best-ranked entry —
  // including the common case where it sits alongside a lower-precedence
  // optional memorial that a priest may choose instead.
  final primaryTier =
      _tier(candidates.first, isSunday: isSunday, season: seasonRes.season);
  final filtered = candidates.where((c) {
    if (c.source != _defaultSource) return true;
    final t = _tier(c, isSunday: isSunday, season: seasonRes.season);
    return t <= primaryTier || identical(c, candidates.first);
  }).toList();

  return LiturgicalDay(
    date: normalized,
    season: seasonRes.season,
    weekOfSeason: seasonRes.weekOfSeason,
    celebrations: filtered.isEmpty ? candidates : filtered,
    sundayCycle: isSunday || filtered.first.rank == CelebrationRank.solemnity
        ? sundayCycleFor(normalized)
        : null,
    weekdayCycle: !isSunday ? weekdayCycleFor(normalized) : null,
  );
}
