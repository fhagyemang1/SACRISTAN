import '../../data/database.dart';

/// Plain-data seed for the built-in checklist templates. Inserted into the
/// local database once, on first launch (see `seedBuiltinTemplates` in
/// `main.dart`) — after that, a parish is free to edit, duplicate, or
/// delete them like any other template; nothing here is fetched from a
/// network, and nothing about it requires one.
class BuiltinItem {
  final String labelKey;
  final String label;
  final String? latin;
  const BuiltinItem(this.labelKey, this.label, [this.latin]);
}

class BuiltinTemplate {
  final String name;
  final MassType massType;
  final String phase; // 'pre' | 'post'
  final List<BuiltinItem> items;
  const BuiltinTemplate(this.name, this.massType, this.phase, this.items);
}

const _preMassCore = [
  BuiltinItem('vestments', 'Vestments matching today\'s color laid out',
      'Vestes Sacrae'),
  BuiltinItem('chalice', 'Chalice and paten set out', 'Calix et Patena'),
  BuiltinItem('purificator', 'Purificator', 'Purificatorium'),
  BuiltinItem('corporal', 'Corporal', 'Corporale'),
  BuiltinItem('pall', 'Pall (if used)', 'Palla'),
  BuiltinItem('cruets', 'Cruets of water and wine filled', 'Ampullae'),
  BuiltinItem('hosts', 'Sufficient hosts prepared'),
  BuiltinItem('candles', 'Altar candles placed and ready to light'),
  BuiltinItem('missalRibbons', 'Missal and ribbons set to today\'s readings',
      'Missale Romanum'),
  BuiltinItem('bell', 'Sacristy/sanctuary bell in place', 'Tintinnabulum'),
  BuiltinItem('sanctuaryLamp', 'Sanctuary lamp checked and lit'),
];

const _thuribleItem =
    BuiltinItem('thurible', 'Thurible and incense prepared, if used', 'Thuribulum');

const _postMassCore = [
  BuiltinItem('purifyVessels', 'Vessels purified and stored', 'Purificatio Vasorum'),
  BuiltinItem('extinguishCandles', 'Candles extinguished'),
  BuiltinItem('linensToSoak', 'Purificators/corporals set aside for the first rinse '
      '(see Reference > Linen Care)'),
  BuiltinItem('restock', 'Hosts/wine/candle stock checked and restocked if needed'),
  BuiltinItem('sanctuaryReset', 'Sanctuary restored to order'),
];

