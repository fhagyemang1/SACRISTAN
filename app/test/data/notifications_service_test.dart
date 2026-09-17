import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/data/notifications_service.dart';

/// Regression test for a round-10 bug: `NotificationsService` used to
/// derive the int id `flutter_local_notifications` requires from
/// `reminderId.hashCode & 0x7fffffff`. Dart's own docs on
/// `Object.hashCode` say hash values "need not be consistent between
/// executions of the same program" — but `scheduleReminder()` and
/// `cancel()` are routinely called from *different app sessions* (add a
/// reminder today, cancel it next week after restarting the app), and
/// the underlying OS-level notification persists independent of whether
/// this process is even still running. If a later session ever derived
/// a different id for the same reminder id string, `cancel()` would
/// silently fail to cancel the real notification, and a reminder the
/// user believes they deleted would still fire.
///
/// `stableNotificationId()` replaced `.hashCode` with a hand-rolled
/// FNV-1a hash specifically so this file *owns* the algorithm rather
/// than depending on an object's built-in, explicitly-unstable hash —
/// these tests can't reproduce a real cross-process run, but they do
/// pin down the properties that guarantee must hold: same input always
/// gives the same output, and the output is always a valid
/// non-negative 31-bit int the plugin can accept.
void main() {
  group('stableNotificationId', () {
    test('is deterministic for the same id, called repeatedly', () {
      const id = 'a1b2c3d4-e5f6-47a8-9abc-def012345678';
      final first = stableNotificationId(id);
      for (var i = 0; i < 20; i++) {
        expect(stableNotificationId(id), first,
            reason: 'stableNotificationId must return the same value '
                'every time for the same input, including across what '
                'would be separate app sessions in real use.');
      }
    });

    test('is always a non-negative int flutter_local_notifications can take',
        () {
      final sampleIds = [
        '',
        'a',
        'reminder-1',
        'a1b2c3d4-e5f6-47a8-9abc-def012345678',
        List.filled(200, 'x').join(), // a very long id, just in case
      ];
      for (final id in sampleIds) {
        final result = stableNotificationId(id);
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(0x7fffffff));
      }
    });

    test('different ids usually produce different results (sanity check '
        'against an accidentally-constant implementation)', () {
      final ids = List.generate(50, (i) => 'reminder-$i');
      final results = ids.map(stableNotificationId).toSet();
      // Not a collision-freedom guarantee (that's not this function's
      // job — flutter_local_notifications ids only need to be unique
      // among a single device's *currently scheduled* reminders, a much
      // smaller set) — just a guard against the whole function
      // collapsing to one value.
      expect(results.length, greaterThan(40));
    });
  });

  // Round 15: [ReminderReliability] backs the "Fix notifications" banner
  // on Settings > Reminders (reminders_screen.dart) — its only job is
  // turning two independent booleans into one "is everything actually
  // going to work" answer, so that's the one property worth pinning down
  // here. The permission-check methods that produce those booleans
  // (`hasNotificationPermission`, `hasExactAlarmPermission`, etc.) go
  // through real platform channels and aren't meaningfully unit-testable
  // without a running Android/iOS environment — this deliberately tests
  // only the pure logic layered on top of them.
  group('ReminderReliability.isFullyReliable', () {
    test('true only when both permissions are granted', () {
      expect(
          const ReminderReliability(
                  notificationsAllowed: true, exactAlarmsAllowed: true)
              .isFullyReliable,
          isTrue);
    });

    test('false when notifications are off, even if exact alarms are fine',
        () {
      expect(
          const ReminderReliability(
                  notificationsAllowed: false, exactAlarmsAllowed: true)
              .isFullyReliable,
          isFalse);
    });

    test('false when exact alarms are off, even if notifications are fine',
        () {
      expect(
          const ReminderReliability(
                  notificationsAllowed: true, exactAlarmsAllowed: false)
              .isFullyReliable,
          isFalse);
    });

    test('false when both are off', () {
      expect(
          const ReminderReliability(
                  notificationsAllowed: false, exactAlarmsAllowed: false)
              .isFullyReliable,
          isFalse);
    });
  });
}
