import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/data/database.dart';
import 'package:sacristan/data/repositories.dart';

/// Regression test for a round-11 bug: `ChecklistRepository
/// .findOrCreateInstance` used to be a plain check-then-insert
/// ("does an instance already exist for this (Mass, template) pair? if
/// not, create one") with nothing preventing two calls for the *same*
/// pair from racing each other — both could see "no existing instance
/// yet" and both insert their own, silently splitting one checklist's
/// progress across two rows. In the real app this was reachable from
/// `checklist_list_screen.dart`'s `_openTemplate`, which a sacristan
/// hurrying before Mass could trigger twice with a rapid double-tap on
/// the same checklist template before the first tap's lookup-or-create
/// finished and navigated away. `checklist_list_screen.dart` now also
/// has its own UI-level debounce for that one call site, but this test
/// targets the repository fix directly: an in-memory lock keyed by
/// "$massId:$templateId" that makes any two concurrent callers for the
/// same pair share one in-flight lookup-or-create, so the fix protects
/// every caller, not just the one screen that first surfaced the bug.
void main() {
  group('ChecklistRepository.findOrCreateInstance', () {
    late SacristanDatabase db;
    late ChecklistRepository repo;

    setUp(() {
      // `SacristanDatabase.forTesting` (added this round) opens against
      // an in-memory drift executor instead of the real on-device file,
      // which needs a platform channel (`getApplicationDocumentsDirectory`)
      // no plain `flutter test` run provides.
      db = SacristanDatabase.forTesting(NativeDatabase.memory());
      repo = ChecklistRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'two concurrent calls for the same (Mass, template) pair resolve '
        'to one shared instance instead of racing into two', () async {
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

      // Deliberately not awaiting the first call before starting the
      // second — that's what reproduces the race. Dart's single-threaded
      // event loop still interleaves these two calls at their `await`
      // points, the same way two near-simultaneous taps on a real device
      // would interleave two separate calls into this same method.
      final results = await Future.wait([
        repo.findOrCreateInstance(massId, templateId),
        repo.findOrCreateInstance(massId, templateId),
      ]);

      expect(results[0], results[1],
          reason: 'both concurrent calls for the same (Mass, template) '
              'pair must resolve to the same checklist instance id');

      final rows = await (db.select(db.checklistInstances)
            ..where((i) =>
                i.massId.equals(massId) & i.templateId.equals(templateId)))
          .get();
      expect(rows.length, 1,
          reason: 'exactly one ChecklistInstance row should exist for '
              'this pair — the pre-fix race could create two, silently '
              'splitting one checklist\'s progress across them');
    });

    test(
        'a second call after the first has already finished still resumes '
        'the same instance (the ordinary, non-racing case)', () async {
      final massId = newId();
      await db.into(db.masses).insert(MassesCompanion.insert(
            id: Value(massId),
            date: DateTime(2026, 8, 23),
            label: 'Test Mass 2',
            massType: MassType.weekday,
          ));
      final templateId = newId();
      await db.into(db.checklistTemplates).insert(
            ChecklistTemplatesCompanion.insert(
              id: Value(templateId),
              name: 'Test Template 2',
              massType: MassType.weekday,
              phase: 'post',
            ),
          );

      final first = await repo.findOrCreateInstance(massId, templateId);
      final second = await repo.findOrCreateInstance(massId, templateId);
      expect(second, first);

      final rows = await (db.select(db.checklistInstances)
            ..where((i) =>
                i.massId.equals(massId) & i.templateId.equals(templateId)))
          .get();
      expect(rows.length, 1);
    });

    test(
        'different (Mass, template) pairs never share an instance, even '
        'when looked up concurrently', () async {
      final massA = newId();
      final massB = newId();
      await db.into(db.masses).insert(MassesCompanion.insert(
            id: Value(massA),
            date: DateTime(2026, 8, 23),
            label: 'Mass A',
            massType: MassType.sunday,
          ));
      await db.into(db.masses).insert(MassesCompanion.insert(
            id: Value(massB),
            date: DateTime(2026, 8, 23),
            label: 'Mass B',
            massType: MassType.sunday,
          ));
      final templateId = newId();
      await db.into(db.checklistTemplates).insert(
            ChecklistTemplatesCompanion.insert(
              id: Value(templateId),
              name: 'Shared Template',
              massType: MassType.sunday,
              phase: 'pre',
            ),
          );

      final results = await Future.wait([
        repo.findOrCreateInstance(massA, templateId),
        repo.findOrCreateInstance(massB, templateId),
      ]);

      expect(results[0], isNot(equals(results[1])),
          reason: 'the per-key lock must not accidentally serialize or '
              'merge lookups for genuinely different (Mass, template) '
              'pairs — only identical pairs should ever share a result');
    });
  });
}
