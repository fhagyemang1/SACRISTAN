import 'computus.dart';
import 'models.dart';
import 'season_engine.dart';

/// A celebration fixed to a specific month/day on the General Roman
/// Calendar (as opposed to one whose date depends on Easter).
class FixedCelebration {
  final int month;
  final int day;
  final Celebration celebration;
  const FixedCelebration(this.month, this.day, this.celebration);
}

const _c = CalendarSource.generalRomanCalendar;

/// A representative subset of the General Roman Calendar's fixed-date
/// solemnities, feasts, and memorials — enough to cover every month, every
/// rank, and the celebrations sacristans most commonly need to prepare
/// for. This is not the complete ~250-entry universal calendar; extending
/// it further is purely additive data-entry work (see ARCHITECTURE.md).
final List<FixedCelebration> generalRomanCalendarFixed = [
  const FixedCelebration(1, 1, Celebration(
      key: 'maryMotherOfGod',
      name: 'Mary, Mother of God',
      latinName: 'Sollemnitas Sanctae Dei Genetricis Mariae',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 6, Celebration(
      key: 'epiphany',
      name: 'The Epiphany of the Lord',
      latinName: 'In Epiphania Domini',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c,
      goldPermitted: true)),
  const FixedCelebration(1, 17, Celebration(
      key: 'stAnthonyAbbot',
      name: 'St. Anthony, Abbot',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 25, Celebration(
      key: 'conversionOfStPaul',
      name: 'The Conversion of St. Paul the Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(2, 2, Celebration(
      key: 'presentationOfTheLord',
      name: 'The Presentation of the Lord',
      latinName: 'In Praesentatione Domini',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c,
      isFeastOfTheLord: true)),
  const FixedCelebration(2, 22, Celebration(
      key: 'chairOfStPeter',
      name: 'The Chair of St. Peter the Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(3, 17, Celebration(
      key: 'stPatrick',
      name: 'St. Patrick, Bishop',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(3, 19, Celebration(
      key: 'stJoseph',
      name: 'St. Joseph, Spouse of the Blessed Virgin Mary',
      latinName: 'Sancti Ioseph, Sponsi B.M.V.',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(3, 25, Celebration(
      key: 'annunciation',
      name: 'The Annunciation of the Lord',
      latinName: 'In Annuntiatione Domini',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(4, 25, Celebration(
      key: 'stMarkEvangelist',
      name: 'St. Mark, Evangelist',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(5, 1, Celebration(
      key: 'stJosephTheWorker',
      name: 'St. Joseph the Worker',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 31, Celebration(
      key: 'visitation',
      name: 'The Visitation of the Blessed Virgin Mary',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(6, 24, Celebration(
      key: 'nativityOfStJohnTheBaptist',
      name: 'The Nativity of St. John the Baptist',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(6, 29, Celebration(
      key: 'ssPeterAndPaul',
      name: 'Ss. Peter and Paul, Apostles',
      latinName: 'Ss. Petri et Pauli, Apostolorum',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(7, 22, Celebration(
      key: 'stMaryMagdalene',
      name: 'St. Mary Magdalene',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(7, 25, Celebration(
      key: 'stJamesApostle',
      name: 'St. James, Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(8, 6, Celebration(
      key: 'transfiguration',
      name: 'The Transfiguration of the Lord',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c,
      isFeastOfTheLord: true)),
  const FixedCelebration(8, 15, Celebration(
      key: 'assumption',
      name: 'The Assumption of the Blessed Virgin Mary',
      latinName: 'In Assumptione B.M.V.',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 8, Celebration(
      key: 'nativityOfMary',
      name: 'The Nativity of the Blessed Virgin Mary',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 14, Celebration(
      key: 'exaltationOfTheCross',
      name: 'The Exaltation of the Holy Cross',
      latinName: 'In Exaltatione Sanctae Crucis',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c,
      isFeastOfTheLord: true)),
  const FixedCelebration(9, 29, Celebration(
      key: 'archangels',
      name: 'Ss. Michael, Gabriel, and Raphael, Archangels',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 4, Celebration(
      key: 'stFrancisOfAssisi',
      name: 'St. Francis of Assisi',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 7, Celebration(
      key: 'ourLadyOfTheRosary',
      name: 'Our Lady of the Rosary',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 1, Celebration(
      key: 'allSaints',
      name: 'All Saints',
      latinName: 'Sollemnitas Omnium Sanctorum',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 2, Celebration(
      key: 'allSouls',
      name: 'The Commemoration of All the Faithful Departed (All Souls)',
      latinName: 'In Commemoratione Omnium Fidelium Defunctorum',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.violet,
      source: _c)),
  const FixedCelebration(11, 9, Celebration(
      key: 'dedicationLateran',
      name: 'The Dedication of the Lateran Basilica',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c,
      // The Lateran is the cathedral of Rome, dedicated to Christ the
      // Savior; this feast is conventionally grouped with the "Feasts of
      // the Lord in the General Calendar" (II.5) rather than with feasts
      // of a particular saint (II.7) for precedence purposes. Flagged as
      // the lowest-confidence classification in this file — unlike
      // Presentation/Transfiguration/Exaltation of the Cross, which are
      // unambiguous.
      isFeastOfTheLord: true)),
  const FixedCelebration(11, 30, Celebration(
      key: 'stAndrewApostle',
      name: 'St. Andrew, Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(12, 8, Celebration(
      key: 'immaculateConception',
      name: 'The Immaculate Conception of the Blessed Virgin Mary',
      latinName: 'In Conceptione Immaculata B.M.V.',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(12, 12, Celebration(
      key: 'ourLadyOfGuadalupe',
      name: 'Our Lady of Guadalupe',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(12, 25, Celebration(
      key: 'christmas',
      name: 'The Nativity of the Lord (Christmas)',
      latinName: 'In Nativitate Domini',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c,
      goldPermitted: true)),
  const FixedCelebration(12, 26, Celebration(
      key: 'stStephen',
      name: 'St. Stephen, First Martyr',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(12, 28, Celebration(
      key: 'holyInnocents',
      name: 'The Holy Innocents, Martyrs',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(12, 31, Celebration(
      key: 'stSylvester',
      name: 'St. Sylvester I, Pope',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
];

const _mv = CalendarSource.computed;

/// Movable-date (Easter-dependent, or otherwise computed) celebrations for
/// a given [year]. These are resolved separately from [generalRomanCalendarFixed]
/// because their date changes every year.
List<FixedCelebration> movableCelebrationsForYear(int year) {
  final md = MovableDates.forYear(year);
  Celebration mk(String key, String name, CelebrationRank rank,
          LiturgicalColor color,
          {bool gold = false, String? latin, bool isLord = false}) =>
      Celebration(
          key: key,
          name: name,
          latinName: latin,
          rank: rank,
          color: color,
          source: _mv,
          goldPermitted: gold,
          isFeastOfTheLord: isLord);

  FixedCelebration f(DateTime d, Celebration c) => FixedCelebration(d.month, d.day, c);

  return [
    f(md.ashWednesday, mk('ashWednesday', 'Ash Wednesday', CelebrationRank.ferial, LiturgicalColor.violet, latin: 'Feria IV Cinerum')),
    f(md.palmSunday, mk('palmSunday', 'Palm Sunday of the Lord\'s Passion', CelebrationRank.sunday, LiturgicalColor.red, latin: 'Dominica in Palmis de Passione Domini')),
    // Monday-Wednesday of Holy Week: ordinary ferial rank, but — like Ash
    // Wednesday — top liturgical precedence (Table of Liturgical Days,
    // General Norms n. 59, tier I.2), so nothing (not even a solemnity)
    // may be celebrated in their place. See the `topPrecedenceKeys` set in
    // calendar_engine.dart, which is what actually enforces that; without
    // these three explicit entries, these days previously fell through to
    // the generic "Lenten Weekday, Week 6" filler and carried no special
    // precedence protection at all — fixed in round 6.
    f(md.mondayHolyWeek, mk('holyMonday', 'Monday of Holy Week', CelebrationRank.ferial, LiturgicalColor.violet, latin: 'Feria II Hebdomadae Sanctae')),
    f(md.tuesdayHolyWeek, mk('holyTuesday', 'Tuesday of Holy Week', CelebrationRank.ferial, LiturgicalColor.violet, latin: 'Feria III Hebdomadae Sanctae')),
    f(md.wednesdayHolyWeek, mk('holyWednesday', 'Wednesday of Holy Week', CelebrationRank.ferial, LiturgicalColor.violet, latin: 'Feria IV Hebdomadae Sanctae')),
    f(md.holyThursday, mk('holyThursday', 'Holy Thursday — Evening Mass of the Lord\'s Supper', CelebrationRank.triduum, LiturgicalColor.white, latin: 'Feria V in Cena Domini')),
    f(md.goodFriday, mk('goodFriday', 'Good Friday of the Passion of the Lord', CelebrationRank.triduum, LiturgicalColor.red, latin: 'Feria VI in Passione Domini')),
    f(md.holySaturday, mk('holySaturday', 'Holy Saturday — the Easter Vigil (after nightfall)', CelebrationRank.triduum, LiturgicalColor.white, gold: true, latin: 'Sabbato Sancto — Vigilia Paschalis')),
    f(md.easterSunday, mk('easterSunday', 'Easter Sunday of the Resurrection of the Lord', CelebrationRank.solemnity, LiturgicalColor.white, gold: true, latin: 'Dominica Resurrectionis')),
    f(md.divineMercySunday, mk('divineMercySunday', 'Second Sunday of Easter (Divine Mercy Sunday)', CelebrationRank.sunday, LiturgicalColor.white)),
    f(md.pentecost, mk('pentecost', 'Pentecost Sunday', CelebrationRank.solemnity, LiturgicalColor.red, latin: 'Dominica Pentecostes')),
    f(md.trinitySunday, mk('trinitySunday', 'The Most Holy Trinity', CelebrationRank.solemnity, LiturgicalColor.white, latin: 'Sanctissimae Trinitatis')),
    f(md.corpusChristiSunday, mk('corpusChristi', 'The Most Holy Body and Blood of Christ (Corpus Christi)', CelebrationRank.solemnity, LiturgicalColor.white, gold: true, latin: 'Sanctissimi Corporis et Sanguinis Christi')),
    f(md.sacredHeartFriday, mk('sacredHeart', 'The Most Sacred Heart of Jesus', CelebrationRank.solemnity, LiturgicalColor.white, latin: 'Sanctissimi Cordis Iesu')),
    f(baptismOfTheLord(year), mk('baptismOfTheLord', 'The Baptism of the Lord', CelebrationRank.feast, LiturgicalColor.white, isLord: true)),
    // Holy Family is the proper title of the Sunday within the Octave of
    // Christmas (or, when Christmas Day itself is a Sunday, of Dec 30) —
    // it is the Christmas-season counterpart to how Divine Mercy Sunday
    // and Palm Sunday occupy their own proper Sundays. It must therefore
    // always outrank an ordinary Feast of a Saint fixed to the same date
    // (Dec 26 St. Stephen, Dec 28 Holy Innocents) as well as the generic
    // "Sunday within the Christmas Season" filler — treating it as a
    // Feast of the Lord (tier II.5, same as e.g. the Presentation) rather
    // than an ordinary Feast of a Saint (II.7) is what guarantees that in
    // `calendar_engine.dart`'s `_tier()`. See the explicit key-based
    // tie-break in `resolveLiturgicalDay`'s comparator for a second,
    // independent guard on top of this classification.
    f(holyFamily(year), mk('holyFamily', 'The Holy Family of Jesus, Mary and Joseph', CelebrationRank.feast, LiturgicalColor.white, isLord: true)),
    f(christTheKing(year), mk('christTheKing', 'Our Lord Jesus Christ, King of the Universe', CelebrationRank.solemnity, LiturgicalColor.white, latin: 'Domini Nostri Iesu Christi Universorum Regis')),
    // Ascension is shown at its traditional Thursday date (Easter+39). Many
    // episcopal conferences transfer the celebration to the following
    // Sunday (Easter+42) by decree; parishes that follow a transferred
    // Ascension should add/override this via the local supplementary
    // calendar (see local_calendar.dart) rather than the engine silently
    // guessing regional practice.
    f(md.ascensionThursday, mk('ascension', 'The Ascension of the Lord', CelebrationRank.solemnity, LiturgicalColor.white, latin: 'In Ascensione Domini')),
  ];
}
