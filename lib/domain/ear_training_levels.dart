/// Tabelas didáticas dos exercícios auditivos, sem dependências de tela.
abstract final class EarTrainingLevels {
  static const _naturals = <int>[0, 2, 4, 5, 7, 9, 11];
  static const _chromatic = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  static List<int> practiceNotes(int level) {
    _checkLevel(level);
    return switch (level) {
      1 => const [0, 4, 7],
      2 => const [0, 2, 4, 5, 7],
      3 || 4 => _naturals,
      _ => _chromatic,
    };
  }

  static int practiceSequenceLength(int level) {
    _checkLevel(level);
    return const [1, 2, 2, 3, 3][level - 1];
  }

  static List<int> intervalSemitones(int level) {
    _checkLevel(level);
    return switch (level) {
      1 => List<int>.generate(10, (index) => index + 3),
      2 => const [2, 7, 12],
      3 => const [2, 4, 5, 7, 12],
      4 || 5 => List<int>.generate(12, (index) => index + 1),
      _ => const [],
    };
  }

  static bool intervalCanDescend(int level) {
    _checkLevel(level);
    return level == 5;
  }

  static void _checkLevel(int level) {
    RangeError.checkValueInInterval(level, 1, 5, 'level');
  }
}
