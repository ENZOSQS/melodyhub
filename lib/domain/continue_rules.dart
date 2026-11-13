/// Atividades que o cartão "Continue de onde parou" consegue reabrir.
enum AtividadeContinuar { teoria, pratica, intervalos, ritmo, escalas, acordes, violao }

/// Sugestão do cartão "Continue de onde parou", calculada a partir do último
/// evento do histórico do aluno (`usuarios/{uid}/historico`).
class SugestaoContinuar {
  const SugestaoContinuar({
    required this.atividade,
    required this.rotulo,
    this.etapa,
  });

  final AtividadeContinuar atividade;

  /// Texto exibido no cartão, por exemplo "Intervalos – Etapa 2".
  final String rotulo;
  final int? etapa;
}

/// Converte o último evento do histórico em uma sugestão. Retorna `null` quando
/// o aluno ainda não praticou ou o tipo do evento não é reconhecido.
SugestaoContinuar? sugestaoContinuar(Map<String, dynamic>? ultimoEvento) {
  if (ultimoEvento == null) return null;
  final tipo = ultimoEvento['tipo'];
  final (atividade, nome, temEtapas) = switch (tipo) {
    'Teórico' => (AtividadeContinuar.teoria, 'Teoria', true),
    'Prático' => (AtividadeContinuar.pratica, 'Identificar a nota', true),
    'Intervalo' => (AtividadeContinuar.intervalos, 'Intervalos', true),
    'Ritmo' => (AtividadeContinuar.ritmo, 'Ritmo', false),
    'Escala' => (AtividadeContinuar.escalas, 'Escalas', false),
    'Acorde' => (AtividadeContinuar.acordes, 'Acordes', false),
    'Violão' => (AtividadeContinuar.violao, 'Notas no violão', false),
    _ => (null, '', false),
  };
  if (atividade == null) return null;
  final dificuldade = ultimoEvento['dificuldade'];
  final etapa = temEtapas && dificuldade is num
      ? dificuldade.toInt().clamp(1, 5)
      : null;
  return SugestaoContinuar(
    atividade: atividade,
    etapa: etapa,
    rotulo: etapa == null ? nome : '$nome – Etapa $etapa',
  );
}
