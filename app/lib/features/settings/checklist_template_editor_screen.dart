import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_session.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import 'admin_pin_screen.dart';

/// Round 11: the screen `checklist_detail_screen.dart`'s empty-state text
/// and `settings_screen.dart`'s "Admin PIN" subtitle have always pointed
/// sacristans toward ("Settings > Manage Checklist Templates") — but until
/// this round it did not exist. Lets an admin (PIN-gated, same as the
/// Reference Library) add new checklist templates and manage each
/// template's items.
///
/// Round 14+: whole-template deletion is now offered, as an archive/
/// restore toggle rather than a real delete — see the doc comment on
/// `ChecklistRepository.archiveTemplate` for why a hard delete still
/// isn't. This list shows archived templates too (greyed out, labeled),
/// since an admin managing templates needs to be able to find and
/// restore one — only the "start a checklist" flow
/// (`checklist_list_screen.dart`, via `watchTemplatesFor`) hides them.
class ChecklistTemplateEditorScreen extends StatelessWidget {
  const ChecklistTemplateEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChecklistRepository>();
    final session = context.watch<AdminSession>();
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.manageTemplatesTitle)),
      body: StreamBuilder<List<ChecklistTemplate>>(
        stream: repo.watchAllTemplates(),
        builder: (context, snap) {
          final templates = snap.data ?? const <ChecklistTemplate>[];
          if (templates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(loc.manageTemplatesEmptyState, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: templates.length,
            itemBuilder: (context, i) {
              final t = templates[i];
              final archived = t.archivedAt != null;
              return Opacity(
                opacity: archived ? 0.6 : 1.0,
                child: Card(
                  child: ListTile(
                    leading: Icon(t.phase == 'pre'
                        ? Icons.play_circle_outline
                        : Icons.stop_circle_outlined),
                    title: Text(t.name),
                    subtitle: Text(
                        '${_massTypeLabel(t.massType)} — ${t.phase == 'pre' ? 'Before Mass' : 'After Mass'}'
                        '${archived ? ' · Archived' : ''}'),
                    trailing: session.isUnlocked
                        ? IconButton(
                            icon: Icon(archived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined),
                            tooltip: archived
                                ? 'Restore template'
                                : 'Archive template',
                            onPressed: () =>
                                _confirmArchiveToggle(context, repo, t, archived),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TemplateItemsEditorScreen(template: t),
                    )),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(loc.manageTemplatesAddTemplate),
        onPressed: () => _showAddTemplateDialog(context, repo, session),
      ),
    );
  }

  Future<void> _confirmArchiveToggle(BuildContext context, ChecklistRepository repo,
      ChecklistTemplate t, bool archived) async {
    if (archived) {
      // Restoring is low-risk and immediately reversible right back from
      // this same screen — no confirmation needed, unlike archiving.
      await repo.unarchiveTemplate(t.id);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive this template?'),
        content: Text(
            '"${t.name}" will no longer be offered when starting a new '
            "checklist, but it isn't deleted — its items and every past "
            'checklist made from it stay exactly as they are, and you can '
            'restore it here at any time.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Archive')),
        ],
      ),
    );
    if (confirmed == true) {
      await repo.archiveTemplate(t.id);
    }
  }

  Future<void> _showAddTemplateDialog(
      BuildContext context, ChecklistRepository repo, AdminSession session) async {
    if (!session.isUnlocked) {
      AdminPinRequiredSnackBar.show(context);
      return;
    }
    final nameCtrl = TextEditingController();
    var massType = MassType.sunday;
    var phase = 'pre';
    // Same double-tap-creates-a-duplicate-row guard used throughout the
    // app's other "Add" dialogs.
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MassType>(
                  initialValue: massType,
                  decoration: const InputDecoration(labelText: 'Mass type'),
                  items: [
                    for (final m in MassType.values)
                      DropdownMenuItem(value: m, child: Text(_massTypeLabel(m))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => massType = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: phase,
                  decoration: const InputDecoration(labelText: 'Phase'),
                  items: const [
                    DropdownMenuItem(value: 'pre', child: Text('Before Mass')),
                    DropdownMenuItem(value: 'post', child: Text('After Mass')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => phase = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setState(() => submitting = true);
                      try {
                        await repo.addTemplate(
                          name: nameCtrl.text.trim(),
                          massType: massType,
                          phase: phase,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      } finally {
                        if (context.mounted) setState(() => submitting = false);
                      }
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

String _massTypeLabel(MassType t) {
  switch (t) {
    case MassType.sunday:
      return 'Sunday Mass';
    case MassType.weekday:
      return 'Weekday Mass';
    case MassType.funeral:
      return 'Funeral';
    case MassType.wedding:
      return 'Wedding';
    case MassType.baptism:
      return 'Baptism';
    case MassType.benediction:
      return 'Benediction / Adoration';
    case MassType.holyWeek:
      return 'Holy Week';
  }
}

/// Same fallback used by `checklist_detail_screen.dart` for rendering a
/// built-in item's label when no custom label is set.
String _itemLabel(ChecklistItem item) {
  if (item.labelCustom != null) return item.labelCustom!;
  final key = item.labelKey;
  if (key == null) return '(untitled item)';
  final spaced = key.replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Manages one template's items: add, delete, and reorder — all
/// admin-gated and race-safe via `ChecklistRepository`'s per-template
/// serialization (see repositories.dart).
class TemplateItemsEditorScreen extends StatelessWidget {
  final ChecklistTemplate template;
  const TemplateItemsEditorScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChecklistRepository>();
    final session = context.watch<AdminSession>();

    return Scaffold(
      appBar: AppBar(title: Text(template.name)),
      body: StreamBuilder<List<ChecklistItem>>(
        stream: repo.watchItems(template.id),
        builder: (context, snap) {
          final items = snap.data ?? const <ChecklistItem>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(AppLocalizations.of(context)!.templateItemsEmptyState,
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                child: ListTile(
                  title: Text(_itemLabel(item)),
                  subtitle: item.latinTerm != null ? Text(item.latinTerm!) : null,
                  trailing: session.isUnlocked
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              tooltip: 'Move up',
                              onPressed: i == 0
                                  ? null
                                  : () => repo.reorderItem(template.id, item.id, -1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              tooltip: 'Move down',
                              onPressed: i == items.length - 1
                                  ? null
                                  : () => repo.reorderItem(template.id, item.id, 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete item',
                              onPressed: () => repo.deleteItem(template.id, item.id),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addItem),
        onPressed: () => _showAddItemDialog(context, repo, session),
      ),
    );
  }

  Future<void> _showAddItemDialog(
      BuildContext context, ChecklistRepository repo, AdminSession session) async {
    if (!session.isUnlocked) {
      AdminPinRequiredSnackBar.show(context);
      return;
    }
    final labelCtrl = TextEditingController();
    final latinCtrl = TextEditingController();
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label'),
                  autofocus: true,
                ),
                TextField(
                  controller: latinCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Latin term (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (labelCtrl.text.trim().isEmpty) return;
                      setState(() => submitting = true);
                      try {
                        await repo.addItem(
                          templateId: template.id,
                          label: labelCtrl.text.trim(),
                          latinTerm: latinCtrl.text.trim().isEmpty
                              ? null
                              : latinCtrl.text.trim(),
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      } finally {
                        if (context.mounted) setState(() => submitting = false);
                      }
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
