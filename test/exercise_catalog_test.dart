import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/screens/exercise_catalog_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('filtra por violão e mantém a escolha ao remontar', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExerciseCatalogScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Violão').last);
    await tester.pumpAndSettle();

    expect(find.text('Violão: identificar notas'), findsOneWidget);
    expect(find.text('Abrir simulador de Violão'), findsOneWidget);
    expect(find.text('Prática: reconhecer notas'), findsNothing);
    expect(find.text('Intervalos auditivos'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: ExerciseCatalogScreen()));
    await tester.pumpAndSettle();

    final instrumentFilter = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).at(2),
    );
    expect(instrumentFilter.value, 'Violão');
    expect(find.text('Violão: identificar notas'), findsOneWidget);
    expect(find.text('Abrir simulador de Violão'), findsOneWidget);
  });
}
