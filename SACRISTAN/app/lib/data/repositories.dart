import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart' as lc;

import 'database.dart';

/// Repositories are the only thing UI code talks to — never the database
/// directly. This is what makes an optional future sync layer additive
/// (see docs/ARCHITECTURE.md §1): a `SyncEngine` would listen to the same
/// `.watch()` streams these expose and push/pull through the repositories,
/// with zero changes to any screen.

class CalendarRepository {
  final SacristanDatabase db;
  CalendarRepository(this.db);

  /// Resolves the full liturgical description of [date], including any
  /// parish/diocesan local-supplement entries stored offline in SQLite.
  /// This never touches the network — the calendar engine underneath is
  /// pure, offline, on-device computation.
  Future<lc.LiturgicalDay> dayFor(DateTime date) async {
    final rows = await db.select(db.localCalendarEntries).get();
    final supplement = rows
        .map((r) => lc.LocalCalendarEntry(
              id: r.id,
              month: r.month,
              day: r.day,
              name: r.name,
              latinName: r.latinName,
              rank: lc.CelebrationRank.values.byName(r.rank),
              color: lc.LiturgicalColor.values.byName(r.color),
              notes: r.notes,
            ))
        .toList();
    return lc.resolveLiturgicalDay(date, localSupplement: supplement);
  }

  Future<List<lc.LiturgicalDay>> weekFrom(DateTime start) async {
    final days = <lc.LiturgicalDay>[];
    for (var i = 0; i < 7; i++) {
      days.add(await dayFor(start.add(Duration(days: i))));
    }
    return days;
  }

  Future<String> addLocalEntry({
    required int month,
    required int day,
    required String name,
    String? latinName,
    required lc.CelebrationRank rank,
    required lc.LiturgicalColor color,
    String? notes,
  }) async {
    final id = newId();
    await db.into(db.localCalendarEntries).insert(
          LocalCalendarEntriesCompanion.insert(
            id: Value(id),
            month: month,
            day: day,
            name: name,
            latinName: Value(latinName),
            rank: rank.name,
            color: color.name,
            notes: Value(notes),
          ),
        );
    return id;
  }

  /// Streams the parish/diocesan local supplementary calendar for the
  /// Settings editor. Entirely local — no network involved in reading,
  /// writing, or "importing" this list (an import is just parsing a file
  /// the user picks on-device and calling [addLocalEntry] per row).
  Stream<List<LocalCalendarEntryRow>> watchLocalEntries() {
    return (db.select(db.localCalendarEntries)
          ..orderBy([
            (e) => OrderingTerm.asc(e.month),
            (e) => OrderingTerm.asc(e.day),
          ]))
        .watch();
  }

  Future<void> deleteLocalEntry(String id) => (db.delete(db.localCalendarEntries)
        ..where((e) => e.id.equals(id)))
      .go();
}

class MassRepository {
  final SacristanDatabase db;
  MassRepository(this.db);

  /// Today's Mass rows of [type], so a parish with several simultaneous
  /// Masses (multiple priests, a large parish) can pick which one a
  /// checklist belongs to instead of everything collapsing into one.
  Future<List<Mass>> todaysMasses(MassType type) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (db.select(db.masses)
          ..where((m) =>
              m.massType.equals(type) &
              m.date.isBiggerOrEqualValue(start) &
              m.date.isSmallerThanValue(end))
          ..orderBy([(m) => OrderingTerm.asc(m.date)]))
        .get();
  }

  Future<String> create(MassType type, String label, {DateTime? date}) async {
    final id = newId();
    await db.into(db.masses).insert(
          MassesCompanion.insert(
            id: Value(id),
            date: date ?? DateTime.now(),
            label: label,
            massType: type,
          ),
        );
    return id;
  }
}

class ChecklistRepository {
  final SacristanDatabase db;
  ChecklistRepository(this.db);

  Stream<List<ChecklistTemplate>> watchTemplatesFor(MassType type) {
    return (db.select(db.checklistTemplates)
          ..where((t) => t.massType.equals(type)))
        .watch();
  }

