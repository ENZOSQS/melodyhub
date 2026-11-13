import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/screens/exercise_catalog_screen.dart';
import 'package:melodyhub/widgets/mh_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Finder chip(String texto) => find.widgetWithText(MhChoiceChip, texto);

  testWidgets('filtra por violão e mantém a escolha ao remontar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: ExerciseCatalogScreen()));
    await tester.pumpAndSettle();

    await tester.tap(chip('Violão'));
    await tester.pumpAndSettle();

    expect(find.text('Violão: identificar notas'), findsOneWidget);
    expect(find.text('Abrir simulador de Violão'), findsOneWidget);
    expect(find.text('Identificar a nota'), findsNothing);
    expect(find.text('Intervalos auditivos'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: ExerciseCatalogScreen()));
    await tester.pumpAndSettle();

    expect(tester.widget<MhChoiceChip>(chip('Violão')).selecionado, isTrue);
    expect(tester.widget<MhChoiceChip>(chip('Todos')).selecionado, isFalse);
    expect(find.text('Violão: identificar notas'), findsOneWidget);
    expect(find.text('Abrir simulador de Violão'), findsOneWidget);
  });
}
