import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/admin_session.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../common/sms_helper.dart';
import '../settings/admin_pin_screen.dart';

/// Vestment / vessel / linen inventory: list grouped by category, add,
/// edit, delete, toggle a manual low-stock flag, and export a low-stock
/// shopping list as CSV (no internet-based reordering — the export is a
/// file the sacristan can hand to whoever places the order, or attach to
/// a text/email once back online).
///
/// Editing and deleting are gated behind [AdminSession] so a volunteer
/// using the app before Mass can't accidentally wipe out inventory data —
/// see admin_pin_screen.dart for the unlock flow this checks.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<InventoryRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sms_outlined),
            tooltip: 'Text a low-stock alert to a parish contact',
            onPressed: () => _textLowStockAlert(context, repo),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export low-stock shopping list (CSV)',
            onPressed: () => _exportLowStockCsv(context, repo),
          ),
        ],
      ),
      body: StreamBuilder<List<InventoryItem>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          final items = snap.data ?? const <InventoryItem>[];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No inventory items yet.\nTap + to add a chasuble, chalice, '
                  'box of purificators, or anything else you track.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final grouped = <InventoryCategory, List<InventoryItem>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(_categoryLabel(entry.key),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                for (final item in entry.value)
                  Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text([
                        if (item.color != null) item.color!,
                        if (item.condition != null) item.condition!,
                        if (item.storageLocation != null) 'at ${item.storageLocation}',
                      ].join(' · ')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.lowStockFlag)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            ),
                          Text('×${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      onTap: () => _showItemDialog(context, repo, existing: item),
                      onLongPress: () => repo.upsert(InventoryItemsCompanion(
                        id: Value(item.id),
                        lowStockFlag: Value(!item.lowStockFlag),
                      )),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addItem),
        onPressed: () => _showItemDialog(context, repo),
      ),
    );
  }

  Future<void> _textLowStockAlert(BuildContext context, InventoryRepository repo) async {
    final items = await repo.watchLowStock().first;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing is flagged low-stock right now.')),
      );
      return;
    }
    final contactRepo = context.read<ContactRepository>();
    final contacts = await contactRepo.watchAll().first;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'No parish contacts yet — add one in Settings > Low-Stock Text Alerts.')),
      );
      return;
    }
    if (!context.mounted) return;
    final chosen = await showDialog<Contact>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Text which contact?'),
        children: contacts
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(c),
                  child: Text('${c.name} (${c.role.name})'),
                ))
            .toList(),
      ),
    );
    if (chosen == null) return;
    final summary = items.map((i) => '- ${i.name} (×${i.quantity})').join('\n');
    await openSmsComposer(
      phone: chosen.phone,
      body: 'SACRISTAN low-stock alert:\n$summary',
    );
  }

  Future<void> _exportLowStockCsv(BuildContext context, InventoryRepository repo) async {
    final items = await repo.watchLowStock().first;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing is flagged low-stock right now.')),
      );
      return;
    }
    final rows = <List<String>>[
      ['Category', 'Name', 'Quantity on Hand', 'Storage Location', 'Notes'],
      for (final i in items)
        [
          _categoryLabel(i.category),
          i.name,
          '${i.quantity}',
          i.storageLocation ?? '',
          i.notes ?? '',
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path,
        'sacristan_shopping_list_${DateTime.now().toIso8601String().substring(0, 10)}.csv'));
    await file.writeAsString(csv);
    if (context.mounted) {
      // share_plus's API shifted in 11.0.0: the static `Share` class (and
      // `Share.shareXFiles`) is deprecated in favor of
      // `SharePlus.instance.share(ShareParams(...))`. pubspec.yaml pins
      // `share_plus: ^13.3.0` (bumped in round 9 to resolve a real
      // version-solving conflict with `drift`'s `web` dependency), and
      // round 9's first successful `flutter analyze` run flagged the old
      // call here (`deprecated_member_use`) among its 42 issues — using
      // the current, non-deprecated API instead.
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: 'SACRISTAN low-stock shopping list',
      ));
    }
  }

  Future<void> _showItemDialog(BuildContext context, InventoryRepository repo,
      {InventoryItem? existing}) async {
    final session = context.read<AdminSession>();
    if (existing != null && !session.isUnlocked) {
      AdminPinRequiredSnackBar.show(context);
      return;
    }

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final locationCtrl = TextEditingController(text: existing?.storageLocation ?? '');
    final conditionCtrl = TextEditingController(text: existing?.condition ?? '');
    var category = existing?.category ?? InventoryCategory.vessel;
    var quantity = existing?.quantity ?? 1;
    var lowStock = existing?.lowStockFlag ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add inventory item' : 'Edit inventory item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InventoryCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: InventoryCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c))))
                      .toList(),
                  onChanged: (v) => setState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Storage location'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conditionCtrl,
                  decoration: const InputDecoration(labelText: 'Condition (e.g. good, worn)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Quantity'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Decrease quantity',
                      onPressed: () => setState(() => quantity = (quantity - 1).clamp(0, 999)),
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Increase quantity',
                      onPressed: () => setState(() => quantity += 1),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Flag as low stock'),
                  value: lowStock,
                  onChanged: (v) => setState(() => lowStock = v),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete this item?'),
                      content: Text('"${existing.name}" will be removed.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await repo.delete(existing.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await repo.upsert(InventoryItemsCompanion(
                  id: existing != null ? Value(existing.id) : const Value.absent(),
                  category: Value(category),
                  name: Value(nameCtrl.text.trim()),
                  storageLocation: Value(
                      locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim()),
                  condition: Value(
                      conditionCtrl.text.trim().isEmpty ? null : conditionCtrl.text.trim()),
                  quantity: Value(quantity),
                  lowStockFlag: Value(lowStock),
                ));
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(InventoryCategory c) {
  switch (c) {
    case InventoryCategory.chasuble:
      return 'Chasubles';
    case InventoryCategory.stole:
      return 'Stoles';
    case InventoryCategory.alb:
      return 'Albs';
    case InventoryCategory.linen:
      return 'Linens';
    case InventoryCategory.vessel:
      return 'Vessels';
    case InventoryCategory.candle:
      return 'Candles';
    case InventoryCategory.incense:
      return 'Incense';
    case InventoryCategory.hosts:
      return 'Hosts';
    case InventoryCategory.wine:
      return 'Wine';
    case InventoryCategory.other:
      return 'Other';
  }
}
