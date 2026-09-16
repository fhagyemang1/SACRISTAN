import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/data/database.dart';
import 'package:sacristan/features/dashboard/dashboard_screen.dart';
import 'package:sacristan/main.dart';

/// Round-13 fix: this file was still Flutter's stock `flutter create`
/// counter-app template — it pumped a `MyApp` widget that has never
/// existed in this project (the real root widget is [SacristanApp], which
/// also isn't a no-arg constructor: it requires a [SacristanDatabase] and
/// an initial [Locale]). `flutter analyze` never caught this because
/// nothing in this project's own code referenced the stale file; it only
/// surfaced the first time `flutter analyze`/`flutter test` were actually
/// run against this project on a real toolchain (see docs/ARCHITECTURE.md
/// round 13 — the same "written/left blind, never verified" shape every
/// prior round's real-toolchain run has found something new to fix).
///
/// Replaced with an actual smoke test: pump the real [SacristanApp] against
/// a fresh in-memory database (same `SacristanDatabase.forTesting` pattern
/// used throughout `test/data/`) and confirm the app shell renders without
/// throwing, with its bottom navigation in place.
void main() {
  testWidgets('SacristanApp renders the app shell without crashing',
      (tester) async {
    final db = SacristanDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => db.close());

    // Round-13 follow-up: DashboardScreen (always mounted — it's one of
    // AppShell's IndexedStack tabs) schedules a self-rescheduling Timer for
    // the next local midnight. flutter_test runs on a virtual clock, so
    // that Timer — due many hours out — just sits pending for the rest of
    // the test process; a first attempt at fixing this by forcing early
    // disposal (swap in SizedBox.shrink(), pump, rely on dispose() to
    // cancel it before flutter_test's own end-of-test pending-timer check)
    // did not reliably avoid the "Timer is still pending" failure on
    // rerun. Disabling the schedule at the source is the robust fix: no
    // Timer is ever created, so there's nothing for that check to trip on
    // regardless of disposal timing.
    debugDisableMidnightRefresh = true;
    addTearDown(() => debugDisableMidnightRefresh = false);

    await tester.pumpWidget(SacristanApp(
      db: db,
      initialLocale: const Locale('en'),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'the app shell must build and render cleanly against a '
            'fresh, empty database — no templates, reminders, inventory, '
            'or reference entries seeded');

    // The app bar title and the Today tab's label both come from the
    // English ARB strings (app_en.arb) rather than being hardcoded here,
    // so this also catches AppLocalizations wiring breaking again (see
    // main.dart's round-8 doc comment on exactly that prior crash).
    expect(find.text('SACRISTAN'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Round-13, second follow-up: the actual source of "Timer is still
    // pending" was never DashboardScreen's midnight Timer (disabled above
    // via debugDisableMidnightRefresh, which is still worth keeping, but
    // turned out not to be the cause of this specific failure). The real
    // source is `drift` itself: the Checklists, Inventory, and Reference
    // tabs (also always mounted — they're the other IndexedStack children
    // in AppShell) each use a StreamBuilder to watch a query. When a
    // StreamBuilder's subscription is cancelled, drift's
    // StreamQueryStore.markAsClosed (package:drift/src/runtime/executor/
    // stream_queries.dart) schedules its own internal Duration.zero Timer
    // to finish tearing the query stream down. That teardown never
    // happens naturally inside this test body, because nothing here ever
    // unmounts the widget tree — flutter_test does that *for* us,
    // automatically, right at the very end of the test — and its own
    // "!timersPending" check runs immediately after, before drift's
    // Duration.zero Timer gets a chance to fire. So the fix is to force
    // disposal ourselves, inside this test's own body, where we control
    // the fake clock: swap in an empty widget (unmounting every
    // StreamBuilder, which schedules drift's cleanup Timers), then
    // `pumpAndSettle` — unlike a single `pump()`, each of its internal
    // pump cycles elapses real (fake-clock) time, which is what actually
    // fires a Duration.zero Timer, including ones newly created by an
    // earlier cycle's own teardown work.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
