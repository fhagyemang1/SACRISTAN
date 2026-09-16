import 'cycles.dart';
import 'general_roman_calendar.dart';
import 'local_calendar.dart';
import 'models.dart';
import 'season_engine.dart';

const _defaultSource = CalendarSource.computed;

/// True only for the generic per-day filler `_defaultCelebration` produces
/// ("5th Sunday in Ordinary Time", "Lenten Weekday, Week 3", etc.) — never
/// for a named movable celebration (Easter, Pentecost, Ash Wednesday...),
/// even though both share [CalendarSource.computed] as their [source] (see
/// the doc comment on that enum value in `models.dart`). Every filler key
/// `_defaultCelebration` builds starts with `'default'` (`'default.…'` or
/// the privileged-ferial `'default.privileged.…'`); no named celebration
/// anywhere in this package uses that prefix. Round 9's first real `dart
/// test` run (see ARCHITECTURE.md §4) found that the previous
/// `c.source == _defaultSource` check used for this purpose incorrectly
/// also matched named movable solemnities that land in the same
/// precedence tier as the filler (Easter Sunday, Pentecost) — the tie
/// then fell back on list order, which is not guaranteed stable by
/// `List.sort`, so the filler sometimes won and reported the wrong
/// color/goldPermitted. This key-based check is unambiguous.
bool _isGenericFiller(Celebration c) => c.key.startsWith('default');

