import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/domain/note_identification_rules.dart';

void main() {
  group('resoluções de notas em Dó maior', () {
    const cases = <int, List<int>>{
      60: [60],
      62: [62, 60],
      64: [64, 62, 60],
      65: [65, 64, 62, 60],
      67: [67, 69, 71, 72],
      69: [69, 71, 72],
      71: [71, 72],
    };

    for (final entry in cases.entries) {
      test('MIDI ${entry.key} resolve por ${entry.value}', () {
        expect(NoteIdentificationRules.resolutionFor(entry.key), entry.value);
      });
    }

    test('notas em oitava grave resolvem à tônica grave correspondente', () {
      expect(NoteIdentificationRules.resolutionFor(55), [55, 57, 59, 60]);
      expect(NoteIdentificationRules.resolutionFor(59), [59, 60]);
      expect(NoteIdentificationRules.resolutionFor(48), [48]);
    });
  });

  test('cadência Dó–Fá–Sol–Dó usa acordes maiores em sequência', () {
    expect(NoteIdentificationRules.cadenceChords, [
      [48, 52, 55],
      [53, 57, 60],
      [55, 59, 62],
      [60, 64, 67],
    ]);
  });

  test('notas disponíveis seguem os cinco níveis', () {
    expect(NoteIdentificationRules.notesForLevel(1), [60, 67]);
    expect(NoteIdentificationRules.notesForLevel(2), [60, 64, 67]);
    expect(NoteIdentificationRules.notesForLevel(3), [60, 62, 64, 65, 67]);
    expect(NoteIdentificationRules.notesForLevel(4), [
      60,
      62,
      64,
      65,
      67,
      69,
      71,
    ]);
    expect(NoteIdentificationRules.notesForLevel(5), [
      48,
      50,
      52,
      53,
      55,
      57,
      59,
      60,
      62,
      64,
      65,
      67,
      69,
      71,
    ]);
  });

  test('item crítico registra a classe de nota com identificador estável', () {
    expect(NoteIdentificationRules.criticalItemFor(62), 'nota_Re');
    expect(NoteIdentificationRules.criticalItemFor(74), 'nota_Re');
  });

  group('regra de resposta', () {
    test('acerto é a nota sorteada, em qualquer tentativa', () {
      for (var attempt = 1; attempt <= 3; attempt++) {
        expect(
          NoteIdentificationRules.evaluate(
            target: 64,
            selected: 64,
            attempt: attempt,
          ),
          NoteAnswerOutcome.correct,
        );
      }
    });

    test('erro pede nova tentativa até o 3º, que revela a resposta', () {
      expect(
        NoteIdentificationRules.evaluate(target: 64, selected: 62, attempt: 1),
        NoteAnswerOutcome.tryAgain,
      );
      expect(
        NoteIdentificationRules.evaluate(target: 64, selected: 65, attempt: 2),
        NoteAnswerOutcome.tryAgain,
      );
      expect(
        NoteIdentificationRules.evaluate(target: 64, selected: 60, attempt: 3),
        NoteAnswerOutcome.revealed,
      );
    });

    test('no nível 5 a mesma nota em outra oitava conta como erro', () {
      expect(
        NoteIdentificationRules.evaluate(target: 52, selected: 64, attempt: 1),
        NoteAnswerOutcome.tryAgain,
      );
    });

    test('a nota sorteada sempre tem um botão no nível', () {
      final random = math.Random(7);
      for (var level = 1; level <= 5; level++) {
        final options = NoteIdentificationRules.notesForLevel(level);
        for (var i = 0; i < 200; i++) {
          expect(
            options,
            contains(NoteIdentificationRules.drawTarget(level, random)),
          );
        }
      }
    });

    test('o sorteio alcança todas as notas do nível 5 (duas oitavas)', () {
      final random = math.Random(3);
      final drawn = {
        for (var i = 0; i < 2000; i++)
          NoteIdentificationRules.drawTarget(5, random),
      };
      expect(drawn, NoteIdentificationRules.notesForLevel(5).toSet());
    });
  });

  group('estado dos botões', () {
    NoteButtonState state(
      int midi, {
      Set<int> wrong = const {},
      bool finished = false,
      bool revealed = false,
    }) => NoteIdentificationRules.buttonState(
      midi: midi,
      target: 64,
      wrongMidis: wrong,
      finished: finished,
      revealed: revealed,
    );

    test('com a questão aberta nenhum botão acende sozinho', () {
      for (final midi in NoteIdentificationRules.notesForLevel(4)) {
        expect(state(midi), NoteButtonState.idle);
      }
    });

    test('depois do acerto só a nota sorteada fica verde', () {
      for (final midi in NoteIdentificationRules.notesForLevel(4)) {
        expect(
          state(midi, finished: true),
          midi == 64 ? NoteButtonState.correct : NoteButtonState.idle,
        );
      }
    });

    test('as notas da resolução não mudam a cor dos botões', () {
      final resolution = NoteIdentificationRules.resolutionFor(64);
      for (final midi in resolution.where((m) => m != 64)) {
        expect(state(midi, finished: true), NoteButtonState.idle);
      }
    });

    test('erros ficam marcados e a revelação mostra a nota sorteada', () {
      const wrong = {60, 62, 67};
      expect(state(62, wrong: wrong), NoteButtonState.wrong);
      expect(
        state(64, wrong: wrong, finished: true, revealed: true),
        NoteButtonState.revealed,
      );
      expect(
        state(67, wrong: wrong, finished: true, revealed: true),
        NoteButtonState.wrong,
      );
    });
  });
}
