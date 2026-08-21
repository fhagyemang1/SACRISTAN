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
    expect(semantics.hasFlag(SemanticsFlag.isChecked), isTrue);

    final text = tester.widget<Text>(find.text('Purificator'));
    expect(text.style?.decoration, TextDecoration.lineThrough);

    handle.dispose();
  });
}
