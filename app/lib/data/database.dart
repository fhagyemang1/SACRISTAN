import 'dart:io';

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
  // Lightweight, dependency-free v4-ish UUID: good enough for a local
  // primary key that never has to be globally unique across devices
  // (no sync in this build). Swap for package:uuid if/when cloud sync is
  // added and cross-device uniqueness starts to matter.
  final rnd = DateTime.now().microsecondsSinceEpoch;
  final rand2 = identityHashCode(Object());
  return '${rnd.toRadixString(16)}-${rand2.toRadixString(16)}';
}
