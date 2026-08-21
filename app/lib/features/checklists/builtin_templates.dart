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

final List<BuiltinTemplate> builtinTemplates = [
  BuiltinTemplate('Sunday Mass — Before Mass', MassType.sunday, 'pre',
      [..._preMassCore, _thuribleItem]),
  BuiltinTemplate('Sunday Mass — After Mass', MassType.sunday, 'post', _postMassCore),
  BuiltinTemplate('Weekday Mass — Before Mass', MassType.weekday, 'pre', _preMassCore),
  BuiltinTemplate('Weekday Mass — After Mass', MassType.weekday, 'post', _postMassCore),
  BuiltinTemplate('Funeral Mass — Before Mass', MassType.funeral, 'pre', [
    ..._preMassCore,
    const BuiltinItem('paschalCandleFuneral', 'Paschal candle placed by the casket'),
    const BuiltinItem('pallFuneral', 'Funeral pall available for the casket'),
    const BuiltinItem('holyWaterFuneral', 'Holy water and sprinkler ready'),
    const BuiltinItem('coordFuneralDirector', 'Coordinate timing with the funeral director'),
  ]),
  BuiltinTemplate('Funeral Mass — After Mass', MassType.funeral, 'post', _postMassCore),
  BuiltinTemplate('Wedding — Before Mass', MassType.wedding, 'pre', [
    ..._preMassCore,
    const BuiltinItem('unityCandle', 'Unity candle / other requested items placed, per pastor\'s policy'),
    const BuiltinItem('kneelers', 'Kneelers set out for the couple'),
    const BuiltinItem('ringsReminder', 'Confirm best man/maid of honor know where to bring the rings'),
  ]),
  BuiltinTemplate('Wedding — After Mass', MassType.wedding, 'post', _postMassCore),
  BuiltinTemplate('Baptism — Before', MassType.baptism, 'pre', [
    const BuiltinItem('baptismalWater', 'Baptismal water ready in the font'),
    const BuiltinItem('oilOfCatechumens', 'Oil of Catechumens available'),
    const BuiltinItem('sacredChrism', 'Sacred Chrism available'),
    const BuiltinItem('whiteGarment', 'White garment ready'),
    const BuiltinItem('baptismalCandle', 'Baptismal candle ready (lit from the paschal candle)'),
    const BuiltinItem('towels', 'Towels for the child/candidate'),
  ]),
  BuiltinTemplate('Baptism — After', MassType.baptism, 'post', [
    const BuiltinItem('driedFont', 'Font and surrounding area dried and tidied'),
    const BuiltinItem('oilsStored', 'Holy oils safely stored'),
  ]),
  BuiltinTemplate('Benediction / Adoration — Before', MassType.benediction, 'pre', [
    const BuiltinItem('monstrance', 'Monstrance cleaned and ready', 'Ostensorium'),
    const BuiltinItem('luna', 'Luna/lunette in place', 'Luna'),
    const BuiltinItem('humeralVeil', 'Humeral veil ready', 'Velum Humerale'),
    _thuribleItem,
    const BuiltinItem('kneelerCushion', 'Kneeler/cushion set out for the celebrant'),
  ]),
  BuiltinTemplate('Benediction / Adoration — After', MassType.benediction, 'post', [
    const BuiltinItem('reposeBlessedSacrament', 'Blessed Sacrament reposed in the tabernacle'),
    const BuiltinItem('extinguishCandlesAdoration', 'Candles extinguished'),
    const BuiltinItem('monstranceStored', 'Monstrance cleaned and stored'),
  ]),
  BuiltinTemplate('Holy Week — Palm Sunday', MassType.holyWeek, 'pre', [
    const BuiltinItem('palms', 'Palm branches obtained and distributed at the entrance'),
    const BuiltinItem('redVestments', 'Red vestments laid out'),
    const BuiltinItem('passionGospel', 'Passion narrative marked / assigned readers'),
  ]),
  BuiltinTemplate('Holy Week — Holy Thursday', MassType.holyWeek, 'pre', [
    const BuiltinItem('chrismOilsReceived', 'Holy oils from the Chrism Mass received and stored'),
    const BuiltinItem('mandatumBasin', 'Basin, pitcher, and towels ready for the Mandatum (washing of feet)'),
    const BuiltinItem('altarOfReposition', 'Altar of repose prepared'),
    const BuiltinItem('extraHostsTriduum', 'Sufficient hosts consecrated for Good Friday'),
    const BuiltinItem('stripAltarAfter', 'Plan to strip the main altar after the liturgy'),
  ]),
  BuiltinTemplate('Holy Week — Good Friday', MassType.holyWeek, 'pre', [
    const BuiltinItem('bareAltar', 'Main altar left completely bare (no cloth, candles, or cross)'),
    const BuiltinItem('crossForVeneration', 'Cross prepared for veneration'),
    const BuiltinItem('reservedHostsGoodFriday', 'Reserved hosts from Holy Thursday ready for Communion'),
    const BuiltinItem('redVestmentsGoodFriday', 'Red vestments laid out'),
  ]),
  BuiltinTemplate('Holy Week — Easter Vigil', MassType.holyWeek, 'pre', [
    const BuiltinItem('newFire', 'New fire materials ready (fire pit/brazier, fuel)'),
    const BuiltinItem('paschalCandle', 'New paschal candle prepared (with grains of incense)'),
    const BuiltinItem('baptismalItemsVigil', 'Baptismal/confirmation items ready for the Elect and Candidates'),
    const BuiltinItem('individualCandles', 'Small candles for the congregation'),
    const BuiltinItem('whiteGoldVestmentsVigil', 'White/gold vestments laid out'),
    const BuiltinItem('bellsRestored', 'Bells and Gloria ready to be restored at the Vigil'),
  ]),
];
