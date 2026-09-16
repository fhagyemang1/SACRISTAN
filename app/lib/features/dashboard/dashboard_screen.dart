import 'dart:async';

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

/// Test-only escape hatch: set to `true` by `widget_test.dart` before it
/// pumps [DashboardScreen] (directly or via `SacristanApp`/`AppShell`), and
/// reset to `false` in that test's teardown.
///
/// Round-13 follow-up: `flutter test` runs on a virtual clock
/// (`FakeAsync`), so the real self-rescheduling midnight `Timer` below —
/// due many hours out — just sits in `FakeAsync.pendingTimers` for the
/// rest of the test process. The first fix attempt (swap in
/// `SizedBox.shrink()` and `pump()` before the test body returns, so
/// `dispose()` cancels the Timer before flutter_test's own end-of-test
/// "!timersPending" check runs) still failed identically on rerun — the
/// schedule-then-cancel-before-teardown shape isn't reliable here. So
/// instead of relying on disposal timing at all, the test disables
/// scheduling at the source: with this flag set, `_scheduleMidnightRefresh`
/// is a no-op, so no Timer is ever created for the check to trip on.
bool debugDisableMidnightRefresh = false;

// Round 12: `AppShell` hosts every tab in an `IndexedStack` (see
// `features/common/app_shell.dart`), so this State is created once and
// never disposed for the app's entire session — switching tabs does not
// re-run `initState`. Without anything below, "today" was only ever
// (re)computed at that one `initState` call and on a manual pull-to-refresh,
// so a device left open/running past local midnight — a real scenario for
// a sacristy desktop/tablet, or a phone just left unlocked overnight — kept
// showing yesterday's liturgical color/rank/season indefinitely, which
// defeats the entire point of this being the zero-tap "today" screen.
// Two independent triggers cover the two ways that staleness actually
// happens: `didChangeAppLifecycleState` catches resuming from the
// background (including when the OS suspended this app's timers while
// backgrounded, which could cause the Timer below to fire late or not at
// all until resume) and the self-rescheduling `Timer` catches the app
// simply staying in the foreground/running headless across midnight.
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

  /// Schedules a one-shot `Timer` for just after the next local midnight,
  /// which reloads "today" and then reschedules itself for the midnight
  /// after that. Deliberately a self-rescheduling one-shot rather than a
  /// single `Timer.periodic(Duration(days: 1))`: a fixed 24-hour period
  /// would drift off local midnight the very first time a DST transition
  /// adds or removes an hour, whereas recomputing "next midnight" fresh
  /// each time never can.
  void _scheduleMidnightRefresh() {
    if (debugDisableMidnightRefresh) return;
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // A one-second cushion so this fires just after midnight rather than
    // racing it — firing a moment late is harmless, firing a moment early
    // would just reload "today" as still-yesterday.
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
