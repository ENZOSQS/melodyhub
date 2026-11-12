import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/services/app_preferences.dart';
import 'package:melodyhub/widgets/keyboard_octave_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('mais e menos ajustam teclas e respeitam os limites 1–4', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _SelectorHarness())),
    );

    expect(find.text('1 oitava'), findsOneWidget);
    expect(_countLabel(tester, 1), '1 oitava · 7 teclas brancas');
    await tester.tap(find.byTooltip('−'));
    await tester.pump();
    expect(find.text('1 oitava'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('+'));
      await tester.pump();
    }
    expect(find.text('4 oitavas'), findsOneWidget);
    expect(_countLabel(tester, 4), '4 oitavas · 28 teclas brancas');
    await tester.tap(find.byTooltip('+'));
    await tester.pump();
    expect(find.text('4 oitavas'), findsOneWidget);

    await tester.tap(find.byTooltip('−'));
    await tester.pump();
    expect(find.text('3 oitavas'), findsOneWidget);
    expect(await AppPreferences.keyboardOctaveCount(), 3);
  });
}

String _countLabel(WidgetTester tester, int count) => tester
    .widget<Semantics>(
      find
          .ancestor(
            of: find.text('$count ${count == 1 ? 'oitava' : 'oitavas'}'),
            matching: find.byType(Semantics),
          )
          .first,
    )
    .properties
    .label!;

class _SelectorHarness extends StatefulWidget {
  const _SelectorHarness();

  @override
  State<_SelectorHarness> createState() => _SelectorHarnessState();
}

class _SelectorHarnessState extends State<_SelectorHarness> {
  int _octaves = 1;

  void _change(int value) {
    setState(() => _octaves = value);
    unawaited(AppPreferences.setKeyboardOctaveCount(value));
  }

  @override
  Widget build(BuildContext context) => Center(
    child: KeyboardOctaveSelector(octaveCount: _octaves, onChanged: _change),
  );
}
