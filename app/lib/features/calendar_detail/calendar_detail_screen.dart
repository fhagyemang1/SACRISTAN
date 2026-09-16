import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/color_chip.dart';

/// Lets a sacristan tap any date — past or years into the future — and see
/// its full liturgical description. Entirely offline: there is no limit on
/// how far forward or back this can be queried, since the underlying
/// engine computes on demand rather than reading a finite bundled table.
class CalendarDetailScreen extends StatefulWidget {
  final DateTime initialDate;
  // Round 13+ fix: this screen used to have no way to report its own
  // internal date navigation (prev/next arrows, the date picker) back up
  // to AppShell, which only ever updated `_selectedDate` from
  // DashboardScreen's week-row taps. That left AppShell's "Notes" app-bar
  // button always attaching a new note to whatever date the Dashboard was
  // last opened from, silently wrong once the sacristan had navigated
  // elsewhere in this screen (e.g. browse forward to Christmas Eve, tap
  // Notes, and the note saves against today instead of Christmas Eve).
  final ValueChanged<DateTime>? onDateChanged;
  const CalendarDetailScreen(
      {super.key, required this.initialDate, this.onDateChanged});

  @override
  State<CalendarDetailScreen> createState() => _CalendarDetailScreenState();
}

class _CalendarDetailScreenState extends State<CalendarDetailScreen> {
  late DateTime _date;
  late Future<LiturgicalDay> _day;

  @override
  void initState() {
    super.initState();
    _date = DateTime(
        widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    _load();
  }

  @override
  void didUpdateWidget(covariant CalendarDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDate(oldWidget.initialDate, widget.initialDate)) {
      _date = DateTime(widget.initialDate.year, widget.initialDate.month,
          widget.initialDate.day);
      _load();
    }
  }

  void _load() {
    setState(() {
      _day = context.read<CalendarRepository>().dayFor(_date);
    });
  }

  void _shift(int days) {
    // Round 13+ fix: `.add(Duration(days: days))` adds an exact 24-hour
    // offset, not "one calendar day" — Dart's own docs warn this doesn't
    // correct for DST. On the day local clocks "fall back" (25 real hours
    // long), adding exactly 24 hours to that day's midnight lands at
    // 23:00 the *same* calendar day, so tapping "next day" once appeared
    // to do nothing. Building a new `DateTime` from year/month/day+days
    // instead lets the constructor normalize the out-of-range day field
    // (the same way `DateTime(y, m, 32)` rolls into next month), which is
    // correct regardless of DST.
    _date = DateTime(_date.year, _date.month, _date.day + days);
    _load();
    widget.onDateChanged?.call(_date);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // No firstDate/lastDate ceiling on the future beyond what the picker
      // widget itself needs — the calendar engine has no limit. The picker
      // needs *some* bound, so a generous +/- 100 years is used rather
      // than an arbitrary near-term cutoff.
      firstDate: DateTime(_date.year - 100),
      lastDate: DateTime(_date.year + 100),
    );
    if (picked != null) {
      _date = picked;
      _load();
      widget.onDateChanged?.call(_date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.navCalendar),
        actions: [
          IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Jump to a date',
              onPressed: _pickDate),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 32),
                onPressed: () => _shift(-1),
                tooltip: 'Previous day',
              ),
              Text(_formatFullDate(context, _date),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 32),
                onPressed: () => _shift(1),
                tooltip: 'Next day',
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<LiturgicalDay>(
              future: _day,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final day = snap.data!;
                final swatch = swatchFor(day.color,
                    dark: Theme.of(context).brightness == Brightness.dark);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: swatch.background,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day.primary.name,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: swatch.foreground)),
                            if (day.primary.latinName != null)
                              Text(day.primary.latinName!,
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: swatch.foreground.withValues(alpha: 0.85))),
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              LiturgicalColorChip(
                                  color: day.color, goldPermitted: day.goldPermitted),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoTile(
                        label: 'Season', value: seasonLabel(context, day.season)),
                    _InfoTile(
                        label: 'Week of Season', value: '${day.weekOfSeason}'),
                    _InfoTile(label: 'Rank', value: rankLabel(context, day.rank)),
                    if (day.sundayCycle != null)
                      _InfoTile(
                          label: 'Sunday Lectionary Cycle',
                          value: day.sundayCycle!.name.toUpperCase()),
                    if (day.weekdayCycle != null)
                      _InfoTile(
                          label: 'Weekday Lectionary Cycle',
                          value: day.weekdayCycle!.name.toUpperCase()),
                    if (day.celebrations.length > 1) ...[
                      const SizedBox(height: 16),
                      Text('All celebrations offered today',
                          style: Theme.of(context).textTheme.titleMedium),
                      for (final c in day.celebrations)
                        ListTile(
                          leading: const Icon(Icons.church_outlined),
                          title: Text(c.name),
                          subtitle: Text(
                              '${rankLabel(context, c.rank)} — from ${_sourceLabel(c.source)}'),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _sourceLabel(CalendarSource s) {
  switch (s) {
    case CalendarSource.generalRomanCalendar:
      return 'General Roman Calendar';
    case CalendarSource.computed:
      return 'computed';
    case CalendarSource.localSupplement:
      return 'parish/diocesan calendar';
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// Round 13+ fix: this used to be hardcoded English weekday/month name
// arrays — the one piece of text on this screen that never went through
// AppLocalizations, unlike the app-bar title and the season/rank rows
// (which delegate to seasonLabel()/rankLabel()). Switched app language to
// French or Spanish and this date header stayed in English while
// everything around it correctly translated. `intl`'s `DateFormat`
// (already a dependency — see pubspec.yaml) produces a correctly
// translated, locale-formatted full date for any locale this app ships
// (en/fr/es) with no hand-maintained name arrays or new ARB keys needed.
String _formatFullDate(BuildContext context, DateTime d) =>
    DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(d);
