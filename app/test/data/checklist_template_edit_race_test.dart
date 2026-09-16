// Round 13 fix: `Value` was shown but never actually used in this file
// (unlike the sibling race-test files) — `flutter analyze` flagged it as
// an unused shown name the first time it was run for real. `OrderingTerm`
// (used by `reorderItem`'s tests below) is kept.
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/data/database.dart';
import 'package:sacristan/data/repositories.dart';

/// Regression tests for the round-11 "Manage Checklist Templates" screen's
/// repository layer: `addTemplate`, `addItem`, `deleteItem`, and
/// `reorderItem` on `ChecklistRepository`.
///
/// `addItem` and `reorderItem` both read the template's current item list
/// and then write based on what they read — the same shape of
/// check-then-write race already found and fixed twice elsewhere this
/// round (`findOrCreateInstance`, `setTick`). An admin tapping "add item"
/// or a reorder arrow rapidly is a realistic way to trigger two concurrent
/// calls for the same template. All three mutators are serialized per
/// template through `_serializedForTemplate`, and `reorderItem` re-queries
/// the item list itself each time it actually runs rather than trusting a
/// caller-cached list — these tests exercise that directly.
void main() {
  group('ChecklistRepository template/item management', () {
    late SacristanDatabase db;
    late ChecklistRepository repo;
    late String templateId;

    setUp(() async {
      db = SacristanDatabase.forTesting(NativeDatabase.memory());
      repo = ChecklistRepository(db);
      templateId = await repo.addTemplate(
        name: 'Test Template',
        massType: MassType.sunday,
        phase: 'pre',
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('addTemplate stores the fields it was given', () async {
      final rows = await (db.select(db.checklistTemplates)
            ..where((t) => t.id.equals(templateId)))
          .get();
      expect(rows.length, 1);
      expect(rows.single.name, 'Test Template');
      expect(rows.single.massType, MassType.sunday);
      expect(rows.single.phase, 'pre');
    });

    test(
        'two concurrent addItem calls on the same template both land, with '
        'distinct, non-colliding sortOrder values', () async {
      // Neither call is awaited before the second starts — this is what
      // would reproduce a check-then-write race if addItem read the
      // current max sortOrder and then wrote without serialization.
      final ids = await Future.wait([
        repo.addItem(templateId: templateId, label: 'Item A'),
        repo.addItem(templateId: templateId, label: 'Item B'),
      ]);

      final items = await (db.select(db.checklistItems)
            ..where((i) => i.templateId.equals(templateId)))
          .get();
      expect(items.length, 2,
          reason: 'both concurrent adds must produce their own row');
      expect(ids.toSet().length, 2, reason: 'both ids must be distinct');
      final orders = items.map((i) => i.sortOrder).toSet();
      expect(orders.length, 2,
          reason: 'a pre-fix race could have both calls compute the same '
              'next sortOrder from a stale read');
    });

    test('deleteItem removes only the targeted item', () async {
      final keepId =
          await repo.addItem(templateId: templateId, label: 'Keep me');
      final deleteId =
          await repo.addItem(templateId: templateId, label: 'Delete me');

      await repo.deleteItem(templateId, deleteId);

      final items = await (db.select(db.checklistItems)
            ..where((i) => i.templateId.equals(templateId)))
          .get();
      expect(items.length, 1);
      expect(items.single.id, keepId);
    });

    test('reorderItem swaps sortOrder with the adjacent item', () async {
      final aId = await repo.addItem(templateId: templateId, label: 'A');
      final bId = await repo.addItem(templateId: templateId, label: 'B');

      await repo.reorderItem(templateId, bId, -1); // move B up, before A

      final items = await (db.select(db.checklistItems)
            ..where((i) => i.templateId.equals(templateId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .get();
      expect(items.map((i) => i.id).toList(), [bId, aId]);
    });

    test('reorderItem is a no-op past either end of the list', () async {
      final aId = await repo.addItem(templateId: templateId, label: 'A');
      final bId = await repo.addItem(templateId: templateId, label: 'B');

      await repo.reorderItem(templateId, aId, -1); // already first
      await repo.reorderItem(templateId, bId, 1); // already last

      final items = await (db.select(db.checklistItems)
            ..where((i) => i.templateId.equals(templateId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .get();
      expect(items.map((i) => i.id).toList(), [aId, bId]);
    });

    test(
        'rapid concurrent reorder calls on the same template still leave '
        'every item with a distinct sortOrder (no corruption)', () async {
      final aId = await repo.addItem(templateId: templateId, label: 'A');
      final bId = await repo.addItem(templateId: templateId, label: 'B');
      final cId = await repo.addItem(templateId: templateId, label: 'C');

      // Fire several reorders without awaiting between them — without
      // per-template serialization and a fresh re-query inside each call,
      // these could interleave on stale reads and leave two items sharing
      // one sortOrder (or one item's move silently lost).
      await Future.wait([
        repo.reorderItem(templateId, bId, -1),
        repo.reorderItem(templateId, cId, -1),
      ]);

      final items = await (db.select(db.checklistItems)
            ..where((i) => i.templateId.equals(templateId)))
          .get();
      expect(items.length, 3, reason: 'no item should have been lost');
      final orders = items.map((i) => i.sortOrder).toSet();
      expect(orders.length, 3,
          reason: 'every item must end up with its own distinct sortOrder '
              '— a collision here means two rows now tie for one position');
      expect({aId, bId, cId}, items.map((i) => i.id).toSet());
    });
  });
}
