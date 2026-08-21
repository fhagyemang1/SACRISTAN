import 'general_roman_calendar.dart';
import 'models.dart';

/// A single entry in a parish or diocesan supplementary calendar — entered
/// or imported entirely offline (via a local file or the in-app editor),
/// never fetched from a network.
///
/// Only fixed month/day entries are supported for the local supplement
/// (a patronal feast, a diocesan saint, a parish anniversary). A movable
/// (Easter-relative) local entry — e.g. a diocese that transfers the
/// Ascension to Sunday — is expressed by having the app pre-resolve the
/// date for the relevant year(s) when the entry is saved, and re-resolving
/// it whenever the year changes; the data model's `month`/`day` fields
/// always hold a concrete Gregorian month/day for the year currently being
/// viewed.
class LocalCalendarEntry {
  final String id;
  final int month;
  final int day;
  final String name;
  final String? latinName;
  final CelebrationRank rank;
  final LiturgicalColor color;
  final String? notes;

  const LocalCalendarEntry({
    required this.id,
    required this.month,
    required this.day,
    required this.name,
    this.latinName,
    required this.rank,
    required this.color,
    this.notes,
  });

  Celebration toCelebration() => Celebration(
        key: 'local.$id',
        name: name,
        latinName: latinName,
        rank: rank,
        color: color,
        source: CalendarSource.localSupplement,
      );

  FixedCelebration toFixedCelebration() =>
      FixedCelebration(month, day, toCelebration());
}
