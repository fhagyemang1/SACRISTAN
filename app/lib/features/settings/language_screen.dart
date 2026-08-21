import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/locale_controller.dart';

const _names = {
  'en': 'English',
  'fr': 'Français',
  'es': 'Español',
};

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      // Round 9: Radio/RadioListTile's own `groupValue`/`onChanged` are
      // deprecated as of Flutter's Radio API redesign — the group is now
      // owned by an ancestor `RadioGroup`, with each RadioListTile taking
      // only `value`. See https://docs.flutter.dev/release/breaking-changes/radio-api-redesign
      body: RadioGroup<String>(
        groupValue: controller.locale.languageCode,
        onChanged: (code) {
          if (code != null) controller.setLocale(Locale(code));
        },
        child: ListView(
          children: [
            for (final locale in supportedLocales)
              RadioListTile<String>(
                value: locale.languageCode,
                title: Text(_names[locale.languageCode] ?? locale.languageCode),
              ),
          ],
        ),
      ),
    );
  }
}
