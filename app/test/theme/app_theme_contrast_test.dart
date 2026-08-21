import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart';
import 'package:sacristan/theme/app_theme.dart';

/// Permanent regression test for the round-7 accessibility check, which
/// was originally verified once, externally, with a hand-written Python
/// script (see docs/ARCHITECTURE.md §4, round 7) rather than anything
/// that runs as part of this repo's own test suite. Porting it into a
/// real `flutter test` means every future change to `swatchFor()` gets
/// checked automatically, instead of relying on someone remembering a
/// script that lives outside the repo and was never wired into CI.
///
/// WCAG 2.x relative luminance / contrast ratio formula, taken directly
/// from the spec: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double _linearize(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color c) {
  final r = _linearize(c.r);
  final g = _linearize(c.g);
  final b = _linearize(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('swatchFor() contrast (WCAG AA — 4.5:1 minimum for normal text)', () {
    for (final color in LiturgicalColor.values) {
      for (final dark in [false, true]) {
        test('${color.name} (dark=$dark) background/foreground clears 4.5:1',
            () {
          final swatch = swatchFor(color, dark: dark);
          final ratio = _contrastRatio(swatch.background, swatch.foreground);
          expect(ratio, greaterThanOrEqualTo(4.5),
              reason: '${color.name} (dark=$dark): contrast is only '
                  '${ratio.toStringAsFixed(2)}:1, below the 4.5:1 WCAG AA '
                  'minimum for normal text.');
        });
      }
    }
  });
}
