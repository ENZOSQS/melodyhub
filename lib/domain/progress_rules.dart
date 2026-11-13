import '../utils/xp_calculator.dart';
import '../utils/study_streak.dart';

/// Resultado determinístico das regras aplicadas a uma resposta.
///
/// [camposPerfil] contém somente valores Dart serializáveis que o serviço deve
/// persistir no documento do usuário. Timestamps do Firestore continuam sendo
/// responsabilidade da camada de persistência.
class ResultadoExercicio {
  const ResultadoExercicio({
    required this.camposPerfil,
    required this.xpGanho,
    required this.pontosGanhos,
    required this.conquistasNovas,
  });

  final Map<String, dynamic> camposPerfil;
  final int xpGanho;
  final int pontosGanhos;
  final List<String> conquistasNovas;
}

/// Calcula em memória a atualização de gamificação de uma resposta.
///
/// Não acessa Firebase, relógio do sistema, plugins ou estado global; [agora]
/// torna determinística a regra de sequência diária.
ResultadoExercicio aplicarExercicio({
  required Map<String, dynamic> dados,
  required bool acertou,
  required String tipo,
  int? dificuldade,
  required DateTime agora,
}) {
  final total = _numero(dados['exerciciosRespondidos']) + 1;
  final acertos = _numero(dados['acertos']) + (acertou ? 1 : 0);
  final erros = _numero(dados['erros']) + (acertou ? 0 : 1);
  final xpGanho = XpCalculator.calculateXp(acertou);
  final xp = _numero(dados['xp']) + xpGanho;
  final nivel = calcularNivel(xp);
  final pontosGanhos = acertou
      ? 8 + 2 * (dificuldade ?? 1).clamp(1, 5).toInt()
      : 5;
  final pontos = _numero(dados['pontos']) + pontosGanhos;

  final sequenciaRespostas = acertou ? _numero(dados['sequenciaAtual']) + 1 : 0;
  final melhorSequenciaRespostas = _max(
    sequenciaRespostas,
    _numero(dados['melhorSequencia']),
  );

  final hoje = StudyStreak.dateKey(agora);
  var sequenciaDias = _numero(dados['sequenciaDiasAtual']);
  var ultimoDia = dados['ultimoDiaEstudo'] as String?;
  final ultimoExercicio = dados['ultimoExercicio'];
  if (ultimoDia == null && ultimoExercicio is DateTime) {
    ultimoDia = StudyStreak.dateKey(ultimoExercicio.toLocal());
    if (sequenciaDias == 0) sequenciaDias = 1;
  }
  if (ultimoDia != hoje) {
    final ontem = StudyStreak.dateKey(agora.subtract(const Duration(days: 1)));
    sequenciaDias = ultimoDia == ontem ? sequenciaDias + 1 : 1;
  }
  final melhorSequenciaDias = _max(
    sequenciaDias,
    _numero(dados['melhorSequenciaDias']),
  );

  var nivelTeoria = _nivel(dados['nivelTeoria'], 5);
  var questoesTeoriaRespondidas = _numero(dados['questoesTeoriaRespondidas']);
  var acertosTeoria = _numero(dados['acertosTeoria']);
  var tentativasTeoriaNivel = _numero(dados['tentativasTeoriaNivel']);
  var acertosTeoriaNivel = _numero(dados['acertosTeoriaNivel']);
  final teoriaEtapas = _mapa(dados['teoriaEtapas']);
  if (tipo == 'Teórico') {
    questoesTeoriaRespondidas++;
    if (acertou) acertosTeoria++;
    if (dificuldade != null) {
      final etapa = _mapa(teoriaEtapas['$dificuldade']);
      etapa['tentativas'] = _numero(etapa['tentativas']) + 1;
      etapa['acertos'] = _numero(etapa['acertos']) + (acertou ? 1 : 0);
      etapa['rodadaTentativas'] = _numero(etapa['rodadaTentativas']) + 1;
      etapa['rodadaAcertos'] =
          _numero(etapa['rodadaAcertos']) + (acertou ? 1 : 0);
      if (_numero(etapa['rodadaTentativas']) >= 10) {
        if (_numero(etapa['rodadaAcertos']) >= 7) etapa['concluida'] = true;
        etapa['rodadaTentativas'] = 0;
        etapa['rodadaAcertos'] = 0;
      }
      teoriaEtapas['$dificuldade'] = etapa;
    }
    if (dificuldade == null || dificuldade == nivelTeoria) {
      tentativasTeoriaNivel++;
      if (acertou) acertosTeoriaNivel++;
      if (tentativasTeoriaNivel >= 10) {
        if (nivelTeoria < 5 && acertosTeoriaNivel >= 7) nivelTeoria++;
        tentativasTeoriaNivel = 0;
        acertosTeoriaNivel = 0;
      }
    }
  }

  var nivelPratico = _nivel(dados['nivelPratico'], 5);
  var exerciciosPraticosRespondidos = _numero(
    dados['exerciciosPraticosRespondidos'],
  );
  var tentativasPraticasNivel = _numero(dados['tentativasPraticasNivel']);
  var acertosPraticasNivel = _numero(dados['acertosPraticasNivel']);
  var sequenciaAcertosPraticos = _numero(dados['sequenciaAcertosPraticos']);
  var melhorSequenciaAcertosPraticos = _numero(
    dados['melhorSequenciaAcertosPraticos'],
  );
  final praticaEtapas = _mapa(dados['praticaEtapas']);
  if (tipo == 'Prático') {
    exerciciosPraticosRespondidos++;
    final nivelDoExercicio = dificuldade ?? nivelPratico;
    final etapa = _mapa(praticaEtapas['$nivelDoExercicio']);
    etapa['tentativas'] = _numero(etapa['tentativas']) + 1;
    etapa['acertos'] = _numero(etapa['acertos']) + (acertou ? 1 : 0);
    if (nivelDoExercicio == nivelPratico) {
      tentativasPraticasNivel++;
      if (acertou) acertosPraticasNivel++;
      etapa['rodadaTentativas'] = tentativasPraticasNivel;
      etapa['rodadaAcertos'] = acertosPraticasNivel;
      if (tentativasPraticasNivel >= 10) {
        if (acertosPraticasNivel >= 7) {
          etapa['concluida'] = true;
          if (nivelPratico < 5) nivelPratico++;
        }
        tentativasPraticasNivel = 0;
        acertosPraticasNivel = 0;
        etapa['rodadaTentativas'] = 0;
        etapa['rodadaAcertos'] = 0;
      }
      sequenciaAcertosPraticos = acertou ? sequenciaAcertosPraticos + 1 : 0;
      melhorSequenciaAcertosPraticos = _max(
        sequenciaAcertosPraticos,
        melhorSequenciaAcertosPraticos,
      );
    }
    praticaEtapas['$nivelDoExercicio'] = etapa;
  }

  var nivelIntervalos = _nivel(dados['nivelIntervalos'], 5);
  var intervalosRespondidos = _numero(dados['intervalosRespondidos']);
  var acertosIntervalos = _numero(dados['acertosIntervalos']);
  var tentativasIntervalosNivel = _numero(dados['tentativasIntervalosNivel']);
  var acertosIntervalosNivel = _numero(dados['acertosIntervalosNivel']);
  final intervaloEtapas = _mapa(dados['intervaloEtapas']);
  if (tipo == 'Intervalo') {
    intervalosRespondidos++;
    if (acertou) acertosIntervalos++;
    if (dificuldade != null) {
      final etapa = _mapa(intervaloEtapas['$dificuldade']);
      etapa['tentativas'] = _numero(etapa['tentativas']) + 1;
      etapa['acertos'] = _numero(etapa['acertos']) + (acertou ? 1 : 0);
      etapa['rodadaTentativas'] = _numero(etapa['rodadaTentativas']) + 1;
      etapa['rodadaAcertos'] =
          _numero(etapa['rodadaAcertos']) + (acertou ? 1 : 0);
      if (_numero(etapa['rodadaTentativas']) >= 10) {
        if (_numero(etapa['rodadaAcertos']) >= 7) etapa['concluida'] = true;
        etapa['rodadaTentativas'] = 0;
        etapa['rodadaAcertos'] = 0;
      }
      intervaloEtapas['$dificuldade'] = etapa;
    }
    if (dificuldade == null || dificuldade == nivelIntervalos) {
      tentativasIntervalosNivel++;
      if (acertou) acertosIntervalosNivel++;
      if (tentativasIntervalosNivel >= 10) {
        if (nivelIntervalos < 5 && acertosIntervalosNivel >= 7) {
          final etapa = _mapa(intervaloEtapas['$nivelIntervalos']);
          etapa['concluida'] = true;
          intervaloEtapas['$nivelIntervalos'] = etapa;
          nivelIntervalos++;
        } else if (nivelIntervalos == 5 && acertosIntervalosNivel >= 7) {
          final etapa = _mapa(intervaloEtapas['$nivelIntervalos']);
          etapa['concluida'] = true;
          intervaloEtapas['$nivelIntervalos'] = etapa;
        }
        tentativasIntervalosNivel = 0;
        acertosIntervalosNivel = 0;
      }
    }
  }

  final habilidadesEtapas = _mapa(dados['habilidadesEtapas']);
  var ditadosRitmicosRespondidos = _numero(dados['ditadosRitmicosRespondidos']);
  var escalasRespondidas = _numero(dados['escalasRespondidas']);
  // O exercício auditivo de acordes saiu do escopo; o contador antigo só é
  // preservado para não apagar dados de quem já tinha praticado.
  final acordesRespondidos = _numero(dados['acordesRespondidos']);
  if (tipo == 'Ritmo' || tipo == 'Escala') {
    final habilidade = tipo == 'Ritmo' ? 'ritmo' : 'escalas';
    if (tipo == 'Ritmo') ditadosRitmicosRespondidos++;
    if (tipo == 'Escala') escalasRespondidas++;

    final etapasDaHabilidade = _mapa(habilidadesEtapas[habilidade]);
    final nivelAtual = _nivel(etapasDaHabilidade['nivel'], 5);
    final nivelDoExercicio = (dificuldade ?? nivelAtual).clamp(1, 5).toInt();
    final etapa = _mapa(etapasDaHabilidade['$nivelDoExercicio']);
    final tentativas = _numero(etapa['rodadaTentativas']) + 1;
    final acertosDaRodada = _numero(etapa['rodadaAcertos']) + (acertou ? 1 : 0);
    etapa['tentativas'] = _numero(etapa['tentativas']) + 1;
    etapa['acertos'] = _numero(etapa['acertos']) + (acertou ? 1 : 0);
    if (tentativas >= 10) {
      etapa['concluida'] = acertosDaRodada >= 7;
      etapa['rodadaTentativas'] = 0;
      etapa['rodadaAcertos'] = 0;
      if (acertosDaRodada >= 7 && nivelDoExercicio == nivelAtual) {
        etapasDaHabilidade['nivel'] = nivelAtual < 5 ? nivelAtual + 1 : 5;
      }
    } else {
      etapa['rodadaTentativas'] = tentativas;
      etapa['rodadaAcertos'] = acertosDaRodada;
    }
    etapasDaHabilidade['$nivelDoExercicio'] = etapa;
    etapasDaHabilidade['nivel'] = _nivel(
      etapasDaHabilidade['nivel'] ?? nivelAtual,
      5,
    );
    habilidadesEtapas[habilidade] = etapasDaHabilidade;
  }

  final conquistasAtuais = List<String>.from(
    dados['conquistas'] as List? ?? const <String>[],
  );
  final conquistas = _verificarConquistas(
    exerciciosRespondidos: total,
    acertos: acertos,
    xp: xp,
    nivel: nivel,
    pontos: pontos,
    melhorSequenciaRespostas: melhorSequenciaRespostas,
    melhorSequenciaDias: melhorSequenciaDias,
    nivelTeoria: nivelTeoria,
    nivelPratico: nivelPratico,
    nivelIntervalos: nivelIntervalos,
    intervalosRespondidos: intervalosRespondidos,
    totalTeoria: questoesTeoriaRespondidas,
    totalPratico: exerciciosPraticosRespondidos,
    precisaoTeoria: questoesTeoriaRespondidas == 0
        ? 0.0
        : acertosTeoria * 100 / questoesTeoriaRespondidas,
    conquistasAtuais: conquistasAtuais,
  );

  final camposPerfil = <String, dynamic>{
    'xp': xp,
    'pontos': pontos,
    'nivel': nivel,
    'exerciciosRespondidos': total,
    'acertos': acertos,
    'erros': erros,
    // Mantido por compatibilidade; representa acertos consecutivos.
    'sequenciaAtual': sequenciaRespostas,
    'melhorSequencia': melhorSequenciaRespostas,
    'sequenciaDiasAtual': sequenciaDias,
    'melhorSequenciaDias': melhorSequenciaDias,
    'nivelTeoria': nivelTeoria,
    'questoesTeoriaRespondidas': questoesTeoriaRespondidas,
    'acertosTeoria': acertosTeoria,
    'tentativasTeoriaNivel': tentativasTeoriaNivel,
    'acertosTeoriaNivel': acertosTeoriaNivel,
    'teoriaEtapas': teoriaEtapas,
    'nivelIntervalos': nivelIntervalos,
    'intervalosRespondidos': intervalosRespondidos,
    'acertosIntervalos': acertosIntervalos,
    'tentativasIntervalosNivel': tentativasIntervalosNivel,
    'acertosIntervalosNivel': acertosIntervalosNivel,
    'intervaloEtapas': intervaloEtapas,
    'habilidadesEtapas': habilidadesEtapas,
    'ditadosRitmicosRespondidos': ditadosRitmicosRespondidos,
    'escalasRespondidas': escalasRespondidas,
    'acordesRespondidos': acordesRespondidos,
    'nivelPratico': nivelPratico,
    'tentativasPraticasNivel': tentativasPraticasNivel,
    'acertosPraticasNivel': acertosPraticasNivel,
    'exerciciosPraticosRespondidos': exerciciosPraticosRespondidos,
    'sequenciaAcertosPraticos': sequenciaAcertosPraticos,
    'melhorSequenciaAcertosPraticos': melhorSequenciaAcertosPraticos,
    'praticaEtapas': praticaEtapas,
    'ultimoDiaEstudo': hoje,
    'conquistas': conquistas,
  };
  return ResultadoExercicio(
    camposPerfil: camposPerfil,
    xpGanho: xpGanho,
    pontosGanhos: pontosGanhos,
    conquistasNovas: conquistas
        .where((conquista) => !conquistasAtuais.contains(conquista))
        .toList(),
  );
}

