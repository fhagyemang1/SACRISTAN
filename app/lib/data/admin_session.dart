import 'package:flutter/foundation.dart';

/// In-memory "is admin mode currently unlocked" flag for this app run.
///
/// Deliberately NOT persisted: every fresh launch starts locked (volunteer
/// mode), and unlocking requires the admin PIN again. This matches the
/// spec's intent — a lighter view for volunteers who "just need today's
/// checklist" by default, with editing gated behind the PIN rather than
/// wide open. Screens that perform an admin-only action should check
/// [isUnlocked] and, if false, route to [AdminPinRequired] (see
/// admin_pin_screen.dart) instead of performing the action.
class AdminSession extends ChangeNotifier {
  bool _isUnlocked = false;
  bool get isUnlocked => _isUnlocked;

  void unlock() {
    _isUnlocked = true;
    notifyListeners();
  }

  void lock() {
    _isUnlocked = false;
    notifyListeners();
  }
}
