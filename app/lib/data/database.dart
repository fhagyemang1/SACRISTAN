import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

enum ProfileRole { admin, volunteer }

class Profiles extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get displayName => text()();
  TextColumn get role => textEnum<ProfileRole>()();
  TextColumn get pinHash => text().nullable()();
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
  TextColumn get label => text()();
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
  TextColumn get phase => text()();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
  TextColumn get locale => text().withDefault(const Constant('en'))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistItems extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get templateId =>
      text().references(ChecklistTemplates, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get labelKey => text().nullable()();
  TextColumn get labelCustom => text().nullable()();
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
  TextColumn get color => text().nullable()();
  TextColumn get condition => text().nullable()();
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
  TextColumn get linkedType => text()();
  TextColumn get linkedId => text()();
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
  TextColumn get repeatRule => text().nullable()();
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
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get latinName => text().nullable()();
  TextColumn get bodyMarkdown => text()();
  TextColumn get sourceCitation => text()();
  TextColumn get illustrationAsset => text().nullable()();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalCalendarEntryRow')
class LocalCalendarEntries extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  IntColumn get month => integer()();
  IntColumn get day => integer()();
  TextColumn get name => text()();
  TextColumn get latinName => text().nullable()();
  TextColumn get rank => text()();
  TextColumn get color => text()();
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

  SacristanDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
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

String newId() => _uuid();

String _uuid() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}