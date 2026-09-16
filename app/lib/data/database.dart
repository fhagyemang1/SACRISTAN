import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Tables — see docs/ARCHITECTURE.md §2.2 for the full data-model rationale.
// All tables live in one on-device SQLite file via `drift`; there is no
// network client anywhere in this file.
// ---------------------------------------------------------------------------

enum ProfileRole { admin, volunteer }

class Profiles extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get displayName => text()();
  TextColumn get role => textEnum<ProfileRole>()();
  TextColumn get pinHash => text().nullable()(); // salted hash, admin-only
  TextColumn get locale => text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

class Suppliers extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get name => text()();
  TextColumn get contactName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

enum MassType {
  sunday,
  weekday,
  funeral,
  wedding,
  baptism,
  benediction,
  holyWeek,
}

@DataClassName('Mass')
class Masses extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  DateTimeColumn get date => dateTime()();
  TextColumn get label => text()(); // e.g. "8:00 AM Sunday Mass"
  TextColumn get massType => textEnum<MassType>()();
  TextColumn get celebrantName => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistTemplates extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get name => text()();
  TextColumn get massType => textEnum<MassType>()();
  TextColumn get phase => text()(); // 'pre' | 'post'
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
  TextColumn get locale => text().withDefault(const Constant('en'))();
  // Round 14+: deletion was deliberately never offered for a template with
  // real usage history — see the long comment on
  // `ChecklistRepository.addTemplate` this column now resolves. Null means
  // active and selectable as usual; non-null means an admin archived it —
  // hidden from the "start a checklist" template picker
  // (`watchTemplatesFor`), but the template row, its items, and every past
  // `ChecklistInstance`/`ChecklistTick` that references it are left
  // completely untouched, so historical checklists stay fully viewable.
  // An admin can restore it from the template management screen.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistItems extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get templateId =>
      text().references(ChecklistTemplates, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get labelKey => text().nullable()(); // for built-in localized items
  TextColumn get labelCustom => text().nullable()(); // for user-authored items
  TextColumn get latinTerm => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistInstances extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get massId =>
      text().references(Masses, #id, onDelete: KeyAction.cascade)();
  TextColumn get templateId => text().references(ChecklistTemplates, #id)();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistTicks extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get instanceId => text()
      .references(ChecklistInstances, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemId =>
      text().references(ChecklistItems, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();
  TextColumn get doneByProfileId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

enum InventoryCategory {
  chasuble,
  stole,
  alb,
  linen,
  vessel,
  candle,
  incense,
  hosts,
  wine,
  other,
}

class InventoryItems extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get category => textEnum<InventoryCategory>()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()(); // liturgical color, if applicable
  TextColumn get condition => text().nullable()(); // free text: "good", "worn", ...
  TextColumn get storageLocation => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  IntColumn get lowStockThreshold => integer().nullable()();
  BoolColumn get lowStockFlag => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Notes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get linkedType => text()(); // 'date' | 'mass' | 'checklistItem'
  TextColumn get linkedId => text()(); // ISO date string, or a row id
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  DateTimeColumn get triggerAt => dateTime()();
  TextColumn get repeatRule => text().nullable()(); // null | 'weekly' | 'yearly'
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

enum ContactRole { pastor, sacristan, serverLeader }

class Contacts extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get role => textEnum<ContactRole>()();
  TextColumn get name => text()();
  TextColumn get phone => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReferenceEntry')
class ReferenceEntries extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get category => text()(); // 'glossary' | 'girm' | 'rubric'
  TextColumn get title => text()();
  TextColumn get latinName => text().nullable()();
  TextColumn get bodyMarkdown => text()();
  TextColumn get sourceCitation => text()();
  TextColumn get illustrationAsset => text().nullable()();
  // True for the entries bundled with the app (see reference_data.dart,
  // seeded on first launch); false for parish-added entries. Both are
  // editable/deletable once admin mode is unlocked — this flag is purely
  // informational (e.g. to label bundled vs. parish-added in the UI), not
  // a protection mechanism, since a parish may legitimately want to
  // correct or remove a bundled entry too.
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A parish/diocesan supplementary calendar entry — see
/// packages/liturgical_calendar/lib/src/local_calendar.dart for the
/// pure-Dart counterpart this table's rows are converted into at read time.
@DataClassName('LocalCalendarEntryRow')
class LocalCalendarEntries extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  IntColumn get month => integer()();
  IntColumn get day => integer()();
  TextColumn get name => text()();
  TextColumn get latinName => text().nullable()();
  TextColumn get rank => text()(); // matches CelebrationRank.name
  TextColumn get color => text()(); // matches LiturgicalColor.name
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [
  Profiles,
  Suppliers,
  Masses,
  ChecklistTemplates,
  ChecklistItems,
  ChecklistInstances,
  ChecklistTicks,
  InventoryItems,
  Notes,
  Reminders,
  Contacts,
  ReferenceEntries,
  LocalCalendarEntries,
  AppSettings,
])
class SacristanDatabase extends _$SacristanDatabase {
  SacristanDatabase() : super(_openConnection());

  // Round 11: test-only constructor. Lets tests open this database
  // against an in-memory executor (e.g. `NativeDatabase.memory()`)
  // instead of the real on-device file `_openConnection()` always uses —
  // the latter calls `getApplicationDocumentsDirectory()`, which needs a
  // platform channel no plain `flutter test` run provides. Added
  // specifically so `test/data/checklist_instance_race_test.dart` can
  // exercise `ChecklistRepository.findOrCreateInstance`'s locking against
  // a real (if temporary) drift database rather than only reasoning
  // about it. Not annotated `@visibleForTesting` deliberately — that
  // annotation lives in `package:meta`, which this file doesn't otherwise
  // depend on directly, and adding an import for a package not listed in
  // pubspec.yaml risks a `depend_on_referenced_packages` lint this round
  // has no compiler available to check against (see round 9's whole
  // saga on trusting `flutter analyze` over guesses). A plain, clearly
  // worded doc comment costs nothing and carries the same intent.
  SacristanDatabase.forTesting(super.executor);

  /// Bump this and add a migration step in [migration] whenever a table or
  /// column changes. Kept independent from the bundled liturgical-calendar
  /// dataset version (that one lives in the `liturgical_calendar` package
  /// and is versioned by app release, not by this schema).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        // Example for the future, left here deliberately so the *pattern*
        // for additive, non-destructive migrations is obvious to whoever
        // adds the next column/table (e.g. for optional cloud sync):
        //
        // onUpgrade: (m, from, to) async {
        //   if (from < 2) {
        //     await m.addColumn(inventoryItems, inventoryItems.syncState);
        //   }
        // },
        //
        // sqlite3 does NOT enforce foreign key constraints by default —
        // it must be turned on per-connection, every time a connection is
        // opened (it is not a persisted database setting). Without this,
        // every `onDelete: KeyAction.cascade`/FK-restrict relationship
        // declared on the tables above (e.g. `ChecklistTicks.itemId` ->
        // `ChecklistItems`, `ChecklistInstances.massId` -> `Masses`) is
        // silently inert: SQLite lets the delete through and simply
        // leaves the dependent rows behind, orphaned, instead of
        // cascading or blocking as the schema declares and as
        // repositories.dart's callers rely on. `beforeOpen` runs on every
        // connection open (fresh install and every subsequent launch),
        // which is what's needed here — `onCreate` above only runs once,
        // the very first time the database file is created.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sacristan.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Public id generator, used by call sites that need to know a row's id
/// before/without a round-trip read (e.g. `insertReturning` call sites
/// that want to keep call code simple). See [_uuid] docs below.
String newId() => _uuid();

String _uuid() {
  // Round 10: the original version of this function combined
  // `DateTime.now().microsecondsSinceEpoch` with `identityHashCode
  // (Object())` for entropy — and neither half of that is actually a
  // uniqueness guarantee. `DateTime.now()`'s real-world resolution isn't
  // guaranteed to be sub-microsecond on every platform this app ships to
  // (iOS/Android/Windows); and `identityHashCode()` is explicitly *not*
  // documented as collision-free — two distinct objects can share one.
  // The first place this function runs at any volume is `main.dart`'s
  // first-launch seeding loop, ~100 sequential `await ...insert(...)`
  // calls building the built-in checklist templates before the UI even
  // shows — a primary-key collision there throws on insert and would
  // crash the app before a sacristan ever sees a screen. No CI run
  // caught this (a collision is a runtime probability, not a type
  // error), so this was manual review, the same way round 6 and round 8's
  // worst findings were.
  //
  // Fixed with real randomness instead of derived-from-timing entropy:
  // 128 bits from `Random.secure()` (a CSPRNG, part of `dart:math` — no
  // new package, so no risk of repeating round 9's dependency-conflict
  // saga), formatted as a conventional-looking v4 UUID. Collision
  // probability across the low thousands of rows this app will ever
  // hold in one parish's database is effectively zero.
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 1
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
