import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'dias do lembrete usam semana completa por padrão e persistem ordenados',
    () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AppPreferences.reminderDays(), [1, 2, 3, 4, 5, 6, 7]);

      await AppPreferences.setReminderDays([7, 2, 2, 9, 0]);
      expect(await AppPreferences.reminderDays(), [2, 7]);
    },
  );

  test(
    'lista inválida vazia mantém o padrão sem deixar lembrete sem dias',
    () async {
      SharedPreferences.setMockInitialValues({
        'lembrete_dias_semana': <String>[],
      });
      expect(await AppPreferences.reminderDays(), [1, 2, 3, 4, 5, 6, 7]);
      await AppPreferences.setReminderDays([]);
      expect(await AppPreferences.reminderDays(), [1, 2, 3, 4, 5, 6, 7]);
    },
  );
}
