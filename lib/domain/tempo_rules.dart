/// Regras puras do exercício de andamento (BPM): ouvir, ajustar e comparar.
class TempoResult {
  const TempoResult({
    required this.target,
    required this.guess,
    required this.correct,
    required this.stars,
  });

  final int target;
  final int guess;
  final bool correct;
  final int stars;

  /// Positivo quando o aluno marcou mais rápido que o original.
  int get difference => guess - target;

  String get description {
    final diff = difference.abs();
    if (diff == 0) return 'Exatamente igual!';
    return diff == 1
        ? '1 BPM ${difference > 0 ? 'mais rápido' : 'mais lento'}'
        : '$diff BPM ${difference > 0 ? 'mais rápido' : 'mais lento'}';
  }
}

abstract final class TempoRules {
  static const minBpm = 40;
  static const maxBpm = 220;

  static ({int min, int max}) bpmRange(int level) {
    _checkLevel(level);
    return switch (level) {
      1 => (min: 60, max: 120),
      2 => (min: 60, max: 140),
      3 => (min: 60, max: 160),
      4 => (min: 50, max: 180),
      _ => (min: 50, max: 200),
    };
  }

  static int tolerance(int level) {
    _checkLevel(level);
    return const [10, 8, 6, 4, 3][level - 1];
  }

  /// ★★★ até metade da tolerância, ★★ dentro dela, ★ até o dobro.
  static TempoResult evaluate({
    required int level,
    required int target,
    required int guess,
  }) {
    final diff = (guess - target).abs();
    final tol = tolerance(level);
    final stars = diff * 2 <= tol
        ? 3
        : diff <= tol
        ? 2
        : diff <= tol * 2
        ? 1
        : 0;
    return TempoResult(
      target: target,
      guess: guess,
      correct: diff <= tol,
      stars: stars,
    );
  }

  /// Valor inicial do ajuste: longe o bastante do alvo para exigir escuta,
  /// sem sair da faixa permitida.
  static int startingGuess(int target, int offset) {
    final candidate = target + offset;
    if (candidate < minBpm || candidate > maxBpm) return target - offset;
    return candidate;
  }

  static int clampBpm(int value) => value.clamp(minBpm, maxBpm).toInt();

  static int beatMs(int bpm) => (60000 / bpm).round();

  static void _checkLevel(int level) {
    RangeError.checkValueInInterval(level, 1, 5, 'level');
  }
}
