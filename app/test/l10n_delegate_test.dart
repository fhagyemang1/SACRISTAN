import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/l10n/app_localizations.dart';

/// Regression test for a round-8 bug: `AppLocalizations.delegate` was
/// missing from `MaterialApp.localizationsDelegates` in main.dart, so
/// every `AppLocalizations.of(context)!` call added across the app in
/// round 5 (nav bar labels, the liturgical color/rank/season vocabulary,
/// several screen titles and buttons) returned null and crashed the app
/// on launch — in every locale, every time. `flutter analyze` cannot
/// catch this class of bug: it's a runtime widget-registration issue, not
/// a type error. This test pumps a `MaterialApp` with the exact
/// `localizationsDelegates` list main.dart uses and asserts
/// `AppLocalizations.of(context)` actually resolves, so this specific
/// mistake can never silently regress again.
void main() {
  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  testWidgets(
      'AppLocalizations.of(context) resolves under the English locale',
      (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: delegates,
      home: Builder(builder: (context) {
        capturedContext = context;
        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle();

    final t = AppLocalizations.of(capturedContext);
    expect(t, isNotNull,
        reason: 'AppLocalizations.of(context) returned null — '
            'AppLocalizations.delegate is missing from '
            'localizationsDelegates somewhere (see main.dart).');
    expect(t!.navToday, 'Today');
    expect(t.navCalendar, 'Calendar');
    expect(t.colorViolet, 'Violet');
    expect(t.rankSolemnity, 'Solemnity');
  });

  testWidgets('French locale resolves distinct, real translations',
      (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: delegates,
      home: Builder(builder: (context) {
        capturedContext = context;
        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle();

    final t = AppLocalizations.of(capturedContext)!;
    expect(t.navToday, "Aujourd'hui");
    expect(t.navCalendar, 'Calendrier');
  });

  testWidgets('Spanish locale resolves distinct, real translations',
      (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: delegates,
      home: Builder(builder: (context) {
        capturedContext = context;
        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle();

    final t = AppLocalizations.of(capturedContext)!;
    expect(t.navToday, 'Hoy');
    expect(t.navCalendar, 'Calendario');
  });
}
