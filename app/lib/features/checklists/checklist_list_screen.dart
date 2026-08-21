import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import 'checklist_detail_screen.dart';

/// Lists every checklist template grouped by Mass type, and lets a
/// sacristan start (or resume) a checklist instance for a specific Mass —
/// including multiple simultaneous Masses in one day (multiple priests, a
/// large parish), each tracked independently via [MassRepository] and
/// [ChecklistRepository.findOrCreateInstance] so progress is never
/// silently duplicated or lost.
class ChecklistListScreen extends StatelessWidget {
  const ChecklistListScreen({super.key});

  static const _groupOrder = [
    MassType.sunday,
    MassType.weekday,
    MassType.holyWeek,
    MassType.funeral,
    MassType.wedding,
    MassType.baptism,
    MassType.benediction,
  ];

  String _label(MassType t) {
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

  @override
  Widget build(BuildContext context) {
    final massRepo = context.read<MassRepository>();
    final checklistRepo = context.read<ChecklistRepository>();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final type in _groupOrder) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(_label(type),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          StreamBuilder<List<ChecklistTemplate>>(
            stream: checklistRepo.watchTemplatesFor(type),
            builder: (context, snap) {
              final templates = snap.data ?? const [];
              if (templates.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('No templates yet.'),
                );
              }
              final loc = AppLocalizations.of(context)!;
              return Column(
                children: templates
                    .map((t) => Card(
                          child: ListTile(
                            leading: Icon(t.phase == 'pre'
                                ? Icons.play_circle_outline
                                : Icons.stop_circle_outlined),
                            title: Text(t.name),
                            subtitle: Text(
                                t.phase == 'pre' ? loc.beforeMass : loc.afterMass),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openTemplate(context, massRepo, checklistRepo, type, t),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _openTemplate(BuildContext context, MassRepository massRepo,
      ChecklistRepository checklistRepo, MassType type, ChecklistTemplate t) async {
    final todaysMasses = await massRepo.todaysMasses(type);
    if (!context.mounted) return;

    String? massId;
    if (todaysMasses.isEmpty) {
      // Nothing to choose between yet — create today's first Mass of this
      // type with a sensible default label and go straight in, so a
      // single-Mass parish never sees an extra tap for the common case.
      massId = await massRepo.create(type, t.name.replaceAll(RegExp(r' — .*'), ''));
    } else if (todaysMasses.length == 1) {
      massId = todaysMasses.first.id;
    } else {
      massId = await _pickMass(context, massRepo, type, todaysMasses);
      if (massId == null) return; // user cancelled
    }

    final instanceId = await checklistRepo.findOrCreateInstance(massId, t.id);
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChecklistDetailScreen(
          instanceId: instanceId,
          templateId: t.id,
          title: t.name,
        ),
      ));
    }
  }

  Future<String?> _pickMass(BuildContext context, MassRepository massRepo,
      MassType type, List<Mass> existing) async {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Which Mass?'),
        children: [
          for (final m in existing)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(m.id),
              child: Text(m.label),
            ),
          SimpleDialogOption(
            onPressed: () async {
              final label = await _promptNewMassLabel(context);
              if (label == null || label.trim().isEmpty) return;
              final id = await massRepo.create(type, label.trim());
              if (context.mounted) Navigator.of(context).pop(id);
            },
            child: const Row(children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text('New Mass…'),
            ]),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptNewMassLabel(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this Mass'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. "10:30 AM" or "Fr. Smith\'s Mass"'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
