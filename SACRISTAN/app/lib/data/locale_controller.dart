import 'package:flutter/material.dart';

import 'repositories.dart';

const supportedLocales = [Locale('en'), Locale('fr'), Locale('es')];

/// Holds the user's chosen app language and persists it locally (no
/// network, no account — just a row in the AppSettings table) so the
/// choice survives an app restart. Defaults to the device's system locale
/// when it's one of [supportedLocales], English otherwise.
class LocaleController extends ChangeNotifier {
  static const _settingsKey = 'locale';

  final SettingsRepository _settings;
  Locale _locale;

  LocaleController(this._settings, Locale initial) : _locale = initial;

  Locale get locale => _locale;

  /// Reads the persisted locale (if any) before the app starts, so
  /// `main()` can construct [LocaleController] with the right initial
  /// value in one pass rather than flashing the default language first.
  static Future<Locale> loadInitial(SettingsRepository settings) async {
    final stored = await settings.getValue(_settingsKey);
    if (stored != null) {
      final match = supportedLocales.where((l) => l.languageCode == stored);
      if (match.isNotEmpty) return match.first;
    }
    final system = WidgetsBinding.instance.platformDispatcher.locale;
    final systemMatch =
        supportedLocales.where((l) => l.languageCode == system.languageCode);
    return systemMatch.isNotEmpty ? systemMatch.first : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    await _settings.setValue(_settingsKey, locale.languageCode);
  }
}
