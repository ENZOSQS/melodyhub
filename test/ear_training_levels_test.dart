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
    expect(EarTrainingLevels.intervalSemitones(1), [
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
    ]);
    expect(EarTrainingLevels.intervalSemitones(2), [2, 7, 12]);
    expect(EarTrainingLevels.intervalSemitones(3), [2, 4, 5, 7, 12]);
    expect(
      EarTrainingLevels.intervalSemitones(4),
      List.generate(12, (i) => i + 1),
    );
    expect(
      EarTrainingLevels.intervalSemitones(5),
      List.generate(12, (i) => i + 1),
    );
    expect(EarTrainingLevels.intervalCanDescend(4), isFalse);
    expect(EarTrainingLevels.intervalCanDescend(5), isTrue);
  });
}
