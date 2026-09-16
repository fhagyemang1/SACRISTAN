import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/active_profile_controller.dart';
import '../../data/database.dart';
import '../../data/repositories.dart';
import '../common/big_checkbox_tile.dart';

/// A single running checklist (one Mass, one phase — before or after).
/// Ticks are written straight to SQLite and stream back, so progress
/// survives the app being closed, the device restarting, or airplane mode
/// — there is nothing here that depends on connectivity.
class ChecklistDetailScreen extends StatelessWidget {
  final String instanceId;
  final String templateId;
  final String title;

  const ChecklistDetailScreen({
    super.key,
    required this.instanceId,
    required this.templateId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChecklistRepository>();
    // Round 14+: `ChecklistTicks.doneByProfileId` used to be dead data —
    // every call here passed `null`, because there was no concept of
    // "who's using the app right now." `ActiveProfileController` (see
    // its own doc comment) now supplies that, set from the Sacristan
    // Profiles screen. `context.watch` (not `read`) deliberately, so
    // switching the active profile mid-checklist takes effect on the
    // very next tap without needing to reopen this screen.
    final activeProfileId =
        context.watch<ActiveProfileController>().activeProfileId;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<ChecklistItem>>(
        stream: repo.watchItems(templateId),
        builder: (context, itemsSnap) {
          final items = itemsSnap.data ?? const <ChecklistItem>[];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This template has no items yet. Add some from the '
                  'template editor (Settings > Manage Checklist Templates).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return StreamBuilder<Map<String, ChecklistTick>>(
            stream: repo.watchTicks(instanceId),
            builder: (context, ticksSnap) {
              final ticks = ticksSnap.data ?? const <String, ChecklistTick>{};
              final doneCount = items
                  .where((i) => ticks[i.id]?.isDone == true)
                  .length;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: items.isEmpty ? 0 : doneCount / items.length,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('$doneCount / ${items.length}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isDone = ticks[item.id]?.isDone ?? false;
                        return BigCheckboxTile(
                          label: item.labelCustom ??
                              _builtinLabel(item.labelKey) ??
                              '(untitled item)',
                          latinTerm: item.latinTerm,
                          checked: isDone,
                          onChanged: (v) => repo.setTick(
                              instanceId, item.id, v, activeProfileId),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Falls back to a readable label for a built-in item key when no locale
/// bundle is loaded for it yet.
///
/// LOCALIZATION STATUS (round 5 review): navigation labels, the
/// color/rank/season vocabulary, and a handful of other chrome strings are
/// wired through `AppLocalizations` (see `lib/l10n/app_*.arb` and every
/// call site that imports `l10n/app_localizations.dart`) and do change
/// with the in-app Language picker. The ~130 built-in checklist item
/// labels (this file), free-text screen copy (dialog titles, hint text,
/// error messages), and the celebration/feast *names* themselves (which
/// come from the pure-Dart `liturgical_calendar` package, outside
/// Flutter's l10n system entirely, and would need their own translated
/// data table) are NOT yet localized — they always render in English
/// regardless of the selected language. Extending `AppLocalizations` to
/// checklist items and screen copy is the same mechanical pattern already
/// used elsewhere; translating celebration names accurately is a content
/// task that should go through a bilingual reviewer familiar with
/// liturgical terminology, not a mechanical string swap.
String? _builtinLabel(String? key) {
  if (key == null) return null;
  final spaced = key.replaceAllMapped(
      RegExp('([A-Z])'), (m) => ' ${m.group(1)}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}
