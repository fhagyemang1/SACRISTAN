import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications`. Every notification
/// here is scheduled entirely on-device — there is no server-side push,
/// no account, and no network call anywhere in this file. This is what
/// lets Reminders ("relaunder the purificators before Palm Sunday",
/// "restock hosts") fire correctly even if the device never goes online
/// between now and the trigger time.
///
/// PLATFORM NOTE: `flutter_local_notifications` supports Android, iOS,
/// macOS, and Linux, but — as of this writing — has no Windows platform
/// implementation, so it cannot post native Windows toast notifications.
/// On Windows this service still records reminders (they're stored via
/// [ReminderRepository]/the Reminders table and listed in the Reminders
/// screen — nothing about *tracking* a reminder requires OS notification
/// support), it just can't pop a system toast for one. If native Windows
/// toasts matter for your parish's desktop use, add a package such as
/// `local_notifier` (which does support Windows/macOS/Linux) behind the
/// same `scheduleReminder`/`cancel` interface used here — everything that
/// calls this service goes through that interface, not through
/// `flutter_local_notifications` directly, so swapping the Windows
/// implementation in doesn't touch any screen.
class NotificationsService {
  static final NotificationsService instance = NotificationsService._();
  NotificationsService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// True when the current platform has a real notification backend wired
  /// up (see the class-level PLATFORM NOTE for why Windows is excluded).
  bool get supportsNativeNotifications =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    // Round 11: this used to be commented as a "falls back to UTC if the
    // platform's local zone can't be read" — that was wrong on two counts:
    // there was never any attempt to read the real device zone (nothing
    // here calls `flutter_timezone` or any platform channel), and, more
    // importantly, that framing implied a real-world risk that isn't
    // there. `tz.local` is only consulted by `TZDateTime.from()` (used
    // below in `scheduleReminder`) to compute the *display* time zone
    // label/offset of the resulting object — NOT the absolute instant it
    // schedules. `TZDateTime.from(other, location)`'s own implementation
    // (package:timezone, lib/src/date_time.dart) is `this._(
    // _toNative(other).toUtc(), location, ...)`: the underlying instant
    // comes from calling `.toUtc()` on `other` directly, which uses
    // Dart's own (OS-backed) notion of the device's real local zone —
    // completely independent of whatever `location` is passed in here.
    // Since every `triggerAt` this app schedules is built as a plain
    // `DateTime(year, month, day, hour, minute)` from date/time pickers
    // (see reminders_screen.dart) — i.e. already a wall-clock value in
    // the device's actual system zone — hardcoding `tz.local` to UTC
    // does not shift when reminders actually fire; it would only matter
    // if this file ever read back a scheduled TZDateTime's `.hour`/
    // `.minute`/zone name for display, which it doesn't (the Reminders
    // screen displays the plain `DateTime` stored in the database, not
    // anything derived from `tz.local`). Verified by reading the
    // `timezone` package's source rather than assumed — see the round-11
    // entry in docs/ARCHITECTURE.md for the full reasoning. Kept as a
    // real `Location` object (rather than removed) because
    // `TZDateTime.from()` requires one; UTC is as good as any fixed
    // choice here. Wiring `flutter_timezone` to read the real device
    // zone would only become worth doing if a future feature needs
    // *displayed* zone-aware timestamps (it is not needed for correct
    // firing times).
    tz.setLocalLocation(tz.getLocation('UTC'));

    if (!supportsNativeNotifications) {
      // Windows (see class doc): nothing to initialize on this platform.
      _initialized = true;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const macInit = DarwinInitializationSettings();
    const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');
    await _plugin.initialize(const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: macInit,
      linux: linuxInit,
    ));
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!supportsNativeNotifications) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleReminder({
    required String id,
    required String title,
    String? body,
    required DateTime triggerAt,
  }) async {
    await init();
    if (!supportsNativeNotifications) return; // see PLATFORM NOTE above
    // Reminder ids are strings (uuid-ish, see database.dart's newId());
    // flutter_local_notifications wants a stable int id, so we derive one
    // deterministically from the string id — see [stableNotificationId]
    // for why that must NOT be `.hashCode`.
    final notifId = stableNotificationId(id);
    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      tz.TZDateTime.from(triggerAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sacristan_reminders',
          'Sacristan Reminders',
          channelDescription:
              'Feast-day prep, linen laundering, and restocking reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(String id) async {
    await init();
    if (!supportsNativeNotifications) return;
    await _plugin.cancel(stableNotificationId(id));
  }
}

/// Round 10: turns a reminder id into the int id
/// `flutter_local_notifications` wants — deterministically, and the same
/// way on every run of the app, forever. Deliberately not prefixed with
/// `_`: it's a pure, deterministic function with no dependency on the
/// notification plugin, so it's directly unit-testable (see
/// `test/data/notifications_service_test.dart`) without needing to mock
/// `flutter_local_notifications` — not because it's meant to be called
/// from outside this file. This used to be
/// `id.hashCode & 0x7fffffff`, which is a real bug: Dart's own docs on
/// `Object.hashCode` say values "need not be consistent between
/// executions of the same program." `zonedSchedule()` and `cancel()` are
/// routinely called from *different app sessions* — you add a reminder
/// today, close the app, and cancel it next week — and
/// `flutter_local_notifications` schedules persist at the OS level
/// independent of whether this process is even still running. If a
/// later session's `.hashCode` for the same string id ever differs from
/// the session that originally scheduled it, `cancel()` derives the
/// wrong notification id and silently fails to cancel the real one: the
/// user sees the reminder disappear from the app's list (the database
/// row really is deactivated) while the original OS-level notification
/// fires anyway. A hand-rolled FNV-1a hash sidesteps the whole class of
/// risk, since it's an algorithm this file owns outright rather than
/// borrowing an object's built-in, explicitly-unstable hashCode.
int stableNotificationId(String id) {
  const fnvOffsetBasis = 0x811c9dc5;
  const fnvPrime = 0x01000193;
  var hash = fnvOffsetBasis;
  for (final codeUnit in id.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }
  return hash & 0x7fffffff;
}
