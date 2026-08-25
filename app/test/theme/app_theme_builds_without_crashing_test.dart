import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/theme/app_theme.dart';

/// Regression test for a round-12 bug that reached a real device before it
/// was ever caught here: `AppTheme.light()`/`.dark()` used to build their
/// `textTheme` as
///   Typography.material2021(platform: TargetPlatform.android)
///       .black
///       .apply(fontSizeFactor: 1.05)
/// which crashed the whole app on first launch — a "red screen of death"
/// at startup, before a single screen rendered — with
/// "'fontSize != null || (fontSizeFactor == 1.0 && fontSizeDelta == 0.0)':
/// is not true." `Typography.material2021(...).black` is deliberately
/// *color-only* (every TextStyle field sets color but leaves `fontSize`
/// null; geometry is meant to be merged in separately), so scaling it
/// directly with a non-1.0 `fontSizeFactor` was guaranteed to fail.
///
/// No prior test in this repo ever exercised `AppTheme.light()`/`.dark()`
/// against a real widget tree — `app_theme_contrast_test.dart` only checks
/// `swatchFor()`'s colors — so this crash shipped straight past every CI
/// run. This test closes that gap the direct way: build a real
/// `MaterialApp` with each theme and confirm nothing throws while
/// rendering ordinary text, which is exactly the scenario that failed on
/// device.
void main() {
  for (final entry in {'light': AppTheme.light(), 'dark': AppTheme.dark()}
      .entries) {
    testWidgets(
        '${entry.key} theme renders text without throwing (round 12 regression)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: entry.value,
        home: const Scaffold(
          body: Center(child: Text('SACRISTAN')),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'AppTheme.${entry.key}() must not throw when a real '
              'widget tree renders text under it — this is exactly the '
              'crash the pre-fix .apply(fontSizeFactor: 1.05) call on a '
              'color-only TextTheme produced on every real device.');

      // The bug specifically zeroed out `fontSize` on every text style;
      // assert directly that it survived the merge, not just that nothing
      // threw (a future regression that silently drops the geometry merge
      // again — without also calling .apply() — would render fine but
      // undo the round-6 "large touch targets / high-contrast text"
      // accessibility intent this theme exists for).
      final textTheme = entry.value.textTheme;
      for (final style in [
        textTheme.displayLarge,
        textTheme.headlineMedium,
        textTheme.titleLarge,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.labelSmall,
      ]) {
        expect(style?.fontSize, isNotNull,
            reason: 'every core text style must carry a real fontSize');
      }
    });
  }
}
