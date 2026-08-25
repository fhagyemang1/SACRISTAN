import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';

/// Free-text notes attached to a specific date (the common case — "order
/// more purificators before Palm Sunday"). The data model also supports
/// notes linked to a specific Mass or checklist item (`linkedType` in the
/// Notes table); wiring an "add note" entry point from those screens is
/// the same repository call with a different `linkedType`/`linkedId`.
///
/// For a reminder with an actual notification/alarm attached (rather than
/// a plain note), see Settings > Reminders (`features/settings/reminders_screen.dart`),
/// which schedules through `flutter_local_notifications` via
/// `data/notifications_service.dart`.
class NotesScreen extends StatefulWidget {
  final DateTime date;
  const NotesScreen({super.key, required this.date});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _controller = TextEditingController();
  // Round 11: guards the "Add note" button below against a double-tap
  // sending the same note text twice as two separate rows before the
  // first `await repo.addForDate(...)` completes and `_controller.clear()`
  // runs — the same duplicate-row shape found and fixed across the
  // app's dialog-based "Add" buttons this round.
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<NotesRepository>();
    return Scaffold(
      appBar: AppBar(title: Text('Notes — ${_fmt(widget.date)}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: repo.watchForDate(widget.date),
              builder: (context, snap) {
                final notes = snap.data ?? const <Note>[];
                if (notes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No notes for this date yet.'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final n = notes[i];
                    return Card(
                      child: ListTile(
                        title: Text(n.body),
                        subtitle: Text(_fmt(n.createdAt)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Add a note for this date…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            setState(() => _submitting = true);
                            try {
                              await repo.addForDate(widget.date, text);
                              _controller.clear();
                            } finally {
                              if (mounted) setState(() => _submitting = false);
                            }
                          },
                    child: Text(AppLocalizations.of(context)!.addNote),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