int calcularNivel(int xp) {
  if (xp >= 1000) return 5;
  if (xp >= 500) return 4;
  if (xp >= 250) return 3;
  if (xp >= 100) return 2;
  return 1;
}

int xpParaProximoNivel(int xp) {
  if (xp < 100) return 100 - xp;
  if (xp < 250) return 250 - xp;
  if (xp < 500) return 500 - xp;
  if (xp < 1000) return 1000 - xp;
  return 0;
}

int xpNivelAnterior(int xp) {
  if (xp < 100) return 0;
  if (xp < 250) return 100;
  if (xp < 500) return 250;
  if (xp < 1000) return 500;
  return 1000;
}

int proximoNivel(int nivel) => switch (nivel) {
  1 => 100,
  2 => 250,
  3 => 500,
  4 => 1000,
  _ => 1000,
};

List<String> _verificarConquistas({
  required int exerciciosRespondidos,
  required int acertos,
  required int xp,
  required int nivel,
  required int pontos,
  required int melhorSequenciaRespostas,
  required int melhorSequenciaDias,
  required int nivelTeoria,
  required int nivelPratico,
  required int nivelIntervalos,
  required int intervalosRespondidos,
  required int totalTeoria,
  required int totalPratico,
  required double precisaoTeoria,
  required List<String> conquistasAtuais,
}) {
  final conquistas = List<String>.from(conquistasAtuais);
  void adicionar(String id) {
    if (!conquistas.contains(id)) conquistas.add(id);
  }

  if (exerciciosRespondidos >= 1) adicionar('primeiro_exercicio');
  if (acertos >= 10) adicionar('dez_acertos');
  if (acertos >= 50) adicionar('cinquenta_acertos');
  if (melhorSequenciaRespostas >= 5) adicionar('sequencia_cinco');
  if (melhorSequenciaDias >= 5) adicionar('cinco_dias_estudados');
  if (xp >= 100) adicionar('cem_xp');
  if (xp >= 500) adicionar('quinhentos_xp');
  if (nivel >= 5) adicionar('nivel_cinco');
  if (exerciciosRespondidos >= 20) adicionar('vinte_exercicios');
  if (exerciciosRespondidos >= 100) adicionar('cem_exercicios');
  if (melhorSequenciaDias >= 20) adicionar('vinte_dias_estudados');
  if (totalTeoria >= 20 && precisaoTeoria >= 90) {
    adicionar('precisao_noventa');
  }
  if (nivelTeoria >= 2) adicionar('teoria_intermediaria');
  if (nivelTeoria >= 3) adicionar('teoria_avancada');
  if (nivelTeoria >= 5) adicionar('teoria_mestre');
  if (nivelPratico >= 3) adicionar('memoria_musical');
  if (nivelPratico >= 5) adicionar('memoria_musical_mestre');
  if (totalPratico >= 100) adicionar('cem_exercicios_praticos');
  if (intervalosRespondidos >= 10) adicionar('intervalista');
  if (intervalosRespondidos >= 50) adicionar('mestre_intervalos');
  if (nivelIntervalos >= 5) adicionar('ouvido_harmonico');
  if (pontos >= 100) adicionar('primeiros_pontos');
  return conquistas;
}

Map<String, dynamic> _mapa(dynamic valor) =>
    valor is Map ? Map<String, dynamic>.from(valor) : <String, dynamic>{};

int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;

int _nivel(dynamic valor, int maximo) =>
    _numero(valor).clamp(1, maximo).toInt();

int _max(int primeiro, int segundo) => primeiro > segundo ? primeiro : segundo;
