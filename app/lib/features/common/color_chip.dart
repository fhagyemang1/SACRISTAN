import 'package:flutter/material.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// A big, unmissable chip showing a liturgical color by name and swatch.
/// Never relies on color alone (WCAG) — always paired with the text label.
class LiturgicalColorChip extends StatelessWidget {
  final LiturgicalColor color;
  final bool goldPermitted;
  final double fontSize;

  const LiturgicalColorChip({
    super.key,
    required this.color,
    this.goldPermitted = false,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final swatch = swatchFor(color, dark: isDark);
    // Round 13+ fix: "(gold permitted)" used to be a raw English string
    // literal concatenated on regardless of the selected app language —
    // every other piece of text in this widget goes through
    // AppLocalizations via _label() below. Now uses the same mechanism.
    final label = goldPermitted
        ? '${_label(context, color)} ${AppLocalizations.of(context)!.colorGoldPermittedSuffix}'
        : _label(context, color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: swatch.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Colors.black.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: fontSize * 0.7, color: swatch.foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: swatch.foreground,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context, LiturgicalColor c) {
    final t = AppLocalizations.of(context)!;
    switch (c) {
      case LiturgicalColor.violet:
        return t.colorViolet;
      case LiturgicalColor.white:
        return t.colorWhite;
      case LiturgicalColor.red:
        return t.colorRed;
      case LiturgicalColor.green:
        return t.colorGreen;
      case LiturgicalColor.rose:
        return t.colorRose;
      case LiturgicalColor.gold:
        return t.colorGold;
      case LiturgicalColor.black:
        return t.colorBlack;
    }
  }
}

/// Localized rank name for [rank] — pass the calling widget's `context` so
/// this reflects whatever language is currently selected (Settings >
/// Language), not just the device's system language.
String rankLabel(BuildContext context, CelebrationRank rank) {
  final t = AppLocalizations.of(context)!;
  switch (rank) {
    case CelebrationRank.triduum:
      return t.rankTriduum;
    case CelebrationRank.solemnity:
      return t.rankSolemnity;
    case CelebrationRank.feast:
      return t.rankFeast;
    case CelebrationRank.sunday:
      return t.rankSunday;
    case CelebrationRank.memorial:
      return t.rankMemorial;
    case CelebrationRank.optionalMemorial:
      return t.rankOptionalMemorial;
    case CelebrationRank.ferial:
      return t.rankFerial;
  }
}

/// Localized season name for [season] — see [rankLabel] on why this takes
/// `context` rather than being a plain data-to-string lookup.
String seasonLabel(BuildContext context, LiturgicalSeason season) {
  final t = AppLocalizations.of(context)!;
  switch (season) {
    case LiturgicalSeason.advent:
      return t.seasonAdvent;
    case LiturgicalSeason.christmas:
      return t.seasonChristmas;
    case LiturgicalSeason.ordinaryTime:
      return t.seasonOrdinaryTime;
    case LiturgicalSeason.lent:
      return t.seasonLent;
    case LiturgicalSeason.triduum:
      return t.seasonTriduum;
    case LiturgicalSeason.easter:
      return t.seasonEaster;
  }
}
