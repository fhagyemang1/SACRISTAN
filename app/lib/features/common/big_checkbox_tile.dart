import 'package:flutter/material.dart';

/// A checklist row sized for volunteers working quickly, under time
/// pressure, sometimes with imprecise motor control: the entire row is the
/// tap target (not just the checkbox glyph), minimum 64dp tall, with a
/// clearly distinct checked/unchecked visual state that doesn't rely on
/// color alone (icon shape changes too).
class BigCheckboxTile extends StatelessWidget {
  final String label;
  final String? latinTerm;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const BigCheckboxTile({
    super.key,
    required this.label,
    this.latinTerm,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      checked: checked,
      label: latinTerm == null ? label : '$label ($latinTerm)',
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: checked
                ? scheme.primaryContainer.withValues(alpha: 0.5)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: checked ? scheme.primary : scheme.outlineVariant,
              width: checked ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 32,
                color: checked ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                        color: checked
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    if (latinTerm != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          latinTerm!,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
