import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_session.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';

/// Set up or enter the admin PIN. The first profile with role
/// [ProfileRole.admin] is treated as "the" admin profile for PIN purposes
/// — a parish that wants named per-person admin accounts can extend this
/// to check a chosen profile instead of always the first one found.
class AdminPinScreen extends StatefulWidget {
  const AdminPinScreen({super.key});

  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  Profile? _adminProfile;
  bool _loading = true;
  // Round 11: guards the "Set PIN and unlock" button below against a
  // double-tap. That handler does two sequential `await`s (creating the
  // one-and-only admin `Profile` via `profileRepo.addProfile(...)`, then
  // `profileRepo.setPin(...)`) before it pops this screen — with nothing
  // previously stopping a second tap, in that window, from also seeing
  // `_adminProfile == null` and creating a *second* "Parish Admin"
  // profile with its own separate PIN. This is the very first screen a
  // fresh install's admin sees, which is exactly when an eager double-tap
  // is likely.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<SacristanDatabase>();
    final profiles = await (db.select(db.profiles)
          ..where((p) => p.role.equalsValue(ProfileRole.admin)))
        .get();
    setState(() {
      _adminProfile = profiles.isEmpty ? null : profiles.first;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _hasPin => _adminProfile?.pinHash != null;

  @override
  Widget build(BuildContext context) {
    final profileRepo = context.read<ProfileRepository>();
    final session = context.read<AdminSession>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin PIN')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (session.isUnlocked)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(children: [
                          Icon(Icons.lock_open),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text('Admin mode is unlocked for this session.')),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (!_hasPin) ...[
                    const Text(
                      'No admin PIN is set yet. Create one to protect '
                      'checklist-template and inventory editing.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinCtrl,
                      decoration: const InputDecoration(labelText: 'New PIN (4+ digits)'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmCtrl,
                      decoration: const InputDecoration(labelText: 'Confirm PIN'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                        if (_pinCtrl.text.length < 4) {
                          setState(() => _error = 'PIN must be at least 4 digits.');
                          return;
                        }
                        if (_pinCtrl.text != _confirmCtrl.text) {
                          setState(() => _error = 'PINs do not match.');
                          return;
                        }
                        setState(() => _submitting = true);
                        try {
                          var profile = _adminProfile;
                          // Wrapped in explicit parens `(() async {...})()` —
                          // an immediately-invoked function expression needs
                          // that outer grouping in Dart, unlike JS, to parse
                          // unambiguously as "call this literal now" rather
                          // than a bare function-typed value.
                          profile ??= await (() async {
                            // `context.read` must happen before the `await`
                            // below, not after — using a `BuildContext`
                            // across an async gap risks it having been
                            // unmounted in between (round 9's
                            // `use_build_context_synchronously` lint).
                            // `db` doesn't depend on `id`, so hoisting this
                            // line up is a free fix, not a workaround.
                            final db = context.read<SacristanDatabase>();
                            final id = await profileRepo.addProfile(
                                'Parish Admin', ProfileRole.admin);
                            return (db.select(db.profiles)
                                  ..where((p) => p.id.equals(id)))
                                .getSingle();
                          })();
                          await profileRepo.setPin(profile.id, _pinCtrl.text);
                          _adminProfile = profile; // keep _hasPin correct if we don't pop
                          session.unlock();
                          if (context.mounted) Navigator.of(context).pop();
                        } finally {
                          // See the `_submitting` field doc: re-enables the
                          // button if we didn't pop (e.g. an exception) —
                          // if we did pop, this screen is gone and the
                          // `mounted` check below just makes the no-op
                          // setState safe either way.
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                      child: const Text('Set PIN and unlock'),
                    ),
                  ] else ...[
                    const Text('Enter the admin PIN to unlock editing.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinCtrl,
                      decoration: const InputDecoration(labelText: 'PIN'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final ok = await profileRepo.verifyPin(
                            _adminProfile!.id, _pinCtrl.text);
                        if (ok) {
                          session.unlock();
                          if (context.mounted) Navigator.of(context).pop();
                        } else {
                          setState(() => _error = 'Incorrect PIN.');
                        }
                      },
                      child: const Text('Unlock'),
                    ),
                    if (session.isUnlocked) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          session.lock();
                          setState(() {});
                        },
                        child: const Text('Lock admin mode'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

/// Small helper widget any admin-only action can use: shown instead of
/// performing the action when [AdminSession.isUnlocked] is false.
class AdminPinRequiredSnackBar {
  static void show(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Admin PIN required to make this change.'),
        action: SnackBarAction(
          label: 'Unlock',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminPinScreen()),
          ),
        ),
      ),
    );
  }
}
