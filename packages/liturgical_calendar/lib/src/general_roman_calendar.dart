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

/// Round 16: crosschecked and filled out against a parish-supplied
/// reference (Ghana Catholic Church perpetual liturgical calendar,
/// General Roman Calendar base) after a real sacristan found two missing
/// dates — Oct 1 (St. Thérèse of the Child Jesus) and Oct 2 (Holy
/// Guardian Angels) — showing as plain green Ordinary Time instead of
/// their proper white Memorial color. That specific gap is fixed below,
/// and the same reference was used to add every other fixed-date entry
/// it lists that this file was still missing, bringing coverage from 37
/// to 150 fixed dates. Optional memorials' colors here are not load-
/// bearing for display — calendar_engine.dart's `_tier()` ranks
/// CelebrationRank.optionalMemorial below the generic ferial filler, so
/// an optional memorial never overrides the day's shown color regardless
/// of which color is recorded here; only Memorial rank and above do.
/// Still not a literal 1:1 copy of the ~250-some-entry universal General
/// Roman Calendar (a few very minor regional-option dates were left out),
/// but every date in the source reference document is now represented.
final List<FixedCelebration> generalRomanCalendarFixed = [
  const FixedCelebration(1, 1, Celebration(
      key: 'maryMotherOfGod',
      name: 'Mary, Mother of God',
      latinName: 'Sollemnitas Sanctae Dei Genetricis Mariae',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 2, Celebration(
      key: 'ssBasilAndGregoryNazianzen',
      name: 'Ss. Basil the Great and Gregory Nazianzen, Bishops and Doctors',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 3, Celebration(
      key: 'holyNameOfJesus',
      name: 'The Most Holy Name of Jesus',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 4, Celebration(
      key: 'stElizabethAnnSeton',
      name: 'St. Elizabeth Ann Seton, Religious',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 5, Celebration(
      key: 'stJohnNeumann',
      name: 'St. John Neumann, Bishop',
      rank: CelebrationRank.optionalMemorial,
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
  const FixedCelebration(1, 6, Celebration(
      key: 'stAndreBessette',
      name: 'St. André Bessette, Religious',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 7, Celebration(
      key: 'stRaymondOfPenyafort',
      name: 'St. Raymond of Penyafort, Priest',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 13, Celebration(
      key: 'stHilary',
      name: 'St. Hilary, Bishop and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 17, Celebration(
      key: 'stAnthonyAbbot',
      name: 'St. Anthony, Abbot',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 20, Celebration(
      key: 'ssFabianAndSebastian',
      name: 'Ss. Fabian, Pope, and Sebastian, Martyrs',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(1, 21, Celebration(
      key: 'stAgnes',
      name: 'St. Agnes, Virgin and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(1, 24, Celebration(
      key: 'stFrancisDeSales',
      name: 'St. Francis de Sales, Bishop and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 25, Celebration(
      key: 'conversionOfStPaul',
      name: 'The Conversion of St. Paul the Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 26, Celebration(
      key: 'ssTimothyAndTitus',
      name: 'Ss. Timothy and Titus, Bishops',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 28, Celebration(
      key: 'stThomasAquinas',
      name: 'St. Thomas Aquinas, Priest and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(1, 31, Celebration(
      key: 'stJohnBosco',
      name: 'St. John Bosco, Priest',
      rank: CelebrationRank.memorial,
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
  const FixedCelebration(2, 3, Celebration(
      key: 'ssBlaiseAndAnsgar',
      name: 'Ss. Blaise, Bishop and Martyr, and Ansgar, Bishop',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(2, 5, Celebration(
      key: 'stAgatha',
      name: 'St. Agatha, Virgin and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(2, 6, Celebration(
      key: 'stPaulMikiAndCompanions',
      name: 'St. Paul Miki and Companions, Martyrs',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(2, 10, Celebration(
      key: 'stScholastica',
      name: 'St. Scholastica, Virgin',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(2, 11, Celebration(
      key: 'ourLadyOfLourdes',
      name: 'Our Lady of Lourdes',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(2, 14, Celebration(
      key: 'ssCyrilAndMethodius',
      name: 'Ss. Cyril, Monk, and Methodius, Bishop',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(2, 22, Celebration(
      key: 'chairOfStPeter',
      name: 'The Chair of St. Peter the Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(2, 23, Celebration(
      key: 'stPolycarp',
      name: 'St. Polycarp, Bishop and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(2, 27, Celebration(
      key: 'stGregoryOfNarek',
      name: 'St. Gregory of Narek, Abbot and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(3, 4, Celebration(
      key: 'stCasimir',
      name: 'St. Casimir',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(3, 7, Celebration(
      key: 'ssPerpetuaAndFelicity',
      name: 'Ss. Perpetua and Felicity, Martyrs',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(3, 8, Celebration(
      key: 'stJohnOfGod',
      name: 'St. John of God, Religious',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(3, 9, Celebration(
      key: 'stFrancesOfRome',
      name: 'St. Frances of Rome, Religious',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(3, 17, Celebration(
      key: 'stPatrick',
      name: 'St. Patrick, Bishop',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(3, 18, Celebration(
      key: 'stCyrilOfJerusalem',
      name: 'St. Cyril of Jerusalem, Bishop and Doctor',
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
  const FixedCelebration(4, 2, Celebration(
      key: 'stFrancisOfPaola',
      name: 'St. Francis of Paola, Hermit',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(4, 4, Celebration(
      key: 'stIsidore',
      name: 'St. Isidore, Bishop and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(4, 21, Celebration(
      key: 'stAnselm',
      name: 'St. Anselm, Bishop and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(4, 23, Celebration(
      key: 'ssGeorgeAndAdalbert',
      name: 'Ss. George, Martyr, and Adalbert, Bishop and Martyr',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(4, 24, Celebration(
      key: 'stFidelisOfSigmaringen',
      name: 'St. Fidelis of Sigmaringen, Priest and Martyr',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(4, 25, Celebration(
      key: 'stMarkEvangelist',
      name: 'St. Mark, Evangelist',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(4, 28, Celebration(
      key: 'stPeterChanelAndLouisDeMontfort',
      name: 'St. Peter Chanel, Priest and Martyr, and St. Louis Grignion de Montfort, Priest',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(4, 29, Celebration(
      key: 'stCatherineOfSiena',
      name: 'St. Catherine of Siena, Virgin and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(4, 30, Celebration(
      key: 'stPiusV',
      name: 'St. Pius V, Pope',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 1, Celebration(
      key: 'stJosephTheWorker',
      name: 'St. Joseph the Worker',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 2, Celebration(
      key: 'stAthanasius',
      name: 'St. Athanasius, Bishop and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 3, Celebration(
      key: 'ssPhilipAndJames',
      name: 'Ss. Philip and James, Apostles',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(5, 10, Celebration(
      key: 'stJohnOfAvila',
      name: 'St. John of Ávila, Priest and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 13, Celebration(
      key: 'ourLadyOfFatima',
      name: 'Our Lady of Fatima',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 14, Celebration(
      key: 'stMatthias',
      name: 'St. Matthias, Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(5, 18, Celebration(
      key: 'stJohnIPope',
      name: 'St. John I, Pope and Martyr',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(5, 20, Celebration(
      key: 'stBernardineOfSiena',
      name: 'St. Bernardine of Siena, Priest',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 22, Celebration(
      key: 'stRitaOfCascia',
      name: 'St. Rita of Cascia, Religious',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 29, Celebration(
      key: 'stPaulVI',
      name: 'St. Paul VI, Pope',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(5, 31, Celebration(
      key: 'visitation',
      name: 'The Visitation of the Blessed Virgin Mary',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(6, 1, Celebration(
      key: 'stJustinMartyr',
      name: 'St. Justin, Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(6, 3, Celebration(
      key: 'stCharlesLwangaAndCompanions',
      name: 'St. Charles Lwanga and Companions, Martyrs',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(6, 5, Celebration(
      key: 'stBoniface',
      name: 'St. Boniface, Bishop and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(6, 9, Celebration(
      key: 'stEphrem',
      name: 'St. Ephrem, Deacon and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(6, 11, Celebration(
      key: 'stBarnabas',
      name: 'St. Barnabas, Apostle',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(6, 13, Celebration(
      key: 'stAnthonyOfPadua',
      name: 'St. Anthony of Padua, Priest and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(6, 21, Celebration(
      key: 'stAloysiusGonzaga',
      name: 'St. Aloysius Gonzaga, Religious',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(6, 22, Celebration(
      key: 'stPaulinusOfNolaAndFisherMore',
      name: 'St. Paulinus of Nola, Bishop, and Ss. John Fisher and Thomas More, Martyrs',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(6, 24, Celebration(
      key: 'nativityOfStJohnTheBaptist',
      name: 'The Nativity of St. John the Baptist',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(6, 28, Celebration(
      key: 'stIrenaeus',
      name: 'St. Irenaeus, Bishop and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(6, 29, Celebration(
      key: 'ssPeterAndPaul',
      name: 'Ss. Peter and Paul, Apostles',
      latinName: 'Ss. Petri et Pauli, Apostolorum',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(7, 3, Celebration(
      key: 'stThomasApostle',
      name: 'St. Thomas, Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(7, 11, Celebration(
      key: 'stBenedict',
      name: 'St. Benedict, Abbot',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(7, 14, Celebration(
      key: 'stCamillusDeLellis',
      name: 'St. Camillus de Lellis, Priest',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(7, 15, Celebration(
      key: 'stBonaventure',
      name: 'St. Bonaventure, Bishop and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(7, 16, Celebration(
      key: 'ourLadyOfMountCarmel',
      name: 'Our Lady of Mount Carmel',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
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
  const FixedCelebration(7, 26, Celebration(
      key: 'ssJoachimAndAnne',
      name: 'Ss. Joachim and Anne, Parents of the Blessed Virgin Mary',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(7, 29, Celebration(
      key: 'ssMarthaMaryAndLazarus',
      name: 'Ss. Martha, Mary and Lazarus',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(7, 31, Celebration(
      key: 'stIgnatiusOfLoyola',
      name: 'St. Ignatius of Loyola, Priest',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 1, Celebration(
      key: 'stAlphonsusLiguori',
      name: 'St. Alphonsus Liguori, Bishop and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 4, Celebration(
      key: 'stJohnVianney',
      name: 'St. John Vianney, Priest',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 5, Celebration(
      key: 'dedicationStMaryMajor',
      name: 'The Dedication of the Basilica of St. Mary Major',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 6, Celebration(
      key: 'transfiguration',
      name: 'The Transfiguration of the Lord',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c,
      isFeastOfTheLord: true)),
  const FixedCelebration(8, 8, Celebration(
      key: 'stDominic',
      name: 'St. Dominic, Priest',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 9, Celebration(
      key: 'stTeresaBenedictaOfTheCross',
      name: 'St. Teresa Benedicta of the Cross (Edith Stein), Virgin and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(8, 10, Celebration(
      key: 'stLawrence',
      name: 'St. Lawrence, Deacon and Martyr',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(8, 11, Celebration(
      key: 'stClare',
      name: 'St. Clare, Virgin',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 14, Celebration(
      key: 'stMaximilianKolbe',
      name: 'St. Maximilian Mary Kolbe, Priest and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(8, 15, Celebration(
      key: 'assumption',
      name: 'The Assumption of the Blessed Virgin Mary',
      latinName: 'In Assumptione B.M.V.',
      rank: CelebrationRank.solemnity,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 20, Celebration(
      key: 'stBernardOfClairvaux',
      name: 'St. Bernard, Abbot and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 21, Celebration(
      key: 'stPiusX',
      name: 'St. Pius X, Pope',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 22, Celebration(
      key: 'queenshipOfMary',
      name: 'The Queenship of the Blessed Virgin Mary',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 24, Celebration(
      key: 'stBartholomew',
      name: 'St. Bartholomew, Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(8, 27, Celebration(
      key: 'stMonica',
      name: 'St. Monica',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 28, Celebration(
      key: 'stAugustineOfHippo',
      name: 'St. Augustine, Bishop and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(8, 29, Celebration(
      key: 'beheadingOfStJohnTheBaptist',
      name: 'The Beheading of St. John the Baptist',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(9, 3, Celebration(
      key: 'stGregoryTheGreat',
      name: 'St. Gregory the Great, Pope and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 5, Celebration(
      key: 'stTeresaOfCalcutta',
      name: 'St. Teresa of Calcutta, Virgin',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 8, Celebration(
      key: 'nativityOfMary',
      name: 'The Nativity of the Blessed Virgin Mary',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 9, Celebration(
      key: 'stPeterClaver',
      name: 'St. Peter Claver, Priest',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 12, Celebration(
      key: 'mostHolyNameOfMary',
      name: 'The Most Holy Name of Mary',
      rank: CelebrationRank.optionalMemorial,
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
  // Round 15: this file's own doc comment (line 16-20 above) flags it as
  // "a representative subset," not the complete calendar — but that gap
  // is exactly what let a real sacristan open the app on Sept 16, 2026
  // and see a generic Ordinary Time weekday instead of the actual
  // Memorial of Ss. Cornelius and Cyprian (red), because nothing between
  // Sept 14 (Exaltation of the Cross, already present) and Sept 29
  // (Archangels, already present) existed for `resolveLiturgicalDay` to
  // find. Filling in that specific date plus its immediate obligatory
  // neighbors (the ones that actually change the day's color/rank, as
  // opposed to optional memorials, which `_tier()` in calendar_engine.dart
  // already ranks below the generic ferial filler at tier 9 and so never
  // override the day's color) — verified against Catholic Culture's own
  // published Liturgical Year Calendar overview for September rather than
  // assumed from memory.
  const FixedCelebration(9, 15, Celebration(
      key: 'ourLadyOfSorrows',
      name: 'Our Lady of Sorrows',
      latinName: 'Beatae Mariae Virginis Perdolentis',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 16, Celebration(
      key: 'ssCorneliusAndCyprian',
      name: 'Ss. Cornelius, Pope, and Cyprian, Bishop, Martyrs',
      latinName: 'Ss. Cornelii et Cypriani',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(9, 17, Celebration(
      key: 'stHildegardOfBingen',
      name: 'St. Hildegard of Bingen, Virgin and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 21, Celebration(
      key: 'stMatthewApostle',
      name: 'St. Matthew, Apostle and Evangelist',
      latinName: 'Sancti Matthaei, Apostoli et Evangelistae',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(9, 23, Celebration(
      key: 'stPioOfPietrelcina',
      name: 'St. Pio of Pietrelcina, Priest',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 27, Celebration(
      key: 'stVincentDePaul',
      name: 'St. Vincent de Paul, Priest',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 29, Celebration(
      key: 'archangels',
      name: 'Ss. Michael, Gabriel, and Raphael, Archangels',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(9, 30, Celebration(
      key: 'stJerome',
      name: 'St. Jerome, Priest and Doctor of the Church',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 1, Celebration(
      key: 'stThereseOfLisieux',
      name: 'St. Thérèse of the Child Jesus, Virgin and Doctor of the Church',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 2, Celebration(
      key: 'holyGuardianAngels',
      name: 'The Holy Guardian Angels',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 4, Celebration(
      key: 'stFrancisOfAssisi',
      name: 'St. Francis of Assisi',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 5, Celebration(
      key: 'stFaustinaKowalska',
      name: 'St. Faustina Kowalska, Virgin',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 7, Celebration(
      key: 'ourLadyOfTheRosary',
      name: 'Our Lady of the Rosary',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 9, Celebration(
      key: 'stJohnHenryNewman',
      name: 'St. John Henry Newman, Priest and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 11, Celebration(
      key: 'stJohnXXIII',
      name: 'St. John XXIII, Pope',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 15, Celebration(
      key: 'stTeresaOfJesus',
      name: 'St. Teresa of Jesus (Ávila), Virgin and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 17, Celebration(
      key: 'stIgnatiusOfAntioch',
      name: 'St. Ignatius of Antioch, Bishop and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(10, 18, Celebration(
      key: 'stLukeEvangelist',
      name: 'St. Luke, Evangelist',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(10, 22, Celebration(
      key: 'stJohnPaulII',
      name: 'St. John Paul II, Pope',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(10, 28, Celebration(
      key: 'ssSimonAndJude',
      name: 'Ss. Simon and Jude, Apostles',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
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
  const FixedCelebration(11, 3, Celebration(
      key: 'stMartinDePorres',
      name: 'St. Martin de Porres, Religious',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 4, Celebration(
      key: 'stCharlesBorromeo',
      name: 'St. Charles Borromeo, Bishop',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 5, Celebration(
      key: 'ssZacharyAndElizabeth',
      name: 'Ss. Zachary and Elizabeth',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
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
  const FixedCelebration(11, 10, Celebration(
      key: 'stLeoTheGreat',
      name: 'St. Leo the Great, Pope and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 11, Celebration(
      key: 'stMartinOfTours',
      name: 'St. Martin of Tours, Bishop',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 12, Celebration(
      key: 'stJosaphat',
      name: 'St. Josaphat, Bishop and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(11, 15, Celebration(
      key: 'stAlbertTheGreat',
      name: 'St. Albert the Great, Bishop and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 16, Celebration(
      key: 'stMargaretOfScotlandAndGertrude',
      name: 'St. Margaret of Scotland, and St. Gertrude, Virgin',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 17, Celebration(
      key: 'stElizabethOfHungary',
      name: 'St. Elizabeth of Hungary, Religious',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 21, Celebration(
      key: 'presentationOfMary',
      name: 'The Presentation of the Blessed Virgin Mary',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(11, 22, Celebration(
      key: 'stCecilia',
      name: 'St. Cecilia, Virgin and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(11, 24, Celebration(
      key: 'stAndrewDungLacAndCompanions',
      name: 'St. Andrew Dũng-Lạc and Companions, Martyrs',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(11, 30, Celebration(
      key: 'stAndrewApostle',
      name: 'St. Andrew, Apostle',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(12, 1, Celebration(
      key: 'blessedCharlesDeFoucauld',
      name: 'Blessed Charles de Foucauld, Priest',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(12, 3, Celebration(
      key: 'stFrancisXavier',
      name: 'St. Francis Xavier, Priest',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(12, 4, Celebration(
      key: 'stJohnDamascene',
      name: 'St. John Damascene, Priest and Doctor',
      rank: CelebrationRank.optionalMemorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(12, 7, Celebration(
      key: 'stAmbrose',
      name: 'St. Ambrose, Bishop and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
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
  const FixedCelebration(12, 13, Celebration(
      key: 'stLucy',
      name: 'St. Lucy, Virgin and Martyr',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(12, 14, Celebration(
      key: 'stJohnOfTheCross',
      name: 'St. John of the Cross, Priest and Doctor',
      rank: CelebrationRank.memorial,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(12, 21, Celebration(
      key: 'stPeterCanisius',
      name: 'St. Peter Canisius, Priest and Doctor',
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
  const FixedCelebration(12, 27, Celebration(
      key: 'stJohnApostleEvangelist',
      name: 'St. John, Apostle and Evangelist',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.white,
      source: _c)),
  const FixedCelebration(12, 28, Celebration(
      key: 'holyInnocents',
      name: 'The Holy Innocents, Martyrs',
      rank: CelebrationRank.feast,
      color: LiturgicalColor.red,
      source: _c)),
  const FixedCelebration(12, 29, Celebration(
      key: 'stThomasBecket',
      name: 'St. Thomas Becket, Bishop and Martyr',
      rank: CelebrationRank.optionalMemorial,
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
