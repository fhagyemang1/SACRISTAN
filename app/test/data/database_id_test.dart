import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/data/database.dart';

/// Regression test for a round-10 bug: `newId()` (the primary-key
/// generator every table in this app uses) used to combine
/// `DateTime.now().microsecondsSinceEpoch` with `identityHashCode
/// (Object())` — neither of which is actually a uniqueness guarantee.
/// `DateTime.now()`'s real resolution isn't guaranteed sub-microsecond
/// on every platform this app ships to, and `identityHashCode()` is
/// explicitly not documented as collision-free. The first place this
/// function ran at any volume was `main.dart`'s first-launch seeding
/// loop (~100 sequential inserts before the UI even shows) — a
/// collision there throws on insert (the column is a primary key) and
/// would have crashed the app before a sacristan ever saw a screen.
///
/// `newId()` now uses `Random.secure()` (a CSPRNG) instead of
/// timing-derived entropy. This test can't prove collision-freedom
/// (nothing short of exhaustion could), but it does pin down the
/// properties a regression back to the old approach would likely break:
/// generating a large batch of ids fast, in a tight loop with no
/// `await` between calls (the exact shape of the seeding loop that
/// motivated this fix), still yields no duplicates.
void main() {
  group('newId()', () {
    test('produces no duplicates across a large, tight-loop batch', () {
      final ids = List.generate(5000, (_) => newId());
      final unique = ids.toSet();
      expect(unique.length, ids.length,
          reason: 'newId() produced a duplicate within a single tight '
              'loop — exactly the failure mode round 10 fixed (this '
              'is the same shape as main.dart\'s first-launch seeding '
              'loop, which calls newId() synchronously per row).');
    });

    test('looks like a v4 UUID (36 chars, hyphens in the standard spots)',
        () {
      final id = newId();
      expect(id.length, 36);
      expect(id[8], '-');
      expect(id[13], '-');
      expect(id[18], '-');
      expect(id[23], '-');
      // Version 4 nibble.
      expect(id[14], '4');
    });
  });
}
