import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Teste simples de login', (tester) async {
    
    expect(find.text('Entrar'), findsOneWidget);

  });
}