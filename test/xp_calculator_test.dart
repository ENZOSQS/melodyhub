import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/utils/xp_calculator.dart';

void main() {
  test('Deve retornar 10 XP quando a resposta estiver correta', () {
    final xp = XpCalculator.calculateXp(true);

    expect(xp, 10);
  });

  test('Deve retornar 0 XP quando a resposta estiver incorreta', () {
    final xp = XpCalculator.calculateXp(false);

    expect(xp, 0);
  });
}