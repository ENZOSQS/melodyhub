import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('mostra e-mail, senha e botão Entrar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'E-mail',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Senha',
      ),
      findsOneWidget,
    );
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });

  testWidgets('pede o e-mail quando a recuperação começa sem endereço', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar senha'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
  });
}
