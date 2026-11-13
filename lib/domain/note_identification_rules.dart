import 'ear_training_levels.dart';

/// Regras puras para o exercício funcional de identificação de notas.
abstract final class NoteIdentificationRules {
  static const List<List<int>> cadenceChords = [
    [48, 52, 55], // Dó maior
    [53, 57, 60], // Fá maior
    [55, 59, 62], // Sol maior
    [60, 64, 67], // Dó maior
  ];

  static List<int> notesForLevel(int level) {
    final degrees = EarTrainingLevels.practiceNotes(level);
    final firstOctave = level == 5 ? 48 : 60;
    final octaves = level == 5 ? 2 : 1;
    return [
      for (var octave = 0; octave < octaves; octave++)
        for (final degree in degrees) firstOctave + octave * 12 + degree,
    ];
  }

  static List<int> resolutionFor(int midi) {
    final degree = ((midi % 12) + 12) % 12;
    final octaveRoot = midi - degree;
    final degrees = switch (degree) {
      0 => const [0],
      2 => const [2, 0],
      4 => const [4, 2, 0],
      5 => const [5, 4, 2, 0],
      7 => const [7, 9, 11, 12],
      9 => const [9, 11, 12],
      11 => const [11, 12],
      _ => throw ArgumentError.value(
        midi,
        'midi',
        'Nota fora da escala de Dó maior',
      ),
    };
    return degrees.map((step) => octaveRoot + step).toList();
  }

  static String criticalItemFor(int midi) {
    final name = switch (((midi % 12) + 12) % 12) {
      0 => 'Do',
      2 => 'Re',
      4 => 'Mi',
      5 => 'Fa',
      7 => 'Sol',
      9 => 'La',
      11 => 'Si',
      _ => throw ArgumentError.value(
        midi,
        'midi',
        'Nota fora da escala de Dó maior',
      ),
    };
    return 'nota_$name';
  }
}