  Stream<List<ChecklistItem>> watchItems(String templateId) {
    return (db.select(db.checklistItems)
          ..where((i) => i.templateId.equals(templateId))
          ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
        .watch();
  }

  Future<String> createInstance(String massId, String templateId) async {
    final id = newId();
    await db.into(db.checklistInstances).insert(
          ChecklistInstancesCompanion.insert(
            id: Value(id),
            massId: massId,
            templateId: templateId,
          ),
        );
    return id;
  }

  /// Resumes the existing checklist instance for this (Mass, template)
  /// pair if one already exists, or creates a fresh one otherwise. This is
  /// what makes re-opening "Sunday Mass — Before Mass" from the list
  /// continue where a sacristan left off, rather than silently starting a
  /// new blank checklist and orphaning their progress every time.
  Future<String> findOrCreateInstance(String massId, String templateId) async {
    final existing = await (db.select(db.checklistInstances)
          ..where((i) =>
              i.massId.equals(massId) & i.templateId.equals(templateId)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return createInstance(massId, templateId);
  }

  Stream<Map<String, ChecklistTick>> watchTicks(String instanceId) {
    final query = db.select(db.checklistTicks)
      ..where((t) => t.instanceId.equals(instanceId));
    return query.watch().map(
          (rows) => {for (final r in rows) r.itemId: r},
        );
  }

  Future<void> setTick(
      String instanceId, String itemId, bool done, String? profileId) async {
    final existing = await (db.select(db.checklistTicks)
          ..where((t) =>
              t.instanceId.equals(instanceId) & t.itemId.equals(itemId)))
        .getSingleOrNull();
    if (existing == null) {
      await db.into(db.checklistTicks).insert(
            ChecklistTicksCompanion.insert(
              instanceId: instanceId,
              itemId: itemId,
              isDone: Value(done),
              doneAt: Value(done ? DateTime.now() : null),
              doneByProfileId: Value(profileId),
            ),
          );
    } else {
      await (db.update(db.checklistTicks)
            ..where((t) => t.id.equals(existing.id)))
          .write(ChecklistTicksCompanion(
        isDone: Value(done),
        doneAt: Value(done ? DateTime.now() : null),
        doneByProfileId: Value(profileId),
      ));
    }
  }
}

class InventoryRepository {
  final SacristanDatabase db;
  InventoryRepository(this.db);

  Stream<List<InventoryItem>> watchAll() =>
      (db.select(db.inventoryItems)
            ..orderBy([(i) => OrderingTerm.asc(i.category)]))
          .watch();

  Stream<List<InventoryItem>> watchLowStock() =>
      (db.select(db.inventoryItems)..where((i) => i.lowStockFlag.equals(true)))
          .watch();

  Future<void> upsert(InventoryItemsCompanion item) async {
    await db.into(db.inventoryItems).insertOnConflictUpdate(item);
  }

  Future<void> delete(String id) =>
      (db.delete(db.inventoryItems)..where((i) => i.id.equals(id))).go();
}

class NotesRepository {
  final SacristanDatabase db;
  NotesRepository(this.db);

  Stream<List<Note>> watchForDate(DateTime date) {
    final key = _dateKey(date);
    return (db.select(db.notes)
          ..where((n) => n.linkedType.equals('date') & n.linkedId.equals(key))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }

  Future<void> addForDate(DateTime date, String body) async {
    await db.into(db.notes).insert(
          NotesCompanion.insert(
            linkedType: 'date',
            linkedId: _dateKey(date),
            body: body,
          ),
        );
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Sacristan profiles and the admin PIN gate. The PIN is never stored in
/// plaintext: it's salted (a random value stored alongside the hash) and
/// hashed with SHA-256 before being written to SQLite. This is a
/// convenience lock to keep volunteers out of template/inventory editing
/// by mistake, not a security boundary against a determined attacker with
/// access to the device's file system — that tradeoff is appropriate for
/// a local, single-device parish tool with no online account.
class ProfileRepository {
  final SacristanDatabase db;
  ProfileRepository(this.db);

  Stream<List<Profile>> watchAll() => db.select(db.profiles).watch();

  Future<String> addProfile(String displayName, ProfileRole role) async {
    final id = newId();
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: Value(id),
            displayName: displayName,
            role: role,
          ),
        );
    return id;
  }

  Future<void> deleteProfile(String id) =>
      (db.delete(db.profiles)..where((p) => p.id.equals(id))).go();

  /// Sets (or replaces) the admin PIN on [profileId].
  Future<void> setPin(String profileId, String pin) async {
    final salt = newId();
    final hash = _hashPin(pin, salt);
    await (db.update(db.profiles)..where((p) => p.id.equals(profileId)))
        .write(ProfilesCompanion(pinHash: Value('$salt:$hash')));
  }

  /// Returns true if [pin] matches the stored hash for [profileId].
  Future<bool> verifyPin(String profileId, String pin) async {
    final profile = await (db.select(db.profiles)
          ..where((p) => p.id.equals(profileId)))
        .getSingleOrNull();
    final stored = profile?.pinHash;
    if (stored == null || !stored.contains(':')) return false;
    final parts = stored.split(':');
    final salt = parts[0];
    final expectedHash = parts[1];
    return _hashPin(pin, salt) == expectedHash;
  }

  String _hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}

class ContactRepository {
  final SacristanDatabase db;
  ContactRepository(this.db);

  Stream<List<Contact>> watchAll() =>
      (db.select(db.contacts)..orderBy([(c) => OrderingTerm.asc(c.role)]))
          .watch();

  Future<void> add(ContactRole role, String name, String phone) async {
    await db.into(db.contacts).insert(
          ContactsCompanion.insert(role: role, name: name, phone: phone),
        );
  }

  Future<void> delete(String id) =>
      (db.delete(db.contacts)..where((c) => c.id.equals(id))).go();
}

class SupplierRepository {
  final SacristanDatabase db;
  SupplierRepository(this.db);

  Stream<List<Supplier>> watchAll() => db.select(db.suppliers).watch();

  Future<void> add(String name, {String? contactName, String? phone, String? notes}) async {
    await db.into(db.suppliers).insert(
          SuppliersCompanion.insert(
            name: name,
            contactName: Value(contactName),
            phone: Value(phone),
            notes: Value(notes),
          ),
        );
  }

  Future<void> delete(String id) =>
      (db.delete(db.suppliers)..where((s) => s.id.equals(id))).go();
}

class ReminderRepository {
  final SacristanDatabase db;
  ReminderRepository(this.db);

  Stream<List<Reminder>> watchActive() => (db.select(db.reminders)
        ..where((r) => r.isActive.equals(true))
        ..orderBy([(r) => OrderingTerm.asc(r.triggerAt)]))
      .watch();

  Future<String> add({
    required String title,
    String? body,
    required DateTime triggerAt,
    String? repeatRule,
  }) async {
    final id = newId();
    await db.into(db.reminders).insert(
          RemindersCompanion.insert(
            id: Value(id),
            title: title,
            body: Value(body),
            triggerAt: triggerAt,
            repeatRule: Value(repeatRule),
          ),
        );
    return id;
  }

  Future<void> cancel(String id) async {
    await (db.update(db.reminders)..where((r) => r.id.equals(id)))
        .write(const RemindersCompanion(isActive: Value(false)));
  }
}

/// Generic local key/value settings store (locale choice, theme override,
/// anything else small and app-wide). Backed by the AppSettings table.
class SettingsRepository {
  final SacristanDatabase db;
  SettingsRepository(this.db);

  Future<String?> getValue(String key) async {
    final row = await (db.select(db.appSettings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) async {
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        );
  }
}

class ReferenceRepository {
  final SacristanDatabase db;
  ReferenceRepository(this.db);

  Stream<List<ReferenceEntry>> watchByCategory(String category) {
    return (db.select(db.referenceEntries)
          ..where((e) => e.category.equals(category))
          ..orderBy([(e) => OrderingTerm.asc(e.title)]))
        .watch();
  }

  Future<void> add({
    required String category,
    required String title,
    String? latinName,
    required String bodyMarkdown,
    required String sourceCitation,
    String? illustrationAsset,
    bool isBuiltin = false,
  }) async {
    await db.into(db.referenceEntries).insert(
          ReferenceEntriesCompanion.insert(
            category: category,
            title: title,
            latinName: Value(latinName),
            bodyMarkdown: bodyMarkdown,
            sourceCitation: sourceCitation,
            illustrationAsset: Value(illustrationAsset),
            isBuiltin: Value(isBuiltin),
          ),
        );
  }

  Future<void> delete(String id) =>
      (db.delete(db.referenceEntries)..where((e) => e.id.equals(id))).go();
}