/// Precedence tiers, loosely modeled on the Roman Missal's "Table of
/// Liturgical Days" (General Norms for the Liturgical Year, nn. 59-61),
/// simplified to what a parish sacristan app actually needs to get right.
/// Lower number = higher precedence = wins as [LiturgicalDay.primary].
///
/// Known simplification: the real Table of Liturgical Days has ~13 finely
/// graded tiers (several classes of memorial, and a "proper feast" tier
/// this app doesn't model). This 10-tier version — which, as of round 12,
/// does distinguish feasts of the Lord (tier 3) from feasts of the BVM/
/// Saints (tier 5), see [Celebration.isFeastOfTheLord] — is accurate for
/// the overwhelming majority of days a sacristan will encounter; edge
/// cases at the boundary between two close tiers should be confirmed
/// against the parish's printed Ordo.
int _tier(Celebration c,
    {required bool isSunday,
    required LiturgicalSeason season,
    required int weekOfSeason}) {
  // Days that sit in the Roman Missal's top precedence tier (General Norms
  // n. 59, "I.2") even though most of them are not solemnities by rank:
  // the four solemnities of the Lord — Nativity (Christmas), Epiphany,
  // Ascension, Pentecost — plus Easter Sunday itself (the first of the
  // "Sundays of Easter"), Ash Wednesday, and Monday-Wednesday of Holy
  // Week. Nothing else — not even a solemnity added via the local parish/
  // diocesan calendar — may be celebrated in their place. (Named
  // `topPrecedenceKeys`, not `topSolemnityKeys`, precisely because Ash
  // Wednesday and the Holy Week weekdays are ferial in *rank* but
  // top-tier in *precedence*.)
  //
  // Round 12 found `'ascension'` missing from this set: the doc comment
  // above already said "the four solemnities of the Lord" belonged here,
  // but the literal set only ever had three of the four (Christmas,
  // Epiphany, Pentecost) — Ascension fell through to the ordinary
  // solemnity tier (2) below, where it could tie with, and potentially
  // lose to, a same-date local-calendar solemnity. Nothing in this
  // package's fixed General Roman Calendar data collides with Ascension's
  // date range (Easter+39, i.e. never before Apr 30), so no *existing*
  // date is affected — but a parish's local supplementary calendar could
  // trivially create the collision (see the `calendar_engine_test.dart`
  // regression test for this fix, modeled on the existing Holy Monday
  // one).
  final topPrecedenceKeys = {
    'christmas', 'easterSunday', 'epiphany', 'ascension', 'pentecost',
    'ashWednesday', 'holyMonday', 'holyTuesday', 'holyWednesday',
  };
  if (c.rank == CelebrationRank.triduum) return 1;
  // Only the day's own Sunday-rank candidate belongs at this top tier —
  // not every candidate merely because the *date* is a Sunday of Advent,
  // Lent, or Easter. This is the exact same shape of bug round 9 found
  // and fixed for tier 5 below (there, `isSunday` alone was wrongly
  // treated as sufficient instead of checking `c.rank`) — this occurrence
  // at tier 1 went unnoticed until round 11's review because no existing
  // test exercised a fixed-date General Roman Calendar solemnity landing
  // on one of these Sundays. Without the `c.rank == sunday` guard, a
  // solemnity fixed to a date that happens to fall on, say, the Second
  // Sunday of Advent (verified: Dec 8 — Immaculate Conception — lands on
  // a Sunday of Advent in 2024 and 2030) would *also* get bumped to tier
  // 1 here, tie with the actual Sunday, and then win the tie-break below
  // (which prefers any non-filler entry over the generic filler) —
  // exactly backwards from the Roman Missal's own Table of Liturgical
  // Days, where Sundays of Advent/Lent/Easter (I.2) outrank General
  // Calendar solemnities (II.4). The real-world practice this app must
  // match is that the Church transfers such a solemnity to the next open
  // day rather than letting it displace the Sunday.
  if (isSunday &&
      c.rank == CelebrationRank.sunday &&
      (season == LiturgicalSeason.advent ||
          season == LiturgicalSeason.lent ||
          season == LiturgicalSeason.easter)) {
    return 1;
  }
  if (topPrecedenceKeys.contains(c.key)) return 1;
  // Round 13+ fix: the Octave of Easter (Easter Sunday through the
  // following Saturday) sits in the Roman Missal's same top-precedence
  // tier (General Norms n. 59, I.2) as Holy Week Monday-Wednesday —
  // nothing, not even a solemnity, may be celebrated in its place.
  // Easter Sunday itself is already covered above via `topPrecedenceKeys`
  // ('easterSunday'), but the weekdays of the Octave (Easter Monday
  // through Saturday) are generic filler entries produced by
  // `_defaultCelebration`'s `easterWeekday` branch below — their key
  // starts with 'default', not a fixed name, so they never match
  // `topPrecedenceKeys`' exact-key-match check and previously fell
  // through to their ferial rank (tier 8), letting a same-date General
  // Roman Calendar feast (e.g. St. Mark, April 25 — within the Octave in
  // 2025 and 2030) wrongly win. `weekOfSeason == 1` during the Easter
  // season is exactly the Octave week: see season_engine.dart's
  // `week = 1 + daysSince ~/ 7`, where `daysSince` counts from Easter
  // Sunday, so days 0-6 after Easter Sunday (i.e. through the following
  // Saturday) are week 1.
  //
  // Round 14 follow-up (found the hard way, by an actual failing `dart
  // test` run in CI rather than by review): the first version of this
  // check returned 1 for *any* candidate `c` present on an Octave day —
  // exactly the same shape of bug already fixed twice elsewhere in this
  // function (the Sunday-of-Advent/Lent/Easter check above, and the
  // Sunday-of-Ordinary-Time check below) — checking only the *date*
  // instead of which candidate the date-level privilege actually belongs
  // to. That meant St. Mark's own fixed feast *also* scored tier 1 on
  // April 25 in an Octave year, tying with the Easter-weekday filler; the
  // comparator's own tie-break rule (a named entry beats the generic
  // filler on a tie) then picked St. Mark as `.primary` anyway —
  // reproducing the exact bug this fix was meant to close. The
  // `_isGenericFiller(c)` guard restricts the privilege to the day's own
  // Easter-weekday candidate, the same pattern used for the Sunday checks
  // immediately above and below.
  if (season == LiturgicalSeason.easter &&
      weekOfSeason == 1 &&
      !isSunday &&
      _isGenericFiller(c)) {
    return 1;
  }
  if (c.rank == CelebrationRank.solemnity) return 2;
  // Feasts of the Lord in the General Calendar (Table of Liturgical Days,
  // II.5 — e.g. the Presentation, the Transfiguration, the Baptism of the
  // Lord) outrank Sundays of the Christmas season and of Ordinary Time
  // (II.6, tier 4 below). [Celebration.isFeastOfTheLord] carries this
  // distinction; see its doc comment in models.dart.
  if (c.rank == CelebrationRank.feast && c.isFeastOfTheLord) return 3;
  // The day's own Sunday-rank celebration (II.6: Sundays of the Christmas
  // season and of Ordinary Time) — not every candidate merely because
  // [isSunday] (the *date*) is true. A round-9-found bug had this
  // checking the date instead of the candidate, so a local
  // optional-memorial entry landing on a Sunday incorrectly tied with
  // (and, via the same-source bug that round fixed, could even beat) the
  // actual Sunday celebration. This must come *before* the plain-feast
  // tier below: II.6 (Sundays) outranks II.7 (feasts of saints).
  if (isSunday && c.rank == CelebrationRank.sunday) return 4;
  // Round 12: feasts of the Blessed Virgin Mary and of the Saints in the
  // General Calendar (II.7 — e.g. the Conversion of St. Paul, the Chair
  // of St. Peter, the Visitation) rank *below* the Sundays above. Every
  // `CelebrationRank.feast` used to land in the same tier as true feasts
  // of the Lord (both were tier 3, undifferentiated) — so a saint's feast
  // fixed to a date that happened to fall on a Sunday of Ordinary Time or
  // the Christmas season would wrongly displace it. E.g. 2026-01-25 is
  // both a Sunday in Ordinary Time and the fixed date of the Conversion
  // of St. Paul (a feast, not a Feast of the Lord) — the Sunday must win
  // as `.primary`, with St. Paul demoted to a secondary celebration, not
  // dropped or promoted ahead of it. See the regression test in
  // `calendar_engine_test.dart` for this exact date.
  if (c.rank == CelebrationRank.feast) return 5;
  if (_isGenericFiller(c) && c.key.startsWith('default.privileged')) {
    return 6;
  }
  if (c.rank == CelebrationRank.memorial) return 7;
  if (_isGenericFiller(c)) return 8; // plain ferial default
  if (c.rank == CelebrationRank.optionalMemorial) return 9;
  return 10;
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
    final ta = _tier(a,
        isSunday: isSunday,
        season: seasonRes.season,
        weekOfSeason: seasonRes.weekOfSeason);
    final tb = _tier(b,
        isSunday: isSunday,
        season: seasonRes.season,
        weekOfSeason: seasonRes.weekOfSeason);
    if (ta != tb) return ta.compareTo(tb);
    // Tie-break: a named (non-filler) entry is shown ahead of the
    // generic filler default when they'd otherwise be equal. Must use
    // the key-based check, not `source`: named movable celebrations
    // (Easter, Pentecost, ...) share `CalendarSource.computed` with the
    // filler itself, so a source-based check can't tell them apart —
    // see `_isGenericFiller`'s doc comment.
    final aIsDefault = _isGenericFiller(a);
    final bIsDefault = _isGenericFiller(b);
    if (aIsDefault != bIsDefault) return aIsDefault ? 1 : -1;
    // Round 12, explicit named guard: Holy Family Sunday must always win
    // when it ties with another named (non-filler) candidate — most
    // notably the fixed Dec 26 St. Stephen or Dec 28 Holy Innocents
    // entries, on the rare years Holy Family Sunday falls on one of those
    // dates (e.g. 2025-12-28). `isFeastOfTheLord` on the `holyFamily`
    // celebration (general_roman_calendar.dart) already keeps this from
    // being a real tie in practice — Holy Family sorts into tier 3 above,
    // Holy Innocents/St. Stephen into tier 5 — but that relies on neither
    // celebration's classification changing later. This clause makes the
    // invariant explicit and self-enforcing at the comparator itself,
    // independent of tier assignment, exactly as this package's own
    // history (rounds 6, 9, 11) shows an unresolved tie between two
    // same-tier named entries silently falls back on `List.sort`'s
    // explicitly-not-guaranteed-stable order.
    if (a.key == 'holyFamily' && b.key != 'holyFamily') return -1;
    if (b.key == 'holyFamily' && a.key != 'holyFamily') return 1;
    return 0;
  });

  // Drop the generic default filler when a same-or-better-ranked named
  // celebration already represents the day (it would just be redundant
  // noise in the UI). It is kept when it remains the best-ranked entry —
  // including the common case where it sits alongside a lower-precedence
  // optional memorial that a priest may choose instead.
  final primaryTier = _tier(candidates.first,
      isSunday: isSunday,
      season: seasonRes.season,
      weekOfSeason: seasonRes.weekOfSeason);
  final filtered = candidates.where((c) {
    if (!_isGenericFiller(c)) return true;
    final t = _tier(c,
        isSunday: isSunday,
        season: seasonRes.season,
        weekOfSeason: seasonRes.weekOfSeason);
    return t <= primaryTier || identical(c, candidates.first);
  }).toList();

  return LiturgicalDay(
    date: normalized,
    season: seasonRes.season,
    weekOfSeason: seasonRes.weekOfSeason,
    celebrations: filtered.isEmpty ? candidates : filtered,
    // Round 13+ fix: this used to read
    // `isSunday || filtered.first.rank == CelebrationRank.solemnity`,
    // which set a Sunday (A/B/C) lectionary cycle on *every*
    // solemnity-ranked primary celebration — including fixed-date
    // solemnities (Assumption, All Saints, Immaculate Conception,
    // Christmas, Epiphany, Mary Mother of God, the Annunciation, ...)
    // whose Mass readings in the Roman Lectionary are one fixed set that
    // never varies by year. Only Sundays themselves, plus the handful of
    // movable solemnities of the Lord that carry genuine proper
    // year-A/B/C readings (Ascension, Corpus Christi, the Most Sacred
    // Heart of Jesus), should get a cycle here. Trinity Sunday and Christ
    // the King already fall on a Sunday, so the plain `isSunday` check
    // already covers them without needing to be named explicitly.
    sundayCycle:
        isSunday || _sundayCycleSolemnityKeys.contains(filtered.first.key)
            ? sundayCycleFor(normalized)
            : null,
    weekdayCycle: !isSunday ? weekdayCycleFor(normalized) : null,
  );
}

/// See the doc comment on `sundayCycle:` in [resolveLiturgicalDay] above.
const _sundayCycleSolemnityKeys = {'ascension', 'corpusChristi', 'sacredHeart'};
