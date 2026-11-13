/// Tabelas didáticas dos exercícios auditivos, sem dependências de tela.
abstract final class EarTrainingLevels {
  static const _naturals = <int>[0, 2, 4, 5, 7, 9, 11];
  static List<int> practiceNotes(int level) {
    _checkLevel(level);
    return switch (level) {
      1 => const [0, 7],
      2 => const [0, 4, 7],
      3 => const [0, 2, 4, 5, 7],
      _ => _naturals,
    };
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
