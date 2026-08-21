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
  FixedCelebration(1, 1, const Celebration(
      key: 'maryMotherOfGod',
      name: 'Mary, Mother of God',
      latinName: 'Sollemnitas Sanctae Dei Genetricis Mariae',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(1, 6, const Celebration(
      key: 'epiphany',
      name: 'The Epiphany of the Lord',
      latinName: 'In Epiphania Domini',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c,
      goldPermitted: true)),
  FixedCelebration(1, 17, const Celebration(
      key: 'stAnthonyAbbot',
      name: 'St. Anthony, Abbot',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(1, 25, const Celebration(
      key: 'conversionOfStPaul',
      name: 'The Conversion of St. Paul the Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(2, 2, const Celebration(
      key: 'presentationOfTheLord',
      name: 'The Presentation of the Lord',
      latinName: 'In Praesentatione Domini',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(2, 22, const Celebration(
      key: 'chairOfStPeter',
      name: 'The Chair of St. Peter the Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(3, 17, const Celebration(
      key: 'stPatrick',
      name: 'St. Patrick, Bishop',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(3, 19, const Celebration(
      key: 'stJoseph',
      name: 'St. Joseph, Spouse of the Blessed Virgin Mary',
      latinName: 'Sancti Ioseph, Sponsi B.M.V.',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(3, 25, const Celebration(
      key: 'annunciation',
      name: 'The Annunciation of the Lord',
      latinName: 'In Annuntiatione Domini',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(4, 25, const Celebration(
      key: 'stMarkEvangelist',
      name: 'St. Mark, Evangelist',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  FixedCelebration(5, 1, const Celebration(
      key: 'stJosephTheWorker',
      name: 'St. Joseph the Worker',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(5, 31, const Celebration(
      key: 'visitation',
      name: 'The Visitation of the Blessed Virgin Mary',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(6, 24, const Celebration(
      key: 'nativityOfStJohnTheBaptist',
      name: 'The Nativity of St. John the Baptist',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(6, 29, const Celebration(
      key: 'ssPeterAndPaul',
      name: 'Ss. Peter and Paul, Apostles',
      latinName: 'Ss. Petri et Pauli, Apostolorum',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.red,
      source: _c)),
  FixedCelebration(7, 22, const Celebration(
      key: 'stMaryMagdalene',
      name: 'St. Mary Magdalene',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(7, 25, const Celebration(
      key: 'stJamesApostle',
      name: 'St. James, Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  FixedCelebration(8, 6, const Celebration(
      key: 'transfiguration',
      name: 'The Transfiguration of the Lord',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(8, 15, const Celebration(
      key: 'assumption',
      name: 'The Assumption of the Blessed Virgin Mary',
      latinName: 'In Assumptione B.M.V.',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(9, 8, const Celebration(
      key: 'nativityOfMary',
      name: 'The Nativity of the Blessed Virgin Mary',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(9, 14, const Celebration(
      key: 'exaltationOfTheCross',
      name: 'The Exaltation of the Holy Cross',
      latinName: 'In Exaltatione Sanctae Crucis',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  FixedCelebration(9, 29, const Celebration(
      key: 'archangels',
      name: 'Ss. Michael, Gabriel, and Raphael, Archangels',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(10, 4, const Celebration(
      key: 'stFrancisOfAssisi',
      name: 'St. Francis of Assisi',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(10, 7, const Celebration(
      key: 'ourLadyOfTheRosary',
      name: 'Our Lady of the Rosary',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(11, 1, const Celebration(
      key: 'allSaints',
      name: 'All Saints',
      latinName: 'Sollemnitas Omnium Sanctorum',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(11, 2, const Celebration(
      key: 'allSouls',
      name: 'The Commemoration of All the Faithful Departed (All Souls)',
      latinName: 'In Commemoratione Omnium Fidelium Defunctorum',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.violet,
      source: _c)),
  FixedCelebration(11, 9, const Celebration(
      key: 'dedicationLateran',
      name: 'The Dedication of the Lateran Basilica',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(11, 30, const Celebration(
      key: 'stAndrewApostle',
      name: 'St. Andrew, Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  FixedCelebration(12, 8, const Celebration(
      key: 'immaculateConception',
      name: 'The Immaculate Conception of the Blessed Virgin Mary',
      latinName: 'In Conceptione Immaculata B.M.V.',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(12, 12, const Celebration(
      key: 'ourLadyOfGuadalupe',
      name: 'Our Lady of Guadalupe',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  FixedCelebration(12, 25, const Celebration(
      key: 'christmas',
      name: 'The Nativity of the Lord (Christmas)',
      latinName: 'In Nativitate Domini',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c,
      goldPermitted: true)),
  FixedCelebration(12, 26, const Celebration(
      key: 'stStephen',
      name: 'St. Stephen, First Martyr',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  FixedCelebration(12, 28, const Celebration(
      key: 'holyInnocents',
      name: 'The Holy Innocents, Martyrs',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  FixedCelebration(12, 31, const Celebration(
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
          {bool gold = false, String? latin}) =>
      Celebration(
          key: key,
          name: name,
          latinName: latin,
          rank: rank,
          color: color,
          source: _mv,
          goldPermitted: gold);

  FixedCelebration f(DateTime d, Celebration c) => FixedCelebration(d.month, d.day, c);

  return [
    f(md.ashWednesday, mk('ashWednesday', 'Ash Wednesday', CelebrationRank.ferial, LiturgicalColor.violet, latin: 'Feria IV Cinerum')),
    f(md.palmSunday, mk('palmSunday', "Palm Sunday of the Lord's Passion", CelebrationRank.sunday, LiturgicalColor.red, latin: 'Dominica in Palmis de Passione Domini')),
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
    f(md.holyThursday, mk('holyThursday', "Holy Thursday — Evening Mass of the Lord's Supper", CelebrationRank.triduum, LiturgicalColor.white, latin: 'Feria V in Cena Domini')),
    f(md.goodFriday, mk('goodFriday', 'Good Friday of the Passion of the Lord', CelebrationRank.triduum, LiturgicalColor.red, latin: 'Feria VI in Passione Domini')),
    f(md.holySaturday, mk('holySaturday', 'Holy Saturday — the Easter Vigil (after nightfall)', CelebrationRank.triduum, LiturgicalColor.white, gold: true, latin: 'Sabbato Sancto — Vigilia Paschalis')),
    f(md.easterSunday, mk('easterSunday', 'Easter Sunday of the Resurrection of the Lord', CelebrationRank.solemnity, LiturgicalColor.white, gold: true, latin: 'Dominica Resurrectionis')),
    f(md.divineMercySunday, mk('divineMercySunday', 'Second Sunday of Easter (Divine Mercy Sunday)', CelebrationRank.sunday, LiturgicalColor.white)),
    f(md.pentecost, mk('pentecost', 'Pentecost Sunday', CelebrationRank.solemnity, LiturgicalColor.red, latin: 'Dominica Pentecostes')),
    f(md.trinitySunday, mk('trinitySunday', 'The Most Holy Trinity', CelebrationRank.solemnity, LiturgicalColor.white, latin: 'Sanctissimae Trinitatis')),
    f(md.corpusChristiSunday, mk('corpusChristi', 'The Most Holy Body and Blood of Christ (Corpus Christi)', CelebrationRank.solemnity, LiturgicalColor.white, gold: true, latin: 'Sanctissimi Corporis et Sanguinis Christi')),
    f(md.sacredHeartFriday, mk('sacredHeart', 'The Most Sacred Heart of Jesus', CelebrationRank.solemnity, LiturgicalColor.white, latin: 'Sanctissimi Cordis Iesu')),
    f(baptismOfTheLord(year), mk('baptismOfTheLord', 'The Baptism of the Lord', CelebrationRank.feast, LiturgicalColor.white)),
    f(holyFamily(year), mk('holyFamily', 'The Holy Family of Jesus, Mary and Joseph', CelebrationRank.feast, LiturgicalColor.white)),
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
