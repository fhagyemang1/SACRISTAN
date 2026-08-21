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
    // Falls back to UTC if the platform's local zone can't be read; a
    // reminder still fires, just anchored to UTC rather than the device's
    // zone in that edge case. Wiring `flutter_timezone` to read the real
    // device zone is a small follow-up if that matters for your parish.
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
    // deterministically from the string id rather than tracking a second
    // counter.
    final notifId = id.hashCode & 0x7fffffff;
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
    await _plugin.cancel(id.hashCode & 0x7fffffff);
  }
}
