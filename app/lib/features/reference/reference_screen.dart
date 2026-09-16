import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/admin_session.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../settings/admin_pin_screen.dart';

/// Offline reference library: vestment/vessel glossary with illustrations,
/// short GIRM-derived notes for sacristan duties, and rubric notes (linen
/// care, sanctuary lamp, etc.). Bundled entries are seeded into the local
/// database once on first launch (see reference_data.dart); a parish can
/// add its own entries (admin-gated) or delete any entry, bundled or
/// their own — nothing here is fetched from a network.
class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  static const _categories = ['glossary', 'girm', 'rubric'];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReferenceRepository>();
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Glossary'),
              Tab(text: 'GIRM Notes'),
              Tab(text: 'Rubric Notes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _EntryList(repo: repo, category: 'glossary', showIllustration: true),
                _EntryList(repo: repo, category: 'girm', showIllustration: false),
                _EntryList(repo: repo, category: 'rubric', showIllustration: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.referenceAddEntry),
        onPressed: () => _showAddDialog(
            context, repo, _categories[_tabs.index]),
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, ReferenceRepository repo, String category) async {
    final session = context.read<AdminSession>();
    if (!session.isUnlocked) {
      AdminPinRequiredSnackBar.show(context);
      return;
    }
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    // Round 11: same double-tap-creates-a-duplicate-row guard used
    // throughout the app's other "Add" dialogs — needs a `StatefulBuilder`
    // (this dialog previously had no local mutable state) so the button
    // can rebuild itself disabled while `repo.add(...)` is in flight.
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add ${_categoryLabel(category)} entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  autofocus: true,
                ),
                TextField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(labelText: 'Details'),
                  minLines: 2,
                  maxLines: 5,
                ),
                TextField(
                  controller: sourceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Source (e.g. "Parish tradition", "Diocesan guidance")'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
                        return;
                      }
                      setState(() => submitting = true);
                      try {
                        await repo.add(
                          category: category,
                          title: titleCtrl.text.trim(),
                          bodyMarkdown: bodyCtrl.text.trim(),
                          sourceCitation: sourceCtrl.text.trim().isEmpty
                              ? 'Parish-added entry'
                              : sourceCtrl.text.trim(),
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

String _categoryLabel(String c) {
  switch (c) {
    case 'glossary':
      return 'glossary';
    case 'girm':
      return 'GIRM note';
    default:
      return 'rubric note';
  }
}

class _EntryList extends StatelessWidget {
  final ReferenceRepository repo;
  final String category;
  final bool showIllustration;
  const _EntryList(
      {required this.repo, required this.category, required this.showIllustration});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSession>();
    return StreamBuilder<List<ReferenceEntry>>(
      stream: repo.watchByCategory(category),
      builder: (context, snap) {
        // `snap.data == null` (stream hasn't emitted its first event yet)
        // and "the stream emitted an empty list" both make `entries`
        // empty below, but they're not the same state — an admin can
        // delete every entry in a category (see the delete button further
        // down), and that legitimately-empty category must not be shown
        // as forever "Loading…", which never resolves once the stream
        // has already emitted.
        if (!snap.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Loading…'),
          ));
        }
        final entries = snap.data!;
        if (entries.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(AppLocalizations.of(context)!.referenceEmptyState,
                textAlign: TextAlign.center),
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: showIllustration &&
                        e.illustrationAsset != null &&
                        e.illustrationAsset!.isNotEmpty
                    ? SizedBox(
                        width: 48,
                        height: 48,
                        child: SvgPicture.asset(
                          'assets/reference/${e.illustrationAsset}',
                          placeholderBuilder: (context) =>
                              const Icon(Icons.church_outlined, size: 32),
                        ),
                      )
                    : const Icon(Icons.menu_book_outlined, size: 32),
                title: Row(
                  children: [
                    Flexible(
                        child: Text(e.title,
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (e.latinName != null && e.latinName!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('· ${e.latinName}',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 13)),
                    ],
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.bodyMarkdown),
                      const SizedBox(height: 6),
                      Text('Source: ${e.sourceCitation}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.outline)),
                    ],
                  ),
                ),
                isThreeLine: true,
                trailing: session.isUnlocked
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete entry',
                        onPressed: () => repo.delete(e.id),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