// Every entry below is `const` — each `items` list is either a direct
// reference to an already-const top-level list (`_preMassCore` /
// `_postMassCore`) or an inline `const [...]` literal (spreads of a
// const list plus const `BuiltinItem`s are themselves valid compile-time
// constants). Previously only the individual `BuiltinItem`s were const,
// not the enclosing `BuiltinTemplate`/list — round 9's first real
// `flutter analyze` run flagged all of these as `prefer_const_constructors`.
final List<BuiltinTemplate> builtinTemplates = [
  const BuiltinTemplate('Sunday Mass — Before Mass', MassType.sunday, 'pre',
      [..._preMassCore, _thuribleItem]),
  const BuiltinTemplate('Sunday Mass — After Mass', MassType.sunday, 'post', _postMassCore),
  const BuiltinTemplate('Weekday Mass — Before Mass', MassType.weekday, 'pre', _preMassCore),
  const BuiltinTemplate('Weekday Mass — After Mass', MassType.weekday, 'post', _postMassCore),
  const BuiltinTemplate('Funeral Mass — Before Mass', MassType.funeral, 'pre', [
    ..._preMassCore,
    BuiltinItem('paschalCandleFuneral', 'Paschal candle placed by the casket'),
    BuiltinItem('pallFuneral', 'Funeral pall available for the casket'),
    BuiltinItem('holyWaterFuneral', 'Holy water and sprinkler ready'),
    BuiltinItem('coordFuneralDirector', 'Coordinate timing with the funeral director'),
  ]),
  const BuiltinTemplate('Funeral Mass — After Mass', MassType.funeral, 'post', _postMassCore),
  const BuiltinTemplate('Wedding — Before Mass', MassType.wedding, 'pre', [
    ..._preMassCore,
    BuiltinItem('unityCandle', 'Unity candle / other requested items placed, per pastor\'s policy'),
    BuiltinItem('kneelers', 'Kneelers set out for the couple'),
    BuiltinItem('ringsReminder', 'Confirm best man/maid of honor know where to bring the rings'),
  ]),
  const BuiltinTemplate('Wedding — After Mass', MassType.wedding, 'post', _postMassCore),
  const BuiltinTemplate('Baptism — Before', MassType.baptism, 'pre', [
    BuiltinItem('baptismalWater', 'Baptismal water ready in the font'),
    BuiltinItem('oilOfCatechumens', 'Oil of Catechumens available'),
    BuiltinItem('sacredChrism', 'Sacred Chrism available'),
    BuiltinItem('whiteGarment', 'White garment ready'),
    BuiltinItem('baptismalCandle', 'Baptismal candle ready (lit from the paschal candle)'),
    BuiltinItem('towels', 'Towels for the child/candidate'),
  ]),
  const BuiltinTemplate('Baptism — After', MassType.baptism, 'post', [
    BuiltinItem('driedFont', 'Font and surrounding area dried and tidied'),
    BuiltinItem('oilsStored', 'Holy oils safely stored'),
  ]),
  const BuiltinTemplate('Benediction / Adoration — Before', MassType.benediction, 'pre', [
    BuiltinItem('monstrance', 'Monstrance cleaned and ready', 'Ostensorium'),
    BuiltinItem('luna', 'Luna/lunette in place', 'Luna'),
    BuiltinItem('humeralVeil', 'Humeral veil ready', 'Velum Humerale'),
    _thuribleItem,
    BuiltinItem('kneelerCushion', 'Kneeler/cushion set out for the celebrant'),
  ]),
  const BuiltinTemplate('Benediction / Adoration — After', MassType.benediction, 'post', [
    BuiltinItem('reposeBlessedSacrament', 'Blessed Sacrament reposed in the tabernacle'),
    BuiltinItem('extinguishCandlesAdoration', 'Candles extinguished'),
    BuiltinItem('monstranceStored', 'Monstrance cleaned and stored'),
  ]),
  const BuiltinTemplate('Holy Week — Palm Sunday', MassType.holyWeek, 'pre', [
    BuiltinItem('palms', 'Palm branches obtained and distributed at the entrance'),
    BuiltinItem('redVestments', 'Red vestments laid out'),
    BuiltinItem('passionGospel', 'Passion narrative marked / assigned readers'),
  ]),
  const BuiltinTemplate('Holy Week — Holy Thursday', MassType.holyWeek, 'pre', [
    BuiltinItem('chrismOilsReceived', 'Holy oils from the Chrism Mass received and stored'),
    BuiltinItem('mandatumBasin', 'Basin, pitcher, and towels ready for the Mandatum (washing of feet)'),
    BuiltinItem('altarOfReposition', 'Altar of repose prepared'),
    BuiltinItem('extraHostsTriduum', 'Sufficient hosts consecrated for Good Friday'),
    BuiltinItem('stripAltarAfter', 'Plan to strip the main altar after the liturgy'),
  ]),
  const BuiltinTemplate('Holy Week — Good Friday', MassType.holyWeek, 'pre', [
    BuiltinItem('bareAltar', 'Main altar left completely bare (no cloth, candles, or cross)'),
    BuiltinItem('crossForVeneration', 'Cross prepared for veneration'),
    BuiltinItem('reservedHostsGoodFriday', 'Reserved hosts from Holy Thursday ready for Communion'),
    BuiltinItem('redVestmentsGoodFriday', 'Red vestments laid out'),
  ]),
  const BuiltinTemplate('Holy Week — Easter Vigil', MassType.holyWeek, 'pre', [
    BuiltinItem('newFire', 'New fire materials ready (fire pit/brazier, fuel)'),
    BuiltinItem('paschalCandle', 'New paschal candle prepared (with grains of incense)'),
    BuiltinItem('baptismalItemsVigil', 'Baptismal/confirmation items ready for the Elect and Candidates'),
    BuiltinItem('individualCandles', 'Small candles for the congregation'),
    BuiltinItem('whiteGoldVestmentsVigil', 'White/gold vestments laid out'),
    BuiltinItem('bellsRestored', 'Bells and Gloria ready to be restored at the Vigil'),
  ]),
];
