import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../data/repositories.dart';
import '../common/sms_helper.dart';

/// Manage the Pastor / Sacristan / Server-Leader contacts that low-stock
/// alerts text, and the Suppliers a pastor can text (or, once back
/// online, email/call/order-online) to restock. Both lists are local —
/// nothing here syncs anywhere.
class ContactsSuppliersScreen extends StatefulWidget {
  const ContactsSuppliersScreen({super.key});

  @override
  State<ContactsSuppliersScreen> createState() => _ContactsSuppliersScreenState();
}

class _ContactsSuppliersScreenState extends State<ContactsSuppliersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts & Suppliers'),
        bottom: TabBar(controller: _tabs, tabs: const [
          Tab(text: 'Parish Contacts'),
          Tab(text: 'Suppliers'),
        ]),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_ContactsTab(), _SuppliersTab()],
      ),
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ContactRepository>();
    return Scaffold(
      body: StreamBuilder<List<Contact>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          final contacts = snap.data ?? const <Contact>[];
          if (contacts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add phone numbers for the Pastor, Sacristan, and Server '
                  'Leader so low-stock alerts can text them directly.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: contacts.length,
            itemBuilder: (context, i) {
              final c = contacts[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(c.name),
                  subtitle: Text('${_roleLabel(c.role)} · ${c.phone}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sms_outlined),
                        tooltip: 'Text this contact',
                        onPressed: () =>
                            openSmsComposerWithFeedback(context, phone: c.phone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete ${c.name}',
                        onPressed: () => repo.delete(c.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add contact'),
        onPressed: () => _showAddContactDialog(context, repo),
      ),
    );
  }

  Future<void> _showAddContactDialog(BuildContext context, ContactRepository repo) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    var role = ContactRole.sacristan;
    // Round 11: see the identical guard in reminders_screen.dart /
    // inventory_screen.dart / profiles_screen.dart — prevents a
    // double-tap on "Add" from creating two contact rows before the
    // first tap's `await repo.add(...)` completes and pops this dialog.
    var submitting = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add parish contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ContactRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ContactRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r))))
                    .toList(),
                onChanged: (v) => setState(() => role = v ?? role),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                        return;
                      }
                      setState(() => submitting = true);
                      try {
                        await repo.add(
                            role, nameCtrl.text.trim(), phoneCtrl.text.trim());
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

class _SuppliersTab extends StatelessWidget {
  const _SuppliersTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SupplierRepository>();
    return Scaffold(
      body: StreamBuilder<List<Supplier>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          final suppliers = snap.data ?? const <Supplier>[];
          if (suppliers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add your usual suppliers here so a pastor can text an '
                  'order directly, or reach them online once connected.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: suppliers.length,
            itemBuilder: (context, i) {
              final s = suppliers[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(s.name),
                  subtitle: Text([
                    if (s.contactName != null) s.contactName!,
                    if (s.phone != null) s.phone!,
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s.phone != null)
                        IconButton(
                          icon: const Icon(Icons.sms_outlined),
                          tooltip: 'Text an order to this supplier',
                          onPressed: () => openSmsComposerWithFeedback(
                            context,
                            phone: s.phone!,
                            body: 'Hello — placing a supply order from our parish. ',
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete ${s.name}',
                        onPressed: () => repo.delete(s.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add supplier'),
        onPressed: () => _showAddSupplierDialog(context, repo),
      ),
    );
  }

  Future<void> _showAddSupplierDialog(BuildContext context, SupplierRepository repo) async {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    // Round 11: same double-tap-creates-a-duplicate-row guard as the
    // contacts dialog above — needs the dialog wrapped in a
    // `StatefulBuilder` (this one previously had no local mutable state
    // at all) so the button can rebuild itself disabled while submitting.
    var submitting = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add supplier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Supplier name'),
                autofocus: true,
              ),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact person (optional)'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone number (optional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setState(() => submitting = true);
                      try {
                        await repo.add(
                          nameCtrl.text.trim(),
                          contactName: contactCtrl.text.trim().isEmpty
                              ? null
                              : contactCtrl.text.trim(),
                          phone: phoneCtrl.text.trim().isEmpty
                              ? null
                              : phoneCtrl.text.trim(),
                        );
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

String _roleLabel(ContactRole r) {
  switch (r) {
    case ContactRole.pastor:
      return 'Pastor';
    case ContactRole.sacristan:
      return 'Sacristan';
    case ContactRole.serverLeader:
      return 'Leader of Mass Servers';
  }
}
