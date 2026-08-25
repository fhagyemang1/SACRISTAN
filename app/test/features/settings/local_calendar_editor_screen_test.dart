import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sacristan/data/database.dart';
import 'package:sacristan/data/repositories.dart';
import 'package:sacristan/features/settings/local_calendar_editor_screen.dart';

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

    await tester.pumpWidget(MaterialApp(
      home: Provider<CalendarRepository>.value(
        value: repo,
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
    await tester.tap(intDropdowns.at(1));
    await tester.pumpAndSettle();
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
    await tester.tap(intDropdowns.at(0));
    await tester.pumpAndSettle();
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
  });
}
