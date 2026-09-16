import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/active_profile_controller.dart';
import 'data/admin_session.dart';
import 'data/database.dart';
import 'data/locale_controller.dart';
import 'data/notifications_service.dart';
import 'data/repositories.dart';
import 'features/checklists/builtin_templates.dart';
import 'features/common/app_shell.dart';
import 'features/reference/reference_data.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = SacristanDatabase();
  await seedBuiltinTemplatesIfNeeded(db);
  await seedReferenceEntriesIfNeeded(ReferenceRepository(db));
  // Local-only notification scheduling (see notifications_service.dart) —
  // no server, no account. Safe to call even on platforms/devices where
  // the user later denies permission; reminders still save either way.
  await NotificationsService.instance.init();
  await NotificationsService.instance.requestPermissions();

  final settingsRepo = SettingsRepository(db);
  final initialLocale = await LocaleController.loadInitial(settingsRepo);
  final initialActiveProfileId =
      await ActiveProfileController.loadInitial(settingsRepo);

  runApp(SacristanApp(
    db: db,
    initialLocale: initialLocale,
    initialActiveProfileId: initialActiveProfileId,
  ));
}

/// Populates the built-in checklist templates on first launch only. Safe
/// to call on every startup — it checks first and is a no-op after the
/// first run. Entirely local: no network call, no remote config.
Future<void> seedBuiltinTemplatesIfNeeded(SacristanDatabase db) async {
  final existing = await db.select(db.checklistTemplates).get();
  if (existing.isNotEmpty) return;

  for (final t in builtinTemplates) {
    final templateId = newId();
    await db.into(db.checklistTemplates).insert(
          ChecklistTemplatesCompanion.insert(
            id: Value(templateId),
            name: t.name,
            massType: t.massType,
            phase: t.phase,
            isBuiltin: const Value(true),
          ),
        );
    var order = 0;
    for (final item in t.items) {
      await db.into(db.checklistItems).insert(
            ChecklistItemsCompanion.insert(
              templateId: templateId,
              sortOrder: Value(order++),
              labelKey: Value(item.labelKey),
              // BUG FIX (round 4 review): the full authored text
              // (item.label — e.g. "Missal and ribbons set to today's
              // readings") was never being stored anywhere. labelKey alone
              // ("missalRibbons") is only meant as a future localization
              // lookup key, and checklist_detail_screen.dart's fallback
              // when no l10n entry exists just prettifies that key into
              // "Missal Ribbons" — silently discarding the actual
              // guidance text every built-in checklist item was written
              // with. Storing it in labelCustom means the real text always
              // displays now; a future l10n pass can still look up
              // labelKey first and only fall back to this stored English
              // text for locales that don't have the key translated yet.
              labelCustom: Value(item.label),
              latinTerm: Value(item.latin),
            ),
          );
    }
  }
}

class SacristanApp extends StatelessWidget {
  final SacristanDatabase db;
  final Locale initialLocale;
  final String? initialActiveProfileId;
  const SacristanApp({
    super.key,
    required this.db,
    required this.initialLocale,
    this.initialActiveProfileId,
  });

  @override
  Widget build(BuildContext context) {
    final settingsRepo = SettingsRepository(db);
    return MultiProvider(
      providers: [
        Provider<SacristanDatabase>.value(value: db),
        Provider<CalendarRepository>(create: (_) => CalendarRepository(db)),
        Provider<MassRepository>(create: (_) => MassRepository(db)),
        Provider<ChecklistRepository>(create: (_) => ChecklistRepository(db)),
        Provider<InventoryRepository>(create: (_) => InventoryRepository(db)),
        Provider<NotesRepository>(create: (_) => NotesRepository(db)),
        Provider<ProfileRepository>(create: (_) => ProfileRepository(db)),
        Provider<ContactRepository>(create: (_) => ContactRepository(db)),
        Provider<SupplierRepository>(create: (_) => SupplierRepository(db)),
        Provider<ReminderRepository>(create: (_) => ReminderRepository(db)),
        Provider<ReferenceRepository>(create: (_) => ReferenceRepository(db)),
        Provider<SettingsRepository>.value(value: settingsRepo),
        ChangeNotifierProvider<AdminSession>(create: (_) => AdminSession()),
        ChangeNotifierProvider<LocaleController>(
            create: (_) => LocaleController(settingsRepo, initialLocale)),
        ChangeNotifierProvider<ActiveProfileController>(
            create: (_) => ActiveProfileController(
                settingsRepo, initialActiveProfileId)),
      ],
      child: Consumer<LocaleController>(
        builder: (context, localeController, _) => MaterialApp(
          title: 'SACRISTAN',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          // English, French, and Spanish ship in this build (see lib/l10n);
          // the l10n.yaml + ARB pipeline is what makes adding a fourth
          // language purely additive — a new app_XX.arb file plus running
          // `flutter gen-l10n`, no code restructuring.
          locale: localeController.locale,
          supportedLocales: supportedLocales,
          // BUG FIX (round 8): AppLocalizations.delegate was missing from
          // this list. Every AppLocalizations.of(context) call added in
          // round 5 (app_shell.dart's nav labels, color_chip.dart's
          // rankLabel/seasonLabel, and several screen titles/buttons) uses
          // a null-assertion (`!`) on that call's result — without this
          // delegate registered, Localizations.of<AppLocalizations>()
          // always returns null, so AppShell's very first build() would
          // have thrown "Null check operator used on a null value" and
          // crashed the app on launch, in every locale, every time.
          // flutter analyze cannot catch this class of bug (it's a
          // runtime widget-registration issue, not a type error) — this
          // is exactly the kind of thing only running the app finds,
          // which is why getting real device/emulator testing going is
          // still the top priority even now that CI is green.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppShell(),
        ),
      ),
    );
  }
}
