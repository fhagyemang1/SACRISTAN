import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/data/database.dart';
import 'package:sacristan/data/repositories.dart';

/// Regression test for a round-11 bug: `ChecklistRepository.setTick` (the
/// function every checkbox tap in the app's core Checklist screen calls)
/// used to be a plain check-then-insert-or-update with no guard against
/// two calls for the *same* (instance, item) racing each other. This is
/// reachable in ordinary use, not just a theoretical concurrency edge
/// case: `BigCheckboxTile` has no debounce of its own, and its `checked`
/// prop only flips once a write round-trips back through `watchTicks`'s
/// stream — so two fast taps on the same checklist row both fire before
/// either write lands. Both could see "no tick row yet" and both insert
/// one, and since drift's `getSingleOrNull()` throws when more than one
/// row matches, every later tap on that item would then throw instead of
/// toggling — silently bricking that one checkbox.
///
/// `setTick` now chains same-key calls through an in-memory lock so they
/// run one at a time, in the order they were made, rather than sharing
/// one shortcut result (unlike `findOrCreateInstance`'s fix, two
/// `setTick` calls can carry genuinely different intended values, so
/// the fix must still apply every call, just not concurrently).
void main() {
  group('ChecklistRepository.setTick', () {
    late SacristanDatabase db;
    late ChecklistRepository repo;
    late String instanceId;
    late String itemId;

    setUp(() async {
      db = SacristanDatabase.forTesting(NativeDatabase.memory());
      repo = ChecklistRepository(db);

      final massId = newId();
      await db.into(db.masses).insert(MassesCompanion.insert(
            id: Value(massId),
            date: DateTime(2026, 8, 23),
            label: 'Test Mass',
            massType: MassType.sunday,
          ));
      final templateId = newId();
      await db.into(db.checklistTemplates).insert(
            ChecklistTemplatesCompanion.insert(
              id: Value(templateId),
              name: 'Test Template',
              massType: MassType.sunday,
              phase: 'pre',
            ),
          );
      itemId = newId();
      await db.into(db.checklistItems).insert(
            ChecklistItemsCompanion.insert(
              id: Value(itemId),
              templateId: templateId,
              labelCustom: const Value('Light the sanctuary lamp'),
            ),
          );
      instanceId = await repo.createInstance(massId, templateId);
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'two concurrent taps with the same target value produce exactly '
        'one tick row, not two', () async {
      // Neither call is awaited before the second starts — this is what
      // reproduces the race (see the class-level doc comment above).
      await Future.wait([
        repo.setTick(instanceId, itemId, true, null),
        repo.setTick(instanceId, itemId, true, null),
      ]);

      final rows = await (db.select(db.checklistTicks)
            ..where((t) =>
                t.instanceId.equals(instanceId) & t.itemId.equals(itemId)))
          .get();
      expect(rows.length, 1,
          reason: 'exactly one ChecklistTick row should exist for this '
              'item — the pre-fix race could create two, and every tap '
              'after that would throw instead of toggling');
      expect(rows.single.isDone, true);
    });

    test(
        'two concurrent taps with different target values both apply, in '
        'the order they were made', () async {
      // Call A (done=true) is issued before call B (done=false); the fix
      // must preserve that order rather than letting them race, so the
      // final stored state should reflect B, the call made second.
      await Future.wait([
        repo.setTick(instanceId, itemId, true, null),
        repo.setTick(instanceId, itemId, false, null),
      ]);

      final rows = await (db.select(db.checklistTicks)
            ..where((t) =>
                t.instanceId.equals(instanceId) & t.itemId.equals(itemId)))
          .get();
      expect(rows.length, 1);
      expect(rows.single.isDone, false,
          reason: 'the second call in program order must be the one '
              'that determines the final state — a race could apply '
              'them out of order or lose one entirely');
    });

    test('a normal, non-racing sequence of taps still works as before',
        () async {
      await repo.setTick(instanceId, itemId, true, 'profile-1');
      var rows = await (db.select(db.checklistTicks)
            ..where((t) =>
                t.instanceId.equals(instanceId) & t.itemId.equals(itemId)))
          .get();
      expect(rows.length, 1);
      expect(rows.single.isDone, true);
      expect(rows.single.doneByProfileId, 'profile-1');

      await repo.setTick(instanceId, itemId, false, 'profile-1');
      rows = await (db.select(db.checklistTicks)
            ..where((t) =>
                t.instanceId.equals(instanceId) & t.itemId.equals(itemId)))
          .get();
      expect(rows.length, 1);
      expect(rows.single.isDone, false);
    });
  });
}
