import 'package:flutter/material.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart';
import 'package:provider/provider.dart';

import '../../data/admin_session.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import 'admin_pin_screen.dart';

/// Lets a parish or diocese add its own fixed-date celebrations — a
/// patronal feast, a diocesan saint, a parish anniversary — on top of the
/// bundled General Roman Calendar. Entirely offline: entries are typed in
/// here (or, for a batch of entries, could be parsed from a file the user
/// picks on-device — the parsing step is the only part that would differ
/// for an "import" flow; both paths end by calling the same
/// [CalendarRepository.addLocalEntry]).
///
/// Round 13+ fix: add/delete here used to have no [AdminSession] gate at
/// all, unlike every other Settings screen that edits shared, parish-wide
/// configuration data (`checklist_template_editor_screen.dart`,
/// `profiles_screen.dart`, the Reference Library). These entries feed
/// `CalendarRepository.dayFor()` on every device, so an unlocked-out
/// volunteer could otherwise silently add junk entries or delete the
/// parish's genuine patronal-feast entry. Gated the same way those other
/// screens are: check `AdminSession.isUnlocked` first and show
/// [AdminPinRequiredSnackBar] instead of performing the action.
class LocalCalendarEditorScreen extends StatelessWidget {
  const LocalCalendarEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalendarRepository>();
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.localCalendarTitle)),
      body: StreamBuilder<List<LocalCalendarEntryRow>>(
        stream: repo.watchLocalEntries(),
        builder: (context, snap) {
          final entries = snap.data ?? const <LocalCalendarEntryRow>[];
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  loc.localCalendarEmptyState,
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
        label: Text(loc.localCalendarAddEntry),
        onPressed: () => _showAddDialog(context, repo),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CalendarRepository repo,
      LocalCalendarEntryRow entry) async {
    final session = context.read<AdminSession>();
    if (!session.isUnlocked) {
      AdminPinRequiredSnackBar.show(context);
      return;
    }
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
    final session = context.read<AdminSession>();
    if (!session.isUnlocked) {
      AdminPinRequiredSnackBar.show(context);
      return;
    }
    final nameCtrl = TextEditingController();
    final latinCtrl = TextEditingController();
    var month = 1;
    var day = 1;
    var rank = CelebrationRank.memorial;
    var color = LiturgicalColor.white;
    // Round 11: see the identical guard elsewhere (reminders_screen.dart,
    // inventory_screen.dart, etc.) — prevents a double-tap on "Add" from
    // creating two local-calendar-entry rows before the first `await`
    // completes.
    var submitting = false;

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
                        onChanged: (v) => setState(() {
                          if (v == null) return;
                          month = v;
                          // Round 11 fix: the Day dropdown below used to
                          // always offer 1-31 regardless of month, with no
                          // validation anywhere (the repository/database
                          // accept any int). That let an admin save an
                          // entry like "April 31" or "February 30" — it
                          // would insert without error, then silently
                          // never appear on the Dashboard or Calendar on
                          // any real date, ever, directly contradicting
                          // this screen's own promise that an added entry
                          // "will show up ... automatically, every year."
                          // Clamping here (and filtering the Day dropdown
                          // below to the selected month's real length)
                          // makes an invalid date impossible to select in
                          // the first place, rather than merely rejecting
                          // it on submit.
                          final maxDay = _daysInMonth[month - 1];
                          if (day > maxDay) day = maxDay;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        // Keyed on `month`: `DropdownButtonFormField`'s
                        // `initialValue` (like other Form fields) is only
                        // consulted on this widget's first build, not on
                        // every rebuild — so clamping `day` above wouldn't,
                        // by itself, update what's visibly selected here
                        // once the user has already interacted with this
                        // dropdown once. A `ValueKey` on `month` forces
                        // Flutter to treat this as a brand-new widget
                        // instance whenever the month changes, so the
                        // freshly-clamped `day` and the freshly-filtered
                        // item list are both picked up correctly.
                        key: ValueKey(month),
                        initialValue: day,
                        decoration: const InputDecoration(labelText: 'Day'),
                        items: List.generate(
                            _daysInMonth[month - 1],
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
              onPressed: submitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setState(() => submitting = true);
                      try {
                        await repo.addLocalEntry(
                          month: month,
                          day: day,
                          name: nameCtrl.text.trim(),
                          latinName: latinCtrl.text.trim().isEmpty
                              ? null
                              : latinCtrl.text.trim(),
                          rank: rank,
                          color: color,
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

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December'
];
String _monthName(int m) => _months[m - 1];

/// Feb is given 29 (not 28) deliberately: a parish entering a genuine
/// Feb-29 observance (rare, but real) should still be able to pick it —
/// the calendar engine already handles a Feb-29 local entry correctly by
/// simply never matching it in a non-leap year, the same way any other
/// date-matching works. Every other month's real day count is used as-is
/// so no invalid date (Feb 30, Apr 31, ...) can be selected at all.
const _daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
