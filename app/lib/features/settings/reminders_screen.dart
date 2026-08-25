import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/notifications_service.dart';
import '../../data/repositories.dart';

/// Create and cancel local reminders — feast-day prep, linen laundering,
/// supply restocking. Scheduling goes through [NotificationsService],
/// which posts a real on-device notification on Android/iOS/macOS/Linux;
/// on Windows (where the underlying plugin has no native implementation —
/// see that file's doc comment) the reminder is still saved and shown in
/// this list, just without a system toast.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReminderRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: StreamBuilder<List<Reminder>>(
        stream: repo.watchActive(),
        builder: (context, snap) {
          final reminders = snap.data ?? const <Reminder>[];
          if (reminders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No reminders yet. Add one for the next feast-day prep, '
                  'linen laundering, or restock.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reminders.length,
            itemBuilder: (context, i) {
              final r = reminders[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(r.title),
                  subtitle: Text(
                      '${_fmt(r.triggerAt)}${r.body != null ? ' · ${r.body}' : ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel reminder',
                    onPressed: () async {
                      await repo.cancel(r.id);
                      await NotificationsService.instance.cancel(r.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add reminder'),
        onPressed: () => _showAddDialog(context, repo),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, ReminderRepository repo) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    var when = DateTime.now().add(const Duration(days: 1));
    // Round 11: guards the "Add" button below against a double-tap, which
    // would otherwise create two separate `Reminder` rows and schedule two
    // separate OS-level notifications for what the sacristan intended as
    // one reminder — worse than most duplicate-row bugs, since cancelling
    // one from the Reminders list wouldn't stop the other from firing.
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Details (optional)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(_fmt(when)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: when,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date == null) return;
                  if (!context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(when),
                  );
                  if (time == null) return;
                  setState(() => when = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      setState(() => submitting = true);
                      try {
                        final id = await repo.add(
                          title: titleCtrl.text.trim(),
                          body: bodyCtrl.text.trim().isEmpty
                              ? null
                              : bodyCtrl.text.trim(),
                          triggerAt: when,
                        );
                        await NotificationsService.instance.scheduleReminder(
                          id: id,
                          title: titleCtrl.text.trim(),
                          body: bodyCtrl.text.trim().isEmpty
                              ? null
                              : bodyCtrl.text.trim(),
                          triggerAt: when,
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

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
