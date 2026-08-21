import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sacristan/features/common/big_checkbox_tile.dart';

void main() {
  testWidgets('tapping the tile calls onChanged with the toggled value',
      (tester) async {
    bool? lastValue;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BigCheckboxTile(
          label: 'Chalice and paten set out',
          latinTerm: 'Calix et Patena',
          checked: false,
          onChanged: (v) => lastValue = v,
        ),
      ),
    ));

    expect(find.text('Chalice and paten set out'), findsOneWidget);
    expect(find.text('Calix et Patena'), findsOneWidget);

    await tester.tap(find.byType(BigCheckboxTile));
    await tester.pump();

    expect(lastValue, isTrue);
  });

  testWidgets('checked tile exposes checked semantics and a strike-through',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BigCheckboxTile(
          label: 'Purificator',
          checked: true,
          onChanged: (_) {},
        ),
      ),
    ));

    final semantics = tester.getSemantics(find.byType(BigCheckboxTile));
    // `hasFlag` is deprecated since Flutter 3.32 in favor of
    // `flagsCollection` (a `SemanticsFlags` object whose `isChecked`
    // getter returns a tri-state `CheckedState`, not a bool) — a real
    // API shape change, not a simple rename. Deferring that migration
    // until a real `flutter test` run can confirm the exact replacement
    // (this sandbox has no compiler to verify it against), and silencing
    // just this one deprecation notice so it doesn't fail `flutter
    // analyze` in the meantime. `SemanticsFlag` itself is still the
    // correct, non-deprecated type for `hasFlag`'s argument — it just
    // needed a direct `dart:ui` import above, since this Flutter SDK
    // version doesn't surface it transitively through `material.dart`.
    // ignore: deprecated_member_use
    expect(semantics.hasFlag(SemanticsFlag.isChecked), isTrue);

    final text = tester.widget<Text>(find.text('Purificator'));
    expect(text.style?.decoration, TextDecoration.lineThrough);

    handle.dispose();
  });
}
