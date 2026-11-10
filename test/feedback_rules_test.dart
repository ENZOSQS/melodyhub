import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/domain/feedback_rules.dart';

void main() {
  group('nivelDeApoio', () {
    test('etapas 1 e 2 recebem apoio iniciante', () {
      expect(
        nivelDeApoio(nivelEtapa: 1, sequenciaAcertos: 0),
        NivelApoio.iniciante,
      );
      expect(
        nivelDeApoio(nivelEtapa: 2, sequenciaAcertos: 4),
        NivelApoio.iniciante,
      );
    });

    test('etapa 3 recebe apoio intermediário', () {
      expect(
        nivelDeApoio(nivelEtapa: 3, sequenciaAcertos: 0),
        NivelApoio.intermediario,
      );
    });

    test('etapas 4 e 5 recebem apoio avançado', () {
      expect(
        nivelDeApoio(nivelEtapa: 4, sequenciaAcertos: 0),
        NivelApoio.avancado,
      );
      expect(
        nivelDeApoio(nivelEtapa: 5, sequenciaAcertos: 0),
        NivelApoio.avancado,
      );
    });

    test(
      'cinco acertos seguidos elevam o apoio a avançado em qualquer etapa',
      () {
        expect(
          nivelDeApoio(nivelEtapa: 1, sequenciaAcertos: 5),
          NivelApoio.avancado,
        );
        expect(
          nivelDeApoio(nivelEtapa: 3, sequenciaAcertos: 7),
          NivelApoio.avancado,
        );
      },
    );

    test('sequência abaixo de cinco mantém o apoio definido pela etapa', () {
      expect(
        nivelDeApoio(nivelEtapa: 3, sequenciaAcertos: 4),
        NivelApoio.intermediario,
      );
    });
  });
}
