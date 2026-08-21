import 'package:flutter/material.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../common/color_chip.dart';

/// The screen a sacristan sees first, and the one the whole app is built
/// around: today's liturgical color/rank/season, in as few taps (zero) as
/// possible, plus the coming week so vestment and linen prep can be
/// planned ahead of time.
class DashboardScreen extends StatefulWidget {
  final ValueChanged<DateTime> onOpenDate;
  const DashboardScreen({super.key, required this.onOpenDate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<LiturgicalDay> _today;
  late Future<List<LiturgicalDay>> _week;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<CalendarRepository>();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    _today = repo.dayFor(startOfToday);
    _week = repo.weekFrom(startOfToday);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(_load),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<LiturgicalDay>(
            future: _today,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _TodayCard(day: snap.data!);
            },
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.thisWeek,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          FutureBuilder<List<LiturgicalDay>>(
            future: _week,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                children: snap.data!
                    .map((d) => _WeekRow(day: d, onTap: () => widget.onOpenDate(d.date)))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final LiturgicalDay day;
  const _TodayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final swatch = swatchFor(day.color,
        dark: Theme.of(context).brightness == Brightness.dark);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [swatch.background, swatch.background.withValues(alpha: 0.75)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatFullDate(day.date),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: swatch.foreground.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day.primary.name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: swatch.foreground,
                height: 1.15,
              ),
            ),
            if (day.primary.latinName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  day.primary.latinName!,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: swatch.foreground.withValues(alpha: 0.85),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                LiturgicalColorChip(
                    color: day.color, goldPermitted: day.goldPermitted),
                _Pill(text: rankLabel(context, day.rank), fg: swatch.foreground),
                _Pill(text: seasonLabel(context, day.season), fg: swatch.foreground),
                if (day.sundayCycle != null)
                  _Pill(
                      text: 'Sunday Cycle ${day.sundayCycle!.name.toUpperCase()}',
                      fg: swatch.foreground),
                if (day.weekdayCycle != null)
                  _Pill(
                      text: 'Weekday Cycle ${day.weekdayCycle!.name.toUpperCase()}',
                      fg: swatch.foreground),
              ],
            ),
            if (day.celebrations.length > 1) ...[
              const SizedBox(height: 16),
              Text('Also available today:',
                  style: TextStyle(
                      color: swatch.foreground.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600)),
              for (final c in day.celebrations.skip(1))
                Text('• ${c.name}',
                    style: TextStyle(color: swatch.foreground.withValues(alpha: 0.85))),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color fg;
  const _Pill({required this.text, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: fg.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final LiturgicalDay day;
  final VoidCallback onTap;
  const _WeekRow({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final swatch = swatchFor(day.color,
        dark: Theme.of(context).brightness == Brightness.dark);
    final isToday = _isSameDate(day.date, DateTime.now());
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: swatch.background,
          child: Text(
            '${day.date.day}',
            style: TextStyle(color: swatch.foreground, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          day.primary.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: isToday ? FontWeight.w800 : FontWeight.w600),
        ),
        subtitle: Text('${_weekdayName(day.date)} · ${rankLabel(context, day.rank)}'),
        trailing: isToday
            ? const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('TODAY', style: TextStyle(fontWeight: FontWeight.w800)),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December'
];

String _weekdayName(DateTime d) => _weekdayNames[d.weekday - 1];
String _formatFullDate(DateTime d) =>
    '${_weekdayName(d)}, ${_monthNames[d.month - 1]} ${d.day}, ${d.year}';
