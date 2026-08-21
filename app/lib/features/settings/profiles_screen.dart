import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/repositories.dart';

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
                    onPressed: () => repo.deleteProfile(p.id),
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

  Future<void> _showAddDialog(BuildContext context, ProfileRepository repo) async {
    final nameCtrl = TextEditingController();
    var role = ProfileRole.volunteer;
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
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await repo.addProfile(nameCtrl.text.trim(), role);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
