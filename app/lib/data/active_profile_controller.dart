import 'package:flutter/material.dart';

import 'repositories.dart';

/// Holds "who's currently using the app" — a lightweight, persisted
/// notion of the active [Profile]. Deliberately a separate concept from
/// [AdminSession] (`admin_session.dart`): that tracks only whether
/// admin-only *actions* are currently unlocked, never *who* unlocked
/// them, and resets to locked on every fresh launch by design. This
/// controller is the opposite on both counts — it identifies a person,
/// not a permission level, and it persists across restarts.
///
/// Round 11's full-codebase review found `ChecklistTicks.doneByProfileId`
/// dead end-to-end: the column, the repository parameter, and the storage
/// write all existed and worked, but every real call site in the app
/// passed `null`, because there was no concept anywhere of "which
/// sacristan is currently checking things off." This controller closes
/// that gap — see `checklist_detail_screen.dart`'s checkbox `onChanged`
/// for where it's actually consulted, and `profiles_screen.dart` for
/// where a sacristan picks themselves.
///
/// Persisted the same way [LocaleController] persists the chosen app
/// language: one row in `AppSettings` via [SettingsRepository], rather
/// than kept only in memory like [AdminSession] — a volunteer shouldn't
/// have to re-identify themselves every time they reopen the app to check
/// one more box, only when a different person actually picks up the
/// device and switches.
class ActiveProfileController extends ChangeNotifier {
  static const _settingsKey = 'activeProfileId';

  final SettingsRepository _settings;
  String? _activeProfileId;

  ActiveProfileController(this._settings, String? initial)
      : _activeProfileId = initial;

  String? get activeProfileId => _activeProfileId;

  /// Reads the persisted active profile id (if any) before the app
  /// starts, mirroring [LocaleController.loadInitial] — so `main()` can
  /// construct this controller with the right initial value in one pass.
  /// Deliberately does not validate that the id still refers to a real
  /// row here (that would need a database round trip before the app can
  /// even show a first frame); a stale id from a since-deleted profile is
  /// instead handled where it's actually consulted — see
  /// `profiles_screen.dart`'s delete flow, which clears this controller
  /// when the profile being deleted is the active one.
  static Future<String?> loadInitial(SettingsRepository settings) =>
      settings.getValue(_settingsKey);

  Future<void> setActiveProfile(String? profileId) async {
    _activeProfileId = profileId;
    notifyListeners();
    if (profileId == null) {
      await _settings.deleteValue(_settingsKey);
    } else {
      await _settings.setValue(_settingsKey, profileId);
    }
  }
}
