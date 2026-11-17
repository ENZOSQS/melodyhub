import 'dart:math' as math;

import 'ear_training_levels.dart';

/// Resultado de um toque do aluno numa resposta.
enum NoteAnswerOutcome { correct, tryAgain, revealed }

/// Aparência de um botão de resposta. Só muda por toque do aluno.
enum NoteButtonState { idle, wrong, correct, revealed }

/// Regras puras para o exercício funcional de identificação de notas.
abstract final class NoteIdentificationRules {
  /// Erros permitidos antes de a resposta ser revelada.
  static const int maxAttempts = 3;

  /// Sorteia a nota da questão sempre entre os botões do nível.
  static int drawTarget(int level, math.Random random) {
    final options = notesForLevel(level);
    return options[random.nextInt(options.length)];
  }

  /// Compara o toque com a nota sorteada. [attempt] conta este toque (1, 2, 3).
  static NoteAnswerOutcome evaluate({
    required int target,
    required int selected,
    required int attempt,
  }) {
    if (attempt < 1) throw RangeError.value(attempt, 'attempt');
    if (selected == target) return NoteAnswerOutcome.correct;
    return attempt >= maxAttempts
        ? NoteAnswerOutcome.revealed
        : NoteAnswerOutcome.tryAgain;
  }

  /// Estado visual de um botão. Depende só da nota sorteada, das notas que o
  /// aluno já errou e de a questão ter terminado; a resolução tocada depois do
  /// acerto não acende nenhum botão.
  static NoteButtonState buttonState({
    required int midi,
    required int target,
    required Set<int> wrongMidis,
    required bool finished,
    required bool revealed,
  }) {
    if (wrongMidis.contains(midi)) return NoteButtonState.wrong;
    if (finished && midi == target) {
      return revealed ? NoteButtonState.revealed : NoteButtonState.correct;
    }
    return NoteButtonState.idle;
  }

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
