import 'package:flutter/material.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/repositories.dart';

/// Lets a parish or diocese add its own fixed-date celebrations — a
/// patronal feast, a diocesan saint, a parish anniversary — on top of the
/// bundled General Roman Calendar. Entirely offline: entries are typed in
/// here (or, for a batch of entries, could be parsed from a file the user
/// picks on-device — the parsing step is the only part that would differ
/// for an "import" flow; both paths end by calling the same
/// [CalendarRepository.addLocalEntry]).
class LocalCalendarEditorScreen extends StatelessWidget {
  const LocalCalendarEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalendarRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Parish / Diocesan Calendar')),
      body: StreamBuilder<List<LocalCalendarEntryRow>>(
        stream: repo.watchLocalEntries(),
        builder: (context, snap) {
          final entries = snap.data ?? const <LocalCalendarEntryRow>[];
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No local entries yet.\nAdd your patronal feast, a diocesan '
                  'saint, or your parish anniversary — it will show up on the '
                  'Dashboard and Calendar automatically, every year, fully '
                  'offline.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              return Card(
                child: ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                      '${_monthName(e.month)} ${e.day} · ${e.rank} · ${e.color}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, repo, e),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
        onPressed: () => _showAddDialog(context, repo),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CalendarRepository repo,
      LocalCalendarEntryRow entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('"${entry.name}" will be removed from your parish '
            'calendar.'),
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
      await repo.deleteLocalEntry(entry.id);
    }
  }

  Future<void> _showAddDialog(BuildContext context, CalendarRepository repo) async {
    final nameCtrl = TextEditingController();
    final latinCtrl = TextEditingController();
    var month = 1;
    var day = 1;
    var rank = CelebrationRank.memorial;
    var color = LiturgicalColor.white;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add local calendar entry'),
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
                TextField(
                  controller: latinCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Latin name (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: month,
                        decoration: const InputDecoration(labelText: 'Month'),
                        items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                                value: i + 1, child: Text(_monthName(i + 1)))),
                        onChanged: (v) => setState(() => month = v ?? month),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: day,
                        decoration: const InputDecoration(labelText: 'Day'),
                        items: List.generate(
                            31,
                            (i) => DropdownMenuItem(
                                value: i + 1, child: Text('${i + 1}'))),
                        onChanged: (v) => setState(() => day = v ?? day),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CelebrationRank>(
                  initialValue: rank,
                  decoration: const InputDecoration(labelText: 'Rank'),
                  items: const [
                    CelebrationRank.solemnity,
                    CelebrationRank.feast,
                    CelebrationRank.memorial,
                    CelebrationRank.optionalMemorial,
                  ]
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                      .toList(),
                  onChanged: (v) => setState(() => rank = v ?? rank),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LiturgicalColor>(
                  initialValue: color,
                  decoration: const InputDecoration(labelText: 'Color'),
                  items: LiturgicalColor.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => color = v ?? color),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await repo.addLocalEntry(
                  month: month,
                  day: day,
                  name: nameCtrl.text.trim(),
                  latinName:
                      latinCtrl.text.trim().isEmpty ? null : latinCtrl.text.trim(),
                  rank: rank,
                  color: color,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December'
];
String _monthName(int m) => _months[m - 1];
