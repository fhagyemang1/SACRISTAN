import '../../data/repositories.dart';

/// Seed content for the offline Reference Library.
///
/// COPYRIGHT NOTE: entries here are original summaries/paraphrases written
/// for this app, not verbatim excerpts of the General Instruction of the
/// Roman Missal (GIRM), the Roman Missal, or the Lectionary — none of
/// which this app redistributes in full. Each entry cites its source so a
/// sacristan can look up the authoritative text. See also
/// docs/STORE_CHECKLIST.md and the in-app About screen for the full
/// attribution list.
class ReferenceEntrySeed {
  final String category; // 'glossary' | 'girm' | 'rubric'
  final String title;
  final String latin;
  final String body;
  final String sourceCitation;
  final String illustrationAsset; // filename under assets/reference/

  const ReferenceEntrySeed({
    required this.category,
    required this.title,
    this.latin = '',
    required this.body,
    required this.sourceCitation,
    this.illustrationAsset = '',
  });
}

const glossaryEntries = <ReferenceEntrySeed>[
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Chasuble',
    latin: 'Casula',
    body: 'The outer vestment worn by the priest over the alb and stole for '
        'Mass. Its color matches the liturgical day. A "Roman" or "Gothic" '
        'cut is common; some are worn with a matching stole visible '
        'underneath.',
    sourceCitation: 'GIRM, no. 337 (paraphrase)',
    illustrationAsset: 'chasuble.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Stole',
    latin: 'Stola',
    body: 'A long narrow band worn around the neck — by a priest hanging '
        'down both sides, by a deacon across the left shoulder. Signifies '
        'the wearer\'s ordained ministry; color follows the day.',
    sourceCitation: 'GIRM, no. 336 (paraphrase)',
    illustrationAsset: 'stole.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Alb',
    latin: 'Alba',
    body: 'The long white garment worn under the chasuble (or dalmatic/'
        'cope), symbolizing the purity that should mark a Christian life. '
        'Usually secured with a cincture at the waist.',
    sourceCitation: 'GIRM, no. 336 (paraphrase)',
    illustrationAsset: 'alb.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Cincture',
    latin: 'Cingulum',
    body: 'A cord tied around the waist over the alb. Traditionally the '
        'color of the day, though white is always acceptable.',
    sourceCitation: 'Common sacristy usage',
    illustrationAsset: 'cincture.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Amice',
    latin: 'Amictus',
    body: 'An optional rectangular white cloth tied around the neck and '
        'shoulders before the alb, covering ordinary clothing at the '
        'collar.',
    sourceCitation: 'GIRM, no. 336 (paraphrase)',
    illustrationAsset: 'amice.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Cope',
    latin: 'Pluviale',
    body: 'A long, cape-like vestment open at the front, fastened at the '
        'chest, worn for processions, Benediction, and other rites outside '
        'of Mass itself.',
    sourceCitation: 'Common sacristy usage',
    illustrationAsset: 'cope.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Humeral Veil',
    latin: 'Velum Humerale',
    body: 'A long, scarf-like cloth worn over the shoulders and used to '
        'cover the hands when carrying the monstrance in a Eucharistic '
        'procession or at Benediction.',
    sourceCitation: 'Common sacristy usage',
    illustrationAsset: 'humeral_veil.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Chalice',
    latin: 'Calix',
    body: 'The cup used to hold the wine that becomes the Blood of Christ. '
        'Typically has a gold or gold-lined interior bowl.',
    sourceCitation: 'GIRM, no. 327-328 (paraphrase)',
    illustrationAsset: 'chalice.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Paten',
    latin: 'Patena',
    body: 'The shallow plate that holds the large host during Mass, '
        'usually resting on or near the chalice.',
    sourceCitation: 'GIRM, no. 327-328 (paraphrase)',
    illustrationAsset: 'paten.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Ciborium',
    latin: 'Ciborium',
    body: 'A covered vessel, shaped like a large lidded cup, used to hold '
        'consecrated hosts for distribution and for reservation in the '
        'tabernacle.',
    sourceCitation: 'GIRM, no. 327-328 (paraphrase)',
    illustrationAsset: 'ciborium.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Purificator',
    latin: 'Purificatorium',
    body: 'A small white linen cloth used to wipe the chalice (and the '
        'priest\'s and communicants\' fingers/lips) during and after '
        'Communion.',
    sourceCitation: 'GIRM, no. 118, 279 (paraphrase)',
    illustrationAsset: 'purificator.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Corporal',
    latin: 'Corporale',
    body: 'A square white linen cloth spread on the altar; the chalice and '
        'paten rest on it during the Eucharistic Prayer, catching any '
        'fragments or drops.',
    sourceCitation: 'GIRM, no. 118, 306 (paraphrase)',
    illustrationAsset: 'corporal.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Pall',
    latin: 'Palla',
    body: 'A small stiffened square, often linen over cardboard, used to '
        'cover the chalice to keep dust or insects out.',
    sourceCitation: 'GIRM, no. 118 (paraphrase)',
    illustrationAsset: 'pall.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Thurible',
    latin: 'Thuribulum',
    body: 'The metal censer, hung on chains, in which incense is burned on '
        'lit charcoal and swung to incense the altar, the Book of the '
        'Gospels, the offerings, and the people.',
    sourceCitation: 'GIRM, no. 276-277 (paraphrase)',
    illustrationAsset: 'thurible.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Cruets',
    latin: 'Ampullae',
    body: 'Small vessels — usually glass or metal, one for water and one '
        'for wine — used to bring these to the altar at the Preparation of '
        'the Gifts.',
    sourceCitation: 'Common sacristy usage',
    illustrationAsset: 'cruets.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Paschal Candle',
    latin: 'Cereus Paschalis',
    body: 'The large candle blessed and lit from the new fire at the '
        'Easter Vigil, marked with a cross and the current year, and '
        'burned at every Mass through the Easter season, at baptisms, and '
        'at funerals throughout the year.',
    sourceCitation: 'Roman Missal, Easter Vigil (paraphrase)',
    illustrationAsset: 'paschal_candle.svg',
  ),
  ReferenceEntrySeed(
    category: 'glossary',
    title: 'Monstrance',
    latin: 'Ostensorium',
    body: 'The often ornate vessel used to display a consecrated host — '
        'held in a small glass-fronted holder called a luna/lunette — for '
        'Eucharistic adoration and Benediction.',
    sourceCitation: 'Common sacristy usage',
    illustrationAsset: 'monstrance.svg',
  ),
];

