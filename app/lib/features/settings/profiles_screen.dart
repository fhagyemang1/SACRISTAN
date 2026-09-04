import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_session.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';
import 'admin_pin_screen.dart';

/// Profiles include the one-and-only admin profile that
/// `admin_pin_screen.dart` looks up (the first row with
/// `role == ProfileRole.admin`), so adding or deleting a profile here is
/// gated behind [AdminSession] the same way editing/deleting an inventory
/// item is (see `inventory_screen.dart`'s `_showItemDialog`) — otherwise a
/// locked-out volunteer could delete the admin profile to make
/// `AdminPinScreen` treat the app as having no PIN set at all, and set
/// their own.
class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProfileRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sacristan Profiles')),
      body: StreamBuilder<List<Profile>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          final profiles = snap.data ?? const <Profile>[];
          if (profiles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No profiles yet. Add volunteers and assign roles.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: profiles.length,
            itemBuilder: (context, i) {
              final p = profiles[i];
              return Card(
                child: ListTile(
                  leading: Icon(p.role == ProfileRole.admin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline),
                  title: Text(p.displayName),
                  subtitle: Text(p.role == ProfileRole.admin ? 'Admin' : 'Volunteer'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete ${p.displayName}',
                    onPressed: () => _confirmDelete(context, repo, p),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add profile'),
        onPressed: () => _showAddDialog(context, repo),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ProfileRepository repo, Profile profile) async {
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
