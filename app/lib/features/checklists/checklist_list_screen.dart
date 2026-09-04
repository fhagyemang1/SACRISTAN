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
class ChecklistListScreen extends StatefulWidget {
  const ChecklistListScreen({super.key});

  @override
  State<ChecklistListScreen> createState() => _ChecklistListScreenState();
}

class _ChecklistListScreenState extends State<ChecklistListScreen> {
  // Round 11: guards against a real duplication bug. `_openTemplate` below
  // does up to three sequential `await`s (todaysMasses lookup, possibly
  // creating today's first Mass of this type, then findOrCreateInstance)
  // before it ever navigates away from this list — and nothing disabled
  // the `ListTile` in between. A sacristan double-tapping a checklist
  // template (an easy, common thing to do while hurrying before Mass)
  // could have both taps see `todaysMasses.isEmpty` as still true and
  // both call `massRepo.create(...)`, silently creating two separate
  // "Mass" rows for the same day/type — each then getting its own
  // independently-progressing checklist instance. The list's own doc
  // comment above already claimed progress is "never silently
  // duplicated" before this fix made that actually true.
  bool _opening = false;

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
                            // `_opening` guard (see the class-level comment)
                            // — ignore taps while a prior tap's Mass/
                            // instance lookup-or-create is still in flight.
                            onTap: _opening
                                ? null
                                : () => _openTemplate(context, massRepo, checklistRepo, type, t),
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
    setState(() => _opening = true);
    try {
      final todaysMasses = await massRepo.todaysMasses(type);
      if (!context.mounted) return;

      String? massId;
      String? instanceId;
      if (todaysMasses.isEmpty) {
        // Round 12: before assuming this is a genuinely new Mass, check for
        // a checklist of this exact template that's still open from
        // recently — `todaysMasses` above keys strictly off calendar date,
        // so a checklist begun before midnight (an Easter Vigil that runs
        // past 12:00 AM is the textbook case, but simply not finishing
        // before the day turns over is enough) would otherwise find no
        // Mass "today" and silently start a brand-new, blank checklist,
        // orphaning the real one's ticks in SQLite. See
        // `ChecklistRepository.recentIncompleteInstances` for exactly what
        // "recent and incomplete" means, and why keying off the template
        // (not massType) here can't collide with the multi-Mass picker
        // below.
        final resumable = await checklistRepo.recentIncompleteInstances(t.id);
        if (!context.mounted) return;
        if (resumable.isEmpty) {
          // Nothing to resume and nothing to choose between yet — create
          // today's first Mass of this type with a sensible default label
          // and go straight in, so a single-Mass parish never sees an
          // extra tap for the common case.
          massId = await massRepo.create(type, t.name.replaceAll(RegExp(r' — .*'), ''));
        } else {
          instanceId = resumable.first.id;
        }
      } else if (todaysMasses.length == 1) {
        massId = todaysMasses.first.id;
      } else {
        massId = await _pickMass(context, massRepo, type, todaysMasses);
        if (massId == null) return; // user cancelled
      }

      // Written this way (rather than `instanceId ??= await ...`) so the
      // value passed to `ChecklistDetailScreen` below is statically
      // non-nullable without relying on flow-analysis promotion through a
      // `??=` — `findOrCreateInstance` is only actually awaited when
      // `instanceId` is still null, since `??` short-circuits.
      final resolvedInstanceId =
          instanceId ?? await checklistRepo.findOrCreateInstance(massId!, t.id);
      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChecklistDetailScreen(
            instanceId: resolvedInstanceId,
            templateId: t.id,
            title: t.name,
          ),
        ));
      }
    } finally {
      // Re-enable the list whether this run succeeded, the user cancelled
      // the "which Mass?" picker, or (in the `else` branches above) we
      // returned early — every path above passes through here. Guarded on
      // `mounted` (the State's own flag, not the possibly-stale local
      // `context` parameter) since the whole screen could have been popped
      // while `_openTemplate` was still awaiting.
      if (mounted) setState(() => _opening = false);
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
