/// Tabelas didáticas dos exercícios auditivos, sem dependências de tela.
abstract final class EarTrainingLevels {
  static const _naturals = <int>[0, 2, 4, 5, 7, 9, 11];

  /// Faixa das notas iniciais dos intervalos (Sol3 a Sol4): soa bem no
  /// alto-falante do celular e deixa espaço para subir ou descer uma oitava.
  static const intervalStartMin = 55;
  static const intervalStartMax = 67;

  static const _intervalNames = [
    'Uníssono',
    '2ª menor',
    '2ª maior',
    '3ª menor',
    '3ª maior',
    '4ª justa',
    'Trítono',
    '5ª justa',
    '6ª menor',
    '6ª maior',
    '7ª menor',
    '7ª maior',
    '8ª justa',
  ];

  static List<int> practiceNotes(int level) {
    _checkLevel(level);
    return switch (level) {
      1 => const [0, 7],
      2 => const [0, 4, 7],
      3 => const [0, 2, 4, 5, 7],
      _ => _naturals,
    };
  }

  /// Intervalos possíveis em cada nível, em semitons. No nível 1 o aluno só
  /// diz se o som sobe ou desce, então qualquer salto de 3 a 12 serve.
  static List<int> intervalSemitones(int level) {
    _checkLevel(level);
    return switch (level) {
      1 => List<int>.generate(10, (index) => index + 3),
      2 => const [4, 7, 12],
      3 => const [2, 4, 5, 7, 12],
      4 => const [1, 2, 3, 4, 5, 7, 9, 12],
      _ => List<int>.generate(12, (index) => index + 1),
    };
  }

  /// Só os níveis 1 (sobe ou desce?) e 5 misturam intervalos descendentes.
  static bool intervalCanDescend(int level) {
    _checkLevel(level);
    return level == 1 || level == 5;
  }

  static String intervalName(int semitones) {
    RangeError.checkValueInInterval(semitones, 0, 12, 'semitones');
    return _intervalNames[semitones];
  }

  /// Notas iniciais possíveis para um intervalo, garantindo que a nota de
  /// chegada fique entre Sol2 (43) e Sol5 (79).
  static List<int> intervalStarts(int semitones, {required bool descending}) {
    RangeError.checkValueInInterval(semitones, 0, 12, 'semitones');
    return [
      for (var midi = intervalStartMin; midi <= intervalStartMax; midi++)
        if ((descending ? midi - semitones : midi + semitones) >= 43 &&
            (descending ? midi - semitones : midi + semitones) <= 79)
          midi,
    ];
  }

  static void _checkLevel(int level) {
    RangeError.checkValueInInterval(level, 1, 5, 'level');
  }
}
