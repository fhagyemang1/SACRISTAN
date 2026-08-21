import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../calendar_detail/calendar_detail_screen.dart';
import '../checklists/checklist_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../notes/notes_screen.dart';
import '../reference/reference_screen.dart';
import '../settings/settings_screen.dart';

/// Root scaffold with bottom navigation. Kept to five top-level
/// destinations (a sixth, Settings, is reached from the app bar) so the
/// bottom bar's touch targets stay large on a phone.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  DateTime _selectedDate = DateTime.now();

  void _openDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final pages = [
      DashboardScreen(onOpenDate: _openDate),
      CalendarDetailScreen(initialDate: _selectedDate),
      const ChecklistListScreen(),
      const InventoryScreen(),
      const ReferenceScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            tooltip: t.navNotes,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => NotesScreen(date: _selectedDate),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.navSettings,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            )),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.today_outlined),
              selectedIcon: const Icon(Icons.today),
              label: t.navToday),
          NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: t.navCalendar),
          NavigationDestination(
              icon: const Icon(Icons.checklist_outlined),
              selectedIcon: const Icon(Icons.checklist),
              label: t.navChecklists),
          NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: t.navInventory),
          NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: t.navReference),
        ],
      ),
    );
  }
}
