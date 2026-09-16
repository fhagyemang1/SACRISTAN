import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/active_profile_controller.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';
import '../../l10n/app_localizations.dart';
import 'admin_pin_screen.dart';
import 'checklist_template_editor_screen.dart';
import 'contacts_suppliers_screen.dart';
import 'language_screen.dart';
import 'local_calendar_editor_screen.dart';
import 'profiles_screen.dart';
import 'reminders_screen.dart';

/// Settings + About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.navSettings)),
      body: ListView(
        children: [
          _SectionHeader(AppLocalizations.of(context)!.settingsAccessSection),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Admin PIN'),
            subtitle: const Text(
                'Protects template/inventory editing. Volunteers get a lighter, '
                'view-and-check-off mode.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminPinScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Sacristan Profiles'),
            subtitle: const _ActiveProfileSubtitle(),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilesScreen())),
          ),
          const Divider(),
          _SectionHeader(AppLocalizations.of(context)!.settingsChecklistsSection),
          ListTile(
            leading: const Icon(Icons.checklist_outlined),
            title: const Text('Manage Checklist Templates'),
            subtitle: const Text(
                'Add templates, add/remove/reorder their items — the '
                '"before Mass" and "after Mass" lists sacristans check off'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ChecklistTemplateEditorScreen())),
          ),
          const Divider(),
          _SectionHeader(AppLocalizations.of(context)!.settingsCalendarSection),
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Parish/Diocesan Calendar'),
            subtitle: const Text(
                'Add or edit local feasts (patronal feast, diocesan saints, '
                'parish anniversary) — entirely offline'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LocalCalendarEditorScreen())),
          ),
          const Divider(),
          _SectionHeader(AppLocalizations.of(context)!.settingsNotificationsContactsSection),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Reminders'),
            subtitle: const Text('Feast-day prep, linen laundering, restocking'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RemindersScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.sms_outlined),
            title: const Text('Contacts & Suppliers'),
            subtitle: const Text(
                'Pastor, sacristan, and server-leader phone numbers for '
                'low-stock text alerts; suppliers to text orders to. Opens '
                'the device\'s own Messages app — no SMS account or gateway '
                'needed.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ContactsSuppliersScreen())),
          ),
          const Divider(),
          _SectionHeader(AppLocalizations.of(context)!.settingsAppSection),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: const Text('English · Français · Español'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanguageScreen())),
          ),
          const ListTile(
            leading: Icon(Icons.brightness_6_outlined),
            title: Text('Appearance'),
            subtitle: Text('Follows system light/dark mode'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About & Attribution'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AboutScreen(),
            )),
          ),
        ],
      ),
    );
  }
}

/// Round 14+: shows who's currently identified as the app's active user
/// (see `active_profile_controller.dart`), so it's visible from Settings
/// without having to open the Sacristan Profiles screen just to check.
/// Combines [ActiveProfileController] (just an id) with [ProfileRepository]
/// (the actual list of profiles, for the display name) — a separate
/// widget rather than inlined in [SettingsScreen] specifically so this
/// stream subscription only exists while this row is actually visible.
class _ActiveProfileSubtitle extends StatelessWidget {
  const _ActiveProfileSubtitle();

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ActiveProfileController>().activeProfileId;
    if (activeId == null) {
      return const Text('Add volunteers, assign roles');
    }
    final repo = context.read<ProfileRepository>();
    return StreamBuilder<List<Profile>>(
      stream: repo.watchAll(),
      builder: (context, snap) {
        final match = (snap.data ?? const <Profile>[])
            .where((p) => p.id == activeId);
        if (match.isEmpty) return const Text('Add volunteers, assign roles');
        return Text('Currently: ${match.first.displayName}');
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

/// Required by both app stores' review guidelines when the app collects no
/// personal data: a clear, in-app statement of that fact, plus attribution
/// for bundled third-party content. See docs/STORE_CHECKLIST.md.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About SACRISTAN')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('SACRISTAN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
            'A companion for Catholic sacristans — the laypeople and clergy '
            'who prepare the sacristy, vestments, sacred vessels, and altar '
            'for Mass and other liturgical celebrations.',
          ),
          SizedBox(height: 20),
          Text('Privacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            'This app collects no personal data and makes no network '
            'requests. All of your parish\'s data — checklists, inventory, '
            'notes, and calendar entries — stays on this device, in a local '
            'database. There is no account, no login, and no server.',
          ),
          SizedBox(height: 20),
          Text('Not an official publication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            'SACRISTAN is an independent app for practical parish use. It is '
            'not published, endorsed, or reviewed by the Vatican, a diocese, '
            'or any parish, and it is not a substitute for the Roman Missal, '
            'the General Instruction of the Roman Missal (GIRM), or your '
            'pastor\'s and diocese\'s own instructions — always follow those '
            'where this app and local practice differ.',
          ),
          SizedBox(height: 20),
          Text('No warranty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            'SACRISTAN is provided free of charge and as-is, with no '
            'warranty of any kind. It\'s built and maintained by one person, '
            'not a formal organization, and while care has gone into '
            'getting the liturgical calendar and other details right, '
            'always double-check anything time-sensitive or feast-specific '
            'against your parish\'s own calendar and your pastor\'s '
            'instructions before relying on it.',
          ),
          SizedBox(height: 20),
          Text('Attribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            '• Liturgical calendar computation: original implementation of '
            'the public-domain Anonymous Gregorian (Meeus/Jones/Butcher) '
            'Easter algorithm and the General Roman Calendar\'s published '
            'rules.\n'
            '• Reference Library glossary and rubric notes: original '
            'summaries citing the General Instruction of the Roman Missal '
            '(GIRM) and standard sacristan formation guidance — see each '
            'entry\'s "Source" line.\n'
            '• Vestment/vessel illustrations: original line-art created for '
            'this app.\n'
            '• No copyrighted Missal or Lectionary text is reproduced in '
            'this app.',
          ),
        ],
      ),
    );
  }
}
