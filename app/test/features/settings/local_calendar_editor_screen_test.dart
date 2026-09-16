import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sacristan/data/admin_session.dart';
import 'package:sacristan/data/database.dart';
import 'package:sacristan/data/repositories.dart';
import 'package:sacristan/features/settings/local_calendar_editor_screen.dart';
import 'package:sacristan/l10n/app_localizations.dart';

/// Regression test for a round-11 bug: the "Add local calendar entry"
/// dialog's Day dropdown always offered 1-31 regardless of the selected
/// Month, and nothing anywhere (this screen, `CalendarRepository
/// .addLocalEntry`, or the database) validated the combination. That let
/// an admin save a nonexistent date — "February 31," say — which the
/// calendar engine's `entry.month == date.month && entry.day == date.day`
/// matching would then simply never satisfy on any real date, ever:
/// the entry would silently vanish from the app the moment it was saved,
/// directly contradicting this screen's own promise that an added entry
/// "will show up on the Dashboard and Calendar automatically, every
/// year." Fixed by filtering the Day dropdown's options to the selected
/// Month's real length and clamping the selected day down when a month
/// change makes it invalid (e.g. day 31 selected under January, then
/// switching to February) — this test exercises exactly that sequence
/// and confirms the day that's actually saved is a real one.
void main() {
  testWidgets(
      'switching from a 31-day month to February clamps an already-selected '
      'day 31 down to 29, and that is what gets saved', (tester) async {
    final db = SacristanDatabase.forTesting(NativeDatabase.memory());
    final repo = CalendarRepository(db);
    addTearDown(db.close);

    // Round 14 fix: this screen's add/delete actions are now admin-PIN
    // gated (see the class doc comment on LocalCalendarEditorScreen) —
    // `_showAddDialog` calls `context.read<AdminSession>()` before it ever
    // shows the dialog. This test previously provided no `AdminSession` in
    // its widget tree at all, so that `read` threw a
    // `ProviderNotFoundException` inside the FAB's `onPressed` the moment
    // the gating fix landed — the dialog never opened, and every dropdown
    // lookup below found nothing. A real app user never hits this: `main
    // .dart` always wires a real `AdminSession` via `ChangeNotifierProvider`
    // at the app root. Fixed here by providing one directly, pre-unlocked
    // (`..unlock()`) — this test's whole point is exercising the Add
    // dialog's Month/Day interaction, not the PIN gate itself, so it needs
    // to already be in the "admin unlocked" state to reach that flow.
    final adminSession = AdminSession()..unlock();

    // Round 14, second follow-up: even after the AdminSession fix above got
    // the dialog itself opening again, the very next real run still failed
    // — this time inside `ensureVisible(find.text('31').last)` with `Bad
    // state: No element`. `WidgetController.ensureVisible` (flutter_test's
    // own source) calls `element(finder)` — i.e. `finder.evaluate().single`
    // — *before* it scrolls anything, so that crash means '31' was not in
    // the widget tree at all at that point, not merely off-screen. Root
    // cause: flutter_test's default surface is a fixed 800x600 logical
    // pixels, and this dialog's `AlertDialog` + `SingleChildScrollView`
    // content (two text fields plus four dropdowns) is taller than that —
    // so the still-closed Day dropdown field itself was laid out below the
    // visible/hit-testable window bounds when `tester.tap(intDropdowns.at
    // (1))` computed its center coordinate, and the tap landed on nothing:
    // the menu never opened, and neither the closed-state nor open-menu
    // copy of '31' was ever reachable. `ensureVisible` cannot fix a tap
    // that's already missed its target — it can only scroll something that
    // was already found. Fixed at the root by giving the test a large
    // enough virtual screen that the whole dialog fits without needing to
    // scroll at all, the standard flutter_test pattern for a dialog taller
    // than the default surface (see WidgetTester.view.physicalSize in the
    // Flutter SDK's own test-utilities docs) — the `ensureVisible` calls
    // below are kept as cheap, harmless defense-in-depth (a no-op once
    // nothing needs scrolling) rather than removed.
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Round 14+, fourth follow-up: this screen's "Add entry" FAB label
    // (and other strings across the app) now reads from
    // `AppLocalizations.of(context)!` instead of a hardcoded literal, as
    // part of this round's localization pass — but a bare `MaterialApp`
    // like the one below has no `localizationsDelegates`/
    // `supportedLocales` configured, unlike the real app's root widget
    // (`SacristanApp` in main.dart, which registers all four delegates —
    // see that file's own round-8 doc comment on why they matter).
    // Without them, `AppLocalizations.of(context)` returns null and the
    // `!` throws — but only inside the one small widget that calls it
    // (`Text(loc.localCalendarAddEntry)`), which Flutter's debug-mode
    // per-widget error boundary replaces with a red error box rather
    // than crashing the whole tree. The rest of the screen still
    // rendered, which is why this surfaced as `find.text('Add entry')`
    // finding zero widgets rather than as a build-time crash. Fixed by
    // registering the same delegates `SacristanApp` always does.
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
      home: MultiProvider(
        providers: [
          Provider<CalendarRepository>.value(value: repo),
          ChangeNotifierProvider<AdminSession>.value(value: adminSession),
        ],
        child: const LocalCalendarEditorScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // Open the "Add entry" dialog.
    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();

    // The Month and Day dropdowns are the only two
    // `DropdownButtonFormField<int>`s in this dialog, in that order.
    final intDropdowns = find.byType(DropdownButtonFormField<int>);
    expect(intDropdowns, findsNWidgets(2));

    // Open the Day dropdown (still January, so 1-31 are all offered) and
    // pick day 31.
    //
    // Round-13, third follow-up: this test (like local_calendar_editor_
    // screen_test.dart's own doc comment says, a round-11 file) had
    // apparently never actually run against a real Flutter toolchain
    // until this session — the first real run threw `Bad state: No
    // element` right here, because `find.text('31')` found nothing at
    // all. The AlertDialog's content is a `SingleChildScrollView`
    // holding two TextFields plus four dropdowns, taller than the
    // default `flutter test` surface — so the Day dropdown field itself
    // was scrolled out of the dialog's visible viewport when `tester.tap`
    // computed its center point, and (per Flutter's own hit-testing,
    // which doesn't complain, just misses) the tap landed on nothing,
    // the menu never opened, and "31" — which only exists once the menu
    // is actually open — was never in the tree to find. `ensureVisible`
    // scrolls the nearest ancestor `Scrollable` (here, the dialog's own
    // SingleChildScrollView, and separately the open dropdown menu's own
    // internal scrollable once it exists) so the tap target is actually
    // on-screen before each tap.
    await tester.ensureVisible(intDropdowns.at(1));
    await tester.tap(intDropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('31').last);
    await tester.tap(find.text('31').last);
    await tester.pumpAndSettle();
    // `findsWidgets` (>=1) rather than `findsOneWidget`: DropdownButton's
    // internals sometimes keep more than one copy of the selected item's
    // text in the tree for layout purposes even while closed, and getting
    // that exact count right isn't the point here — the point is that 31
    // is genuinely selected, which the day: 29 assertion at the very end
    // (the real regression proof) confirms unambiguously either way.
    expect(find.text('31'), findsWidgets,
        reason: 'day 31 should now be the Day dropdown\'s displayed value');

    // Now switch the Month dropdown to February.
    await tester.ensureVisible(intDropdowns.at(0));
    await tester.tap(intDropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('February').last);
    await tester.tap(find.text('February').last);
    await tester.pumpAndSettle();

    // The Day dropdown must no longer be showing (or offering) day 31 —
    // it should have been clamped down to February's real last day, 29.
    expect(find.text('31'), findsNothing,
        reason: 'day 31 does not exist in February and must not still be '
            'selectable or selected after the month change');
    expect(find.text('29'), findsWidgets,
        reason: 'the selected day should have been clamped down to '
            "February's actual length");

    // Fill in a name and submit.
    await tester.enterText(find.byType(TextField).first, 'Test Feast');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    final rows = await db.select(db.localCalendarEntries).get();
    expect(rows.length, 1);
    expect(rows.single.name, 'Test Feast');
    expect(rows.single.month, 2);
    expect(rows.single.day, 29,
        reason: 'must be a real February date — the pre-fix bug would '
            'have saved day 31, a date that can never occur in February '
            'and so would never appear anywhere in the app again');

    // Round 14, third follow-up: with the two fixes above, this test finally
    // ran to completion for the first time ever — and immediately hit the
    // exact same "A Timer is still pending even after the widget tree was
    // disposed" failure that widget_test.dart had (see that file's own doc
    // comment for the full root-cause writeup: drift's internal
    // `StreamQueryStore.markAsClosed` schedules a `Duration.zero` Timer
    // whenever a `StreamBuilder` watching a `.watch()` query — here,
    // `LocalCalendarEditorScreen`'s `repo.watchLocalEntries()` — is
    // disposed, and the framework's own end-of-test teardown is what
    // finally disposes it here, too late for `_verifyInvariants()` to see
    // it fire). This test only ever hit the assertion now because every
    // previous run failed earlier, before the widget tree was ever left
    // pumped at the end of the test body. Same fix: dispose explicitly and
    // let a real `pumpAndSettle()` (not a bare `pump()`) elapse enough
    // fake-clock time for the Timer to actually fire before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
