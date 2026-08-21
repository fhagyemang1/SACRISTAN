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
      body: ListView(
        children: [
          for (final locale in supportedLocales)
            RadioListTile<String>(
              value: locale.languageCode,
              groupValue: controller.locale.languageCode,
              title: Text(_names[locale.languageCode] ?? locale.languageCode),
              onChanged: (code) {
                if (code != null) controller.setLocale(Locale(code));
              },
            ),
        ],
      ),
    );
  }
}
