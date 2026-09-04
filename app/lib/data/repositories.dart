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
              m.massType.equalsValue(type) &
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
          ..where((t) => t.massType.equalsValue(type)))
        .watch();
  }

  /// All templates regardless of Mass type — for the template management
  /// screen's own listing (which groups by type itself), as opposed to
  /// [watchTemplatesFor], which is what the "start a checklist" flow
  /// uses to show only the templates relevant to one Mass type.
  Stream<List<ChecklistTemplate>> watchAllTemplates() {
    return (db.select(db.checklistTemplates)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<ChecklistItem>> watchItems(String templateId) {
    return (db.select(db.checklistItems)
          ..where((i) => i.templateId.equals(templateId))
          ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
        .watch();
  }

  /// Round 11: closes a real gap, not just a bug — `checklist_detail_screen
  /// .dart`'s empty-state message has always told sacristans to add items
  /// "from the template editor (Settings > Manage Checklist Templates)",
  /// and Settings' own "Admin PIN" row has always claimed the PIN
  /// "Protects template/inventory editing" — but until this round, no such
  /// editor existed anywhere in the app. Every template a parish could
  /// ever use was exactly the 16 seeded in `builtin_templates.dart`, with
  /// no way to add, adjust, or extend them without a developer. These
  /// methods back the new `ChecklistTemplateEditorScreen`
  /// (`features/settings/checklist_template_editor_screen.dart`), gated
  /// behind the admin PIN the same way the Reference Library already
  /// gates adding/deleting entries.
  Future<String> addTemplate({
    required String name,
    required MassType massType,
    required String phase,
  }) async {
    final id = newId();
    await db.into(db.checklistTemplates).insert(
          ChecklistTemplatesCompanion.insert(
            id: Value(id),
            name: name,
            massType: massType,
            phase: phase,
          ),
        );
    return id;
  }

  /// Deleting a *template* is deliberately not offered: `ChecklistItems`
  /// cascades on template delete, but `ChecklistInstances.templateId`
  /// does not (see `database.dart`) — a template that any Mass has ever
  /// used has real historical checklist rows referencing it, and SQLite's
  /// default foreign-key behavior would reject the delete outright rather
  /// than silently orphaning that history. Handling that well (block with
  /// an explanation? cascade and destroy real history? soft-hide
  /// instead?) is a product decision, not a bug fix — deliberately left
  /// for a future round rather than guessed at here, the same judgment
  /// call round 9 made for the `CheckedState` migration. Items within a
  /// template, and whole templates that were *just* added and never
  /// used, can still be managed via [addItem]/[deleteItem]/[reorderItem]
  /// and [addTemplate] below.
  // Same shape of risk this round already found and fixed twice
  // (`findOrCreateInstance`, `setTick`): [addItem]/[deleteItem]/
  // [reorderItem] below each read the template's current item list and
  // then write based on what they read. An admin tapping the up/down
  // reorder arrows quickly (an entirely plausible way to actually use
  // them) could run two calls concurrently, each computing its write
  // from a snapshot that's gone stale by the time it writes — genuinely
  // garbling the sort order, not just double-inserting. Every method
  // below is serialized per template through this same
  // queue-onto-the-previous-call pattern, and — importantly —
  // [reorderItem] re-queries the item list itself each time it actually
  // runs, rather than trusting a list the caller captured from a
  // possibly-stale `StreamBuilder` snapshot, so serialization alone is
  // enough to make each call see truly current data.
  final _templateEditLocks = <String, Future<void>>{};

  Future<T> _serializedForTemplate<T>(
      String templateId, Future<T> Function() action) {
    final previous = _templateEditLocks[templateId] ?? Future<void>.value();
    final chained = previous.then((_) => action());
    final settled = chained.then((_) {}, onError: (_) {});
    _templateEditLocks[templateId] = settled;
    settled.whenComplete(() {
      if (identical(_templateEditLocks[templateId], settled)) {
        _templateEditLocks.remove(templateId);
      }
    });
    return chained;
  }

  Future<String> addItem({
    required String templateId,
    required String label,
    String? latinTerm,
  }) {
    return _serializedForTemplate(templateId, () async {
      final existing = await (db.select(db.checklistItems)
            ..where((i) => i.templateId.equals(templateId)))
          .get();
      // One past the current highest sortOrder, not `existing.length` —
      // items can have been deleted, leaving gaps, so counting could
      // collide with a sortOrder that's still in use.
      final nextOrder = existing.isEmpty
          ? 0
          : existing.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b) +
              1;
      final id = newId();
      await db.into(db.checklistItems).insert(
            ChecklistItemsCompanion.insert(
              id: Value(id),
              templateId: templateId,
              sortOrder: Value(nextOrder),
              labelCustom: Value(label),
              latinTerm: Value(latinTerm),
            ),
          );
      return id;
    });
  }

  /// Cascades to any `ChecklistTicks` rows for this item (see
  /// `database.dart` — `ChecklistTicks.itemId` has `onDelete: cascade`),
  /// so this is safe even for an item some Mass has already ticked.
  Future<void> deleteItem(String templateId, String itemId) {
    return _serializedForTemplate(templateId,
        () => (db.delete(db.checklistItems)..where((i) => i.id.equals(itemId))).go());
  }

  /// Moves the item [itemId] within its template's sort order by
  /// [direction] (-1 moves it up/earlier, +1 moves it down/later),
  /// swapping sortOrder with whichever neighbor is currently there — read
  /// fresh at call time, not from a list the caller cached earlier. A
  /// no-op if the item is already at that end of the list.
  Future<void> reorderItem(String templateId, String itemId, int direction) {
    return _serializedForTemplate(templateId, () async {
      final items = await (db.select(db.checklistItems)
            ..where((i) => i.templateId.equals(templateId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .get();
      final index = items.indexWhere((i) => i.id == itemId);
      if (index == -1) return;
      final targetIndex = index + direction;
      if (targetIndex < 0 || targetIndex >= items.length) return;
      final a = items[index];
      final b = items[targetIndex];
      // Wrapped in a transaction so the two rows' positions are never
      // observed half-swapped by another concurrent read partway through.
      await db.transaction(() async {
        await (db.update(db.checklistItems)..where((i) => i.id.equals(a.id)))
            .write(ChecklistItemsCompanion(sortOrder: Value(b.sortOrder)));
        await (db.update(db.checklistItems)..where((i) => i.id.equals(b.id)))
            .write(ChecklistItemsCompanion(sortOrder: Value(a.sortOrder)));
      });
    });
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

  // Round 11: keyed by "$massId:$templateId", holds the in-flight Future
  // for any (Mass, template) pair currently going through
  // `findOrCreateInstance`'s check-then-create below. `_openTemplate` in
  // checklist_list_screen.dart already added a UI-level debounce for its
  // one call site (a rapid double-tap on a checklist template), but this
  // repository method has no way to know every caller — this lock closes
  // the same check-then-insert race at the source, for any caller,
  // present or future: two calls racing on the exact same key now share
  // one lookup-or-create instead of each running it independently and
  // (since neither would see the other's not-yet-committed insert)
  // potentially creating two separate `ChecklistInstance` rows for what
  // should be one checklist.
  final _instanceLocks = <String, Future<String>>{};

  /// Resumes the existing checklist instance for this (Mass, template)
  /// pair if one already exists, or creates a fresh one otherwise. This is
  /// what makes re-opening "Sunday Mass — Before Mass" from the list
  /// continue where a sacristan left off, rather than silently starting a
  /// new blank checklist and orphaning their progress every time.
  Future<String> findOrCreateInstance(String massId, String templateId) {
    final key = '$massId:$templateId';
    final inFlight = _instanceLocks[key];
    if (inFlight != null) return inFlight;
    final result = _findOrCreateInstanceUnlocked(massId, templateId);
    _instanceLocks[key] = result;
    // Whatever the outcome, this key's lock must not outlive this one
    // call — otherwise a later, entirely separate request for the same
    // (Mass, template) pair would incorrectly reuse a stale result (or,
    // on error, a broken Future) instead of running its own fresh lookup.
    result.whenComplete(() => _instanceLocks.remove(key));
    return result;
  }

  Future<String> _findOrCreateInstanceUnlocked(
      String massId, String templateId) async {
    final existing = await (db.select(db.checklistInstances)
          ..where((i) =>
              i.massId.equals(massId) & i.templateId.equals(templateId)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return createInstance(massId, templateId);
  }

  /// Round 12: `findOrCreateInstance` above (and `MassRepository
  /// .todaysMasses`, which callers use to decide *which* Mass to pass it)
  /// both key strictly off calendar date — "today" is whatever
  /// `DateTime.now()` says right now. That is exactly right for deciding
  /// whether a *new* Mass has happened, but wrong for resuming one already
  /// in progress: a checklist started before midnight and still open when
  /// the date rolls over (an Easter Vigil that genuinely runs past
  /// 12:00 AM is the clearest case, but simply not finishing before the day
  /// turns over is enough) would otherwise find no Mass "today", and
  /// `checklist_list_screen.dart` would silently create a brand-new Mass
  /// and a brand-new, blank `ChecklistInstance` — leaving the real one's
  /// ticks sitting untouched, and effectively invisible, in SQLite.
  ///
  /// This looks for an instance of this exact [templateId] that was
  /// created within [window] and is not yet fully ticked off, regardless of
  /// which calendar date it was created on. [templateId] (not massType) is
  /// deliberately the key: `checklist_list_screen.dart` only ever reaches
  /// this when *no* Mass exists for today yet, so it can't collide with the
  /// "two simultaneous same-type Masses picked explicitly via the Mass
  /// picker" case — each of those already has its own Mass row for today
  /// and resumes correctly through `findOrCreateInstance` instead. Ordered
  /// newest-first: in the ordinary case there is exactly one candidate (the
  /// checklist actually still in progress); if more than one genuinely
  /// overlapping incomplete instance of the same template exists within the
  /// window — rare, but possible — the caller resumes the most recently
  /// started one rather than being offered a picker, which keeps this
  /// change small and avoids silently starting a third one.
  Future<List<ChecklistInstance>> recentIncompleteInstances(
    String templateId, {
    Duration window = const Duration(hours: 18),
  }) async {
    final items = await (db.select(db.checklistItems)
          ..where((i) => i.templateId.equals(templateId)))
        .get();
    // No items means "complete" is meaningless (and would be vacuously
    // true below) — nothing to resume, fall through to the normal flow.
    if (items.isEmpty) return const [];
    final itemIds = items.map((i) => i.id).toSet();

    final cutoff = DateTime.now().subtract(window);
    final candidates = await (db.select(db.checklistInstances)
          ..where((i) =>
              i.templateId.equals(templateId) &
              i.createdAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
    if (candidates.isEmpty) return const [];

    final result = <ChecklistInstance>[];
    for (final instance in candidates) {
      final doneTicks = await (db.select(db.checklistTicks)
            ..where((t) =>
                t.instanceId.equals(instance.id) & t.isDone.equals(true)))
          .get();
      final doneIds = doneTicks.map((t) => t.itemId).toSet();
      final isComplete = itemIds.every(doneIds.contains);
      if (!isComplete) result.add(instance);
    }
    return result;
  }

  Stream<Map<String, ChecklistTick>> watchTicks(String instanceId) {
    final query = db.select(db.checklistTicks)
      ..where((t) => t.instanceId.equals(instanceId));
    return query.watch().map(
          (rows) => {for (final r in rows) r.itemId: r},
        );
  }

  // Round 11 (continued): keyed by "$instanceId:$itemId". `setTick` below
  // does the exact same check-then-insert-or-update shape that
  // `findOrCreateInstance` had before this round's fix — but this one is
  // reached far more often, since it's what runs on *every* checkbox tap
  // in the app's core everyday screen. `BigCheckboxTile` has no debounce
  // of its own (see its `InkWell.onTap: () => onChanged(!checked)`), and
  // its `checked` prop only flips once the DB write round-trips back
  // through `watchTicks`'s stream — so two rapid taps on the same row
  // (a sacristan quickly working down a checklist is exactly this) both
  // fire with the *same* target `done` value before either write lands.
  // Both calls could see `existing == null` and both insert a row for
  // the same item — and since drift's `getSingleOrNull()` throws if more
  // than one row matches, every later tap on that same item would then
  // throw instead of toggling, effectively bricking that one checkbox
  // until someone edits the database directly.
  //
  // Unlike `findOrCreateInstance` (where concurrent callers all want the
  // same *answer* and can safely share one in-flight result), two
  // concurrent `setTick` calls can carry genuinely different `done`
  // values (e.g. a fast tap-untap) and both must actually apply — so
  // sharing one Future would silently drop the second call's intent.
  // Instead, each call is chained onto the previous call *for the same
  // key*, so the check-then-write for a given item always runs
  // sequentially, one at a time, regardless of how close together the
  // taps land.
  final _tickLocks = <String, Future<void>>{};

  Future<void> setTick(
      String instanceId, String itemId, bool done, String? profileId) {
    final key = '$instanceId:$itemId';
    final previous = _tickLocks[key] ?? Future<void>.value();
    final chained = previous.then(
        (_) => _setTickUnlocked(instanceId, itemId, done, profileId));
    // Store a version that never itself throws — later calls only need
    // to know earlier work has *settled* before they run, not that it
    // succeeded; otherwise one failed write would permanently wedge
    // every subsequent tap on this item behind a broken chain.
    final settled = chained.then((_) {}, onError: (_) {});
    _tickLocks[key] = settled;
    settled.whenComplete(() {
      // Only clear this key if nothing newer has already replaced it —
      // a later call may have already installed its own `settled` future
      // here while this one was still running.
      if (identical(_tickLocks[key], settled)) _tickLocks.remove(key);
    });
    return chained;
  }

  Future<void> _setTickUnlocked(
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
