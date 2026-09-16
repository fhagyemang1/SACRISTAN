import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/active_profile_controller.dart';
import '../../data/admin_session.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import 'admin_pin_screen.dart';

/// Profiles include the one-and-only admin profile that
/// `admin_pin_screen.dart` looks up (the first row with
/// `role == ProfileRole.admin`), so adding or deleting a profile here is
/// gated behind [AdminSession] the same way editing/deleting an inventory
/// item is (see `inventory_screen.dart`'s `_showItemDialog`) — otherwise a
/// locked-out volunteer could delete the admin profile to make
/// `AdminPinScreen` treat the app as having no PIN set at all, and set
/// their own.
///
/// Round 14+: this screen is also where a sacristan identifies themselves
/// as the app's current active user — tapping a profile (no PIN needed;
/// switching who's currently checking things off isn't an admin-only
/// action) makes it the one [ActiveProfileController] reports, which
/// `checklist_detail_screen.dart` then records against every tick. This
/// resolves round 11's "found, not fixed" finding that Sacristan Profiles
/// otherwise had no real purpose beyond the admin PIN.
class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProfileRepository>();
    final activeProfile = context.watch<ActiveProfileController>();
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.profilesTitle)),
      body: StreamBuilder<List<Profile>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          final profiles = snap.data ?? const <Profile>[];
          if (profiles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(loc.profilesEmptyState),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  activeProfile.activeProfileId == null
                      ? "Tap a profile below to say it's you."
                      : 'Tap a profile to switch, or tap the active one again '
                          'to clear it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (final p in profiles)
                Card(
                  child: ListTile(
                    leading: Icon(p.role == ProfileRole.admin
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline),
                    title: Text(p.displayName),
                    subtitle: Text(p.role == ProfileRole.admin ? 'Admin' : 'Volunteer'),
                    selected: activeProfile.activeProfileId == p.id,
                    selectedTileColor:
                        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (activeProfile.activeProfileId == p.id)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.check_circle,
                                color: Colors.green,
                                semanticLabel: 'Active profile'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete ${p.displayName}',
                          onPressed: () => _confirmDelete(context, repo, p, activeProfile),
                        ),
                      ],
                    ),
                    onTap: () => activeProfile.setActiveProfile(
                        activeProfile.activeProfileId == p.id ? null : p.id),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(loc.profilesAddProfile),
        onPressed: () => _showAddDialog(context, repo),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProfileRepository repo,
      Profile profile, ActiveProfileController activeProfile) async {
    final session = context.read<AdminSession>();
    if (!session.isUnlocked) {
      AdminPinRequiredSnackBar.show(context);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this profile?'),
        content: Text(profile.role == ProfileRole.admin
            ? '"${profile.displayName}" will be removed, along with its '
                'admin PIN. If this is the only admin profile, the next '
                'person to open Admin PIN will be able to set a brand-new '
                'PIN with no admin confirmation — make sure that\'s really '
                'what you want.'
            : '"${profile.displayName}" will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await repo.deleteProfile(profile.id);
      // Round 14+: without this, a deleted profile's id could stay stored
      // as "the active profile" — every future checklist tick would then
      // silently record `doneByProfileId` pointing at a row that no
      // longer exists, and `_activeProfileName` (settings_screen.dart)
      // would have nothing to look up and display.
      if (activeProfile.activeProfileId == profile.id) {
        await activeProfile.setActiveProfile(null);
      }
    }
  }

  Future<void> _showAddDialog(BuildContext context, ProfileRepository repo) async {
    final session = context.read<AdminSession>();
    if (!session.isUnlocked) {
      AdminPinRequiredSnackBar.show(context);
      return;
    }
    final nameCtrl = TextEditingController();
    var role = ProfileRole.volunteer;
    // Round 11: see the identical guard elsewhere (reminders_screen.dart,
    // inventory_screen.dart, etc.) — prevents a double-tap on "Add" from
    // creating two profile rows before the first `await` completes.
    var submitting = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProfileRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: ProfileRole.volunteer, child: Text('Volunteer')),
                  DropdownMenuItem(value: ProfileRole.admin, child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => role = v ?? role),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setState(() => submitting = true);
                      try {
                        await repo.addProfile(nameCtrl.text.trim(), role);
                        if (context.mounted) Navigator.of(context).pop();
                      } finally {
                        if (context.mounted) setState(() => submitting = false);
                      }
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