const girmEntries = <ReferenceEntrySeed>[
  ReferenceEntrySeed(
    category: 'girm',
    title: 'What the sacristan prepares before Mass',
    body: 'The GIRM directs that the sacred vessels, vestments, and other '
        'items needed for the celebration be prepared and arranged in the '
        'sacristy before Mass begins — vestments in the color of the day, '
        'the chalice with purificator/pall/corporal, the Missal, and '
        'anything else the specific rite requires.',
    sourceCitation: 'GIRM, nos. 117-119 (paraphrase — see the full GIRM at '
        'usccb.org for authoritative text)',
  ),
  ReferenceEntrySeed(
    category: 'girm',
    title: 'Liturgical colors',
    body: 'Violet for Advent and Lent; white/gold for Christmas, Easter, '
        'feasts of the Lord (other than the Passion), Mary, angels, and '
        'saints who were not martyrs; red for Palm Sunday, Good Friday, '
        'Pentecost, and feasts of martyrs and Apostles; green for Ordinary '
        'Time; rose is permitted on Gaudete and Laetare Sundays; black is '
        'permitted for funerals/All Souls where local custom allows it.',
    sourceCitation: 'GIRM, nos. 345-347 (paraphrase — see the full GIRM at '
        'usccb.org for authoritative text)',
  ),
  ReferenceEntrySeed(
    category: 'girm',
    title: 'Care of sacred vessels after Communion',
    body: 'After Communion, the priest or deacon (or, under the '
        'conditions envisioned by law, an instituted acolyte or other '
        'extraordinary minister) purifies the vessels, usually at a side '
        'table, and any consecrated hosts are reserved in the tabernacle.',
    sourceCitation: 'GIRM, nos. 163, 279 (paraphrase — see the full GIRM at '
        'usccb.org for authoritative text)',
  ),
];

const rubricEntries = <ReferenceEntrySeed>[
  ReferenceEntrySeed(
    category: 'rubric',
    title: 'Linen care: the first rinse',
    body: 'Traditional practice calls for purificators and corporals to be '
        'rinsed by hand, separately from other laundry, before regular '
        'washing. Out of reverence for any remaining fragments or drops of '
        'the Eucharist, the water from this first rinse is customarily '
        'poured into a sacrarium — a special sink that drains directly '
        'into the earth rather than the ordinary sewer system — or '
        'directly onto the ground outdoors, never into a normal drain. '
        'This is offered as reference guidance for the sacristan to follow '
        'according to their pastor\'s and diocese\'s instruction; the app '
        'does not enforce or verify that it was done.',
    sourceCitation:
        'Common sacristan formation guidance; see e.g. EWTN, "A Sacristan\'s '
        'Duties"',
  ),
  ReferenceEntrySeed(
    category: 'rubric',
    title: 'Retiring worn sacred linens and vestments',
    body: 'Linens and vestments that are no longer fit for use are '
        'traditionally not simply discarded with ordinary trash, out of '
        'reverence for their sacred use — many parishes reverently burn '
        'them or otherwise dispose of them according to diocesan '
        'guidance. Confirm your parish\'s practice with your pastor.',
    sourceCitation: 'Common sacristan formation guidance',
  ),
  ReferenceEntrySeed(
    category: 'rubric',
    title: 'The sanctuary lamp',
    body: 'A lamp near the tabernacle is traditionally kept continuously '
        'lit whenever the Blessed Sacrament is reserved there, as a sign '
        'of Christ\'s presence. Checking its fuel or bulb is an easy task '
        'to overlook precisely because it is meant to just quietly keep '
        'burning.',
    sourceCitation: 'Common sacristan formation guidance; canon 940',
  ),
];

const allSeedEntries = [...glossaryEntries, ...girmEntries, ...rubricEntries];

/// Populates the ReferenceEntries table from the seed lists above, once,
/// on first launch — after that a parish is free to edit/delete any entry
/// (bundled or their own) via the Reference screen's admin-gated editor.
/// No network call; this only reads the const lists in this same file.
///
/// Idempotency check: looks only at the 'glossary' category, since all
/// three categories are always seeded together in this one pass. If a
/// parish deletes every glossary entry but keeps GIRM/rubric ones, this
/// will re-seed glossary entries alongside — an acceptable edge case for
/// a local, single-device tool with no accidental-reseed downside beyond
/// possible duplicates the parish can just delete again.
Future<void> seedReferenceEntriesIfNeeded(ReferenceRepository repo) async {
  final existingGlossary = await repo.watchByCategory('glossary').first;
  if (existingGlossary.isNotEmpty) return;
  for (final e in allSeedEntries) {
    await repo.add(
      category: e.category,
      title: e.title,
      latinName: e.latin.isEmpty ? null : e.latin,
      bodyMarkdown: e.body,
      sourceCitation: e.sourceCitation,
      illustrationAsset: e.illustrationAsset.isEmpty ? null : e.illustrationAsset,
      isBuiltin: true,
    );
  }
}
