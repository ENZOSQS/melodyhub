import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/domain/ear_training_levels.dart';

void main() {
  test('identificação de notas cresce conforme os níveis funcionais', () {
    expect(EarTrainingLevels.practiceNotes(1), [0, 7]);
    expect(EarTrainingLevels.practiceNotes(2), [0, 4, 7]);
    expect(EarTrainingLevels.practiceNotes(3), [0, 2, 4, 5, 7]);
    expect(EarTrainingLevels.practiceNotes(4), [0, 2, 4, 5, 7, 9, 11]);
    expect(EarTrainingLevels.practiceNotes(5), [0, 2, 4, 5, 7, 9, 11]);
  });

  test('intervalos começam com saltos grandes e avançam aos menores', () {
    expect(
      EarTrainingLevels.intervalSemitones(1),
      List.generate(10, (i) => i + 3),
    );
    expect(EarTrainingLevels.intervalSemitones(2), [4, 7, 12]);
    expect(EarTrainingLevels.intervalSemitones(3), [2, 4, 5, 7, 12]);
    expect(EarTrainingLevels.intervalSemitones(4), [1, 2, 3, 4, 5, 7, 9, 12]);
    expect(
      EarTrainingLevels.intervalSemitones(5),
      List.generate(12, (i) => i + 1),
    );
    expect(EarTrainingLevels.intervalCanDescend(1), isTrue);
    expect(EarTrainingLevels.intervalCanDescend(3), isFalse);
    expect(EarTrainingLevels.intervalCanDescend(5), isTrue);
    expect(EarTrainingLevels.intervalName(7), '5ª justa');
    expect(EarTrainingLevels.intervalName(12), '8ª justa');
  });

  test('nota inicial sorteada mantém a chegada dentro da faixa', () {
    for (final descending in [false, true]) {
      for (var semitones = 1; semitones <= 12; semitones++) {
        final starts = EarTrainingLevels.intervalStarts(
          semitones,
          descending: descending,
        );
        expect(starts, isNotEmpty);
        for (final start in starts) {
          expect(start, inInclusiveRange(55, 67));
          final end = descending ? start - semitones : start + semitones;
          expect(end, inInclusiveRange(43, 79));
        }
      }
    }
  });
}
