import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Round 15: must match `applicationId` in android/app/build.gradle.kts —
/// there is no dependency-free way to read it back at runtime from pure
/// Dart, and pulling in a package (e.g. package_info_plus) just to avoid
/// one hardcoded string felt like a worse trade than this comment. Only
/// [NotificationsService.openBatteryOptimizationSettings] uses it.
const _androidPackageName = 'com.example.sacristan';

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
    // Round 13+ fix: macOS is a genuinely first-class supported platform
    // elsewhere in this file (included in supportsNativeNotifications
    // above, and init() explicitly configures `macOS:
    // DarwinInitializationSettings()`), but `flutter_local_notifications`
    // treats iOS and macOS as two distinct platform-implementation
    // classes, each needing its own explicit permission request per the
    // package's own documented usage — this call was missing entirely, so
    // resolvePlatformSpecificImplementation<IOSFlutterLocalNotifications
    // Plugin>() above silently returns null on macOS (the active
    // implementation there is MacOSFlutterLocalNotificationsPlugin), and
    // macOS never showed its system notification-authorization prompt.
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // Round 15 fix: this app's own AndroidManifest.xml has, since round
    // 13, carried a comment explaining that Android 12+ needs
    // SCHEDULE_EXACT_ALARM *declared* before an exact reminder can be
    // scheduled at all — but declaring it was never enough on its own.
    // On Android 14+ (API 34+) this permission is no longer auto-granted
    // at install the way it was on 12-13; the user has to explicitly
    // allow it, and nothing in this app ever asked. The practical result
    // (confirmed against a real report: a reminder silently never fired,
    // with no error visible anywhere) was `scheduleReminder`'s
    // `AndroidScheduleMode.exactAllowWhileIdle` call throwing at
    // schedule time — caught in reminders_screen.dart's "Add reminder"
    // dialog, which could only tell the sacristan to go check their
    // device settings themselves, with no indication of which setting.
    // `requestExactAlarmsPermission()` is `flutter_local_notifications`'
    // own wrapper for the system "Alarms & reminders" screen: it opens
    // that screen directly, pre-scoped to this app, for a single-tap
    // Allow, rather than making anyone find it inside Settings. See also
    // [checkReliability]/[requestReliabilityFixes] below, which let
    // Settings > Reminders re-offer this same fix later — this
    // first-launch call alone can't cover a permission the user denied,
    // revoked afterward, or a phone that wasn't done setting itself up
    // yet the first time the app ran.
    await android?.requestExactAlarmsPermission();
  }

  /// Whether Android has a real, native "post a notification" permission
  /// currently granted for this app. Always true on platforms without
  /// that concept (iOS/macOS handle their own authorization prompt inside
  /// [requestPermissions] instead; Windows has no notification backend at
  /// all — see the class doc comment).
  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  /// Whether this app is currently allowed to schedule *exact* alarms —
  /// the specific permission [scheduleReminder] needs for
  /// `AndroidScheduleMode.exactAllowWhileIdle` to actually fire on time
  /// rather than being silently dropped or coalesced into an inexact,
  /// battery-friendly window Android may delay by hours. See the long
  /// comment on [requestPermissions] above for why this can be false even
  /// after `requestPermissions()` has already run once.
  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? true;
  }

  /// A snapshot of whether this device will actually deliver a scheduled
  /// reminder, for the "Fix notifications" card on Settings > Reminders
  /// (see `reminders_screen.dart`) — added because, before round 15, the
  /// only way a sacristan found out a reminder hadn't fired was the
  /// reminder simply never firing, with the app never having said
  /// anything about why or what to do about it.
  Future<ReminderReliability> checkReliability() async {
    await init();
    return ReminderReliability(
      notificationsAllowed: await hasNotificationPermission(),
      exactAlarmsAllowed: await hasExactAlarmPermission(),
    );
  }

  /// Walks the sacristan through every permission a reminder needs, one
  /// native system prompt/screen at a time, instead of telling them to go
  /// find it themselves — this is the actual "Fix notifications" action
  /// behind the Reminders-screen banner. Returns the resulting state so
  /// the caller can show what (if anything) is still not fixed, such as
  /// an OEM battery/autostart manager this app has no public API to reach
  /// (see [openBatteryOptimizationSettings]'s doc comment).
  Future<ReminderReliability> requestReliabilityFixes() async {
    await requestPermissions();
    return checkReliability();
  }

  /// Opens Android's standard "ignore battery optimizations for this app"
  /// system dialog, pre-scoped to Sacristan — a single Allow/Deny tap,
  /// not a Settings menu to hunt through. This is the one lever
  /// `flutter_local_notifications` itself doesn't expose (it only wraps
  /// the notification and exact-alarm permissions above), because
  /// battery-optimization exemption isn't specific to notifications.
  ///
  /// This does NOT cover manufacturer-specific "autostart manager" /
  /// "protected apps" lists that some Android skins (Xiaomi, Vivo,
  /// Infinix/Transsion's XOS, Oppo, Huawei, ...) layer on top of stock
  /// Android's own battery optimization system — those have no public,
  /// documented Intent action at all, vary by OEM and OS version, and a
  /// wrong guess risks opening the wrong screen entirely on some device.
  /// The Reminders-screen banner that calls this says so explicitly
  /// rather than silently pretending this one tap fixes everything.
  Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:$_androidPackageName',
    );
    try {
      await intent.launch();
    } on PlatformException {
      // Some OEM builds refuse this intent outright rather than just
      // showing nothing useful; there is nothing more specific this app
      // can do about that from here, so this is swallowed rather than
      // crashing the screen that triggered it — the caller's UI already
      // states this step may need to be done manually.
    }
  }

  Future<void> scheduleReminder({
    required String id,
    required String title,
    String? body,
    required DateTime triggerAt,
    // Round 14+: `Reminders.repeatRule` (null | 'weekly' | 'yearly') has
    // been stored since round 2 but was never actually read anywhere —
    // every reminder only ever fired once, no matter what a future UI
    // might eventually pass here. Wired up now by mapping directly onto
    // `flutter_local_notifications`' own built-in repeat mechanism,
    // `matchDateTimeComponents`, rather than building any app-level
    // re-scheduling loop: passing it turns a single `zonedSchedule` call
    // into a real OS-level *repeating* alarm, which the OS keeps firing
    // on schedule even if this app is never opened again between
    // occurrences — exactly the property a "relaunder the purificators
    // every Sunday" or "restock incense every year before Advent"
    // reminder needs, and something an app-level reschedule-on-launch
    // approach could not provide on its own. `DateTimeComponents.
    // dayOfWeekAndTime` matches only the weekday + time (the plugin's own
    // documented meaning) — i.e. weekly. `DateTimeComponents.dateAndTime`
    // matches month + day + time but *not* year — i.e. yearly. Both
    // confirmed against the package's own current published API docs,
    // not assumed.
    String? repeatRule,
  }) async {
    await init();
    if (!supportsNativeNotifications) return; // see PLATFORM NOTE above
    // Reminder ids are strings (uuid-ish, see database.dart's newId());
    // flutter_local_notifications wants a stable int id, so we derive one
    // deterministically from the string id — see [stableNotificationId]
    // for why that must NOT be `.hashCode`.
    final notifId = stableNotificationId(id);
    final matchComponents = switch (repeatRule) {
      'weekly' => DateTimeComponents.dayOfWeekAndTime,
      'yearly' => DateTimeComponents.dateAndTime,
      _ => null,
    };
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
      matchDateTimeComponents: matchComponents,
    );
  }

  Future<void> cancel(String id) async {
    await init();
    if (!supportsNativeNotifications) return;
    await _plugin.cancel(stableNotificationId(id));
  }
}

/// Round 15: a plain-data snapshot of whether reminders will actually
/// fire on this device right now — see [NotificationsService
/// .checkReliability]. Deliberately not a bool: the "Fix notifications"
/// card (reminders_screen.dart) needs to say *which* thing is off so its
/// button/status text can be specific rather than a generic "something's
/// wrong, good luck."
class ReminderReliability {
  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;

  const ReminderReliability({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
  });

  bool get isFullyReliable => notificationsAllowed && exactAlarmsAllowed;
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
