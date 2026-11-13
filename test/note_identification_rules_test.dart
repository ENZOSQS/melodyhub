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
}
