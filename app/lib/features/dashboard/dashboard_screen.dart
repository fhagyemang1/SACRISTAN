import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
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

/// Test-only escape hatch: set to `true` by `widget_test.dart` before it
/// pumps [DashboardScreen] (directly or via `SacristanApp`/`AppShell`), and
/// reset to `false` in that test's teardown.
bool debugDisableMidnightRefresh = false;

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late Future<LiturgicalDay> _today;
  late Future<List<LiturgicalDay>> _week;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      setState(_load);
    }
  }

  void _scheduleMidnightRefresh() {
    if (debugDisableMidnightRefresh) return;
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(delay, _onMidnightTick);
  }

  void _onMidnightTick() {
    if (!mounted) return;
    setState(_load);
    _scheduleMidnightRefresh();
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
          // Dashboard-native "needs attention" card: combines overdue
          // reminders and low-stock inventory items, both read straight
          // from their existing tables. Needs no OS notification
          // permission, no exact-alarm grant, and no OEM battery/
          // autostart allowance — it just checks current data whenever
          // this screen is open, which is reliable on every device.
          const SizedBox(height: 16),
          const _NeedsAttentionSection(),
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

/// One combined "needs attention" card covering two independent sources:
/// overdue reminders (Reminders table) and low-stock inventory items
/// (InventoryItems.lowStockFlag). Both stream from the database directly,
/// so this works even when phone notifications never fire — as long as
/// the sacristan opens the app, both show up here.
class _NeedsAttentionSection extends StatelessWidget {
  const _NeedsAttentionSection();

  @override
  Widget build(BuildContext context) {
    final reminderRepo = context.read<ReminderRepository>();
    final inventoryRepo = context.read<InventoryRepository>();

    return StreamBuilder<List<Reminder>>(
      stream: reminderRepo.watchActive(),
      builder: (context, reminderSnap) {
        return StreamBuilder<List<InventoryItem>>(
          stream: inventoryRepo.watchLowStock(),
          builder: (context, stockSnap) {
            final now = DateTime.now();
            final dueReminders = (reminderSnap.data ?? const <Reminder>[])
                .where((r) => !r.triggerAt.isAfter(now))
                .toList()
              ..sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
            final lowStock = stockSnap.data ?? const <InventoryItem>[];

            if (dueReminders.isEmpty && lowStock.isEmpty) {
              return const SizedBox.shrink();
            }

            return Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.priority_high,
                            color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Needs attention (${dueReminders.length + lowStock.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final r in dueReminders)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_active, size: 18,
                                color: Theme.of(context).colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                  if (r.body != null)
                                    Text(
                                      r.body!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => reminderRepo.cancel(r.id),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      ),
                    for (final item in lowStock)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 18,
                                color: Theme.of(context).colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item.name} — low stock (${item.quantity} left)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
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