import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/domain/tempo_rules.dart';

void main() {
  test('faixa e tolerância de BPM apertam conforme o nível', () {
    expect(TempoRules.bpmRange(1), (min: 60, max: 120));
    expect(TempoRules.bpmRange(5), (min: 50, max: 200));
    expect([for (var n = 1; n <= 5; n++) TempoRules.tolerance(n)], [
      10,
      8,
      6,
      4,
      3,
    ]);
  });

  test('compara o BPM marcado com o original', () {
    final lento = TempoRules.evaluate(level: 1, target: 96, guess: 90);
    expect(lento.correct, isTrue);
    expect(lento.difference, -6);
    expect(lento.description, '6 BPM mais lento');
    expect(lento.stars, 2);

    final exato = TempoRules.evaluate(level: 3, target: 120, guess: 120);
    expect(exato.stars, 3);
    expect(exato.description, 'Exatamente igual!');

    final rapido = TempoRules.evaluate(level: 5, target: 100, guess: 105);
    expect(rapido.correct, isFalse);
    expect(rapido.description, '5 BPM mais rápido');
    expect(rapido.stars, 1);

    expect(TempoRules.evaluate(level: 5, target: 100, guess: 120).stars, 0);
  });

  test('valor inicial do ajuste fica dentro da faixa', () {
    expect(TempoRules.startingGuess(100, 20), 120);
    expect(TempoRules.startingGuess(210, 20), 190);
    expect(TempoRules.clampBpm(300), TempoRules.maxBpm);
    expect(TempoRules.beatMs(120), 500);
  });
}
