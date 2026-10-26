import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/profile_icon_rewards.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? ouvirProgresso() {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('usuarios').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>> buscarProgresso() async {
    final uid = _uid;
    if (uid == null) return _progressoInicial();
    final documento = await _firestore.collection('usuarios').doc(uid).get();
    final dados = documento.data();
    if (dados == null) return _progressoInicial();
    return _normalizarProgresso(dados);
  }

  Map<String, dynamic> _progressoInicial() => {
    'xp': 0,
    'pontos': 0,
    'nivel': 1,
    'exerciciosRespondidos': 0,
    'acertos': 0,
    'erros': 0,
    'sequenciaAtual': 0,
    'melhorSequencia': 0,
    'sequenciaDiasAtual': 0,
    'melhorSequenciaDias': 0,
    'nivelTeoria': 1,
    'intervalosRespondidos': 0,
    'acertosIntervalos': 0,
    'nivelIntervalos': 1,
    'tentativasIntervalosNivel': 0,
    'acertosIntervalosNivel': 0,
    'teoriaEtapas': <String, dynamic>{},
    'praticaEtapas': <String, dynamic>{},
    'intervaloEtapas': <String, dynamic>{},
    'questoesTeoriaRespondidas': 0,
    'acertosTeoria': 0,
    'tentativasTeoriaNivel': 0,
    'acertosTeoriaNivel': 0,
    'exerciciosPraticosRespondidos': 0,
    'nivelPratico': 1,
    'sequenciaAcertosPraticos': 0,
    'melhorSequenciaAcertosPraticos': 0,
    'conquistas': <String>[],
    'iconesComprados': <String>[],
  };

  Map<String, dynamic> _normalizarProgresso(Map<String, dynamic> dados) => {
    ..._progressoInicial(),
    ...dados,
  };

  Future<void> adicionarXP(int quantidade) async {
    final uid = _uid;
    if (uid == null) return;
    final referencia = _firestore.collection('usuarios').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final documento = await transaction.get(referencia);
      final dados = documento.data() ?? <String, dynamic>{};
      final novoXP = _numero(dados['xp']) + quantidade;
      transaction.set(referencia, {
        'xp': novoXP,
        'nivel': calcularNivel(novoXP),
      }, SetOptions(merge: true));
    });
  }

  /// Atualiza o resumo e cria o evento de histórico em uma única transação.
  /// Assim, um exercício não fica contado no perfil sem aparecer no histórico.
  Future<void> registrarExercicio({
    required bool acertou,
    String tipo = 'Prático',
    String? pergunta,
    String? resposta,
    String? respostaCorreta,
    int duracaoSegundos = 0,
    int? dificuldade,
    String? questaoId,
    String? categoria,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final referencia = _firestore.collection('usuarios').doc(uid);
    final evento = referencia.collection('historico').doc();
    final agora = DateTime.now();
    final hoje = _chaveData(agora);

    await _firestore.runTransaction((transaction) async {
      final documento = await transaction.get(referencia);
      final dados = documento.data() ?? <String, dynamic>{};

      final total = _numero(dados['exerciciosRespondidos']) + 1;
      final acertos = _numero(dados['acertos']) + (acertou ? 1 : 0);
      final erros = _numero(dados['erros']) + (acertou ? 0 : 1);
      final xp = _numero(dados['xp']) + (acertou ? 10 : 0);
      final pontosGanhos = acertou ? 8 + 2 * (dificuldade ?? 1).clamp(1, 5) : 5;
      final pontos = _numero(dados['pontos']) + pontosGanhos;
      final sequenciaRespostas = acertou
          ? _numero(dados['sequenciaAtual']) + 1
          : 0;
      final melhorSequenciaRespostas =
          sequenciaRespostas > _numero(dados['melhorSequencia'])
          ? sequenciaRespostas
          : _numero(dados['melhorSequencia']);

      var sequenciaDias = _numero(dados['sequenciaDiasAtual']);
      var ultimoDia = dados['ultimoDiaEstudo'] as String?;
      final ultimoExercicio = dados['ultimoExercicio'];
      if (ultimoDia == null && ultimoExercicio is Timestamp) {
        ultimoDia = _chaveData(ultimoExercicio.toDate().toLocal());
        if (sequenciaDias == 0) sequenciaDias = 1;
      }
      if (ultimoDia != hoje) {
        final ontem = _chaveData(agora.subtract(const Duration(days: 1)));
        sequenciaDias = ultimoDia == ontem ? sequenciaDias + 1 : 1;
      }
      final melhorSequenciaDias =
          sequenciaDias > _numero(dados['melhorSequenciaDias'])
          ? sequenciaDias
          : _numero(dados['melhorSequenciaDias']);

      var nivelTeoria = _nivel(dados['nivelTeoria'], 5);
      var questoesTeoriaRespondidas = _numero(
        dados['questoesTeoriaRespondidas'],
      );
      var acertosTeoria = _numero(dados['acertosTeoria']);
      var tentativasTeoriaNivel = _numero(dados['tentativasTeoriaNivel']);
      var acertosTeoriaNivel = _numero(dados['acertosTeoriaNivel']);
      final teoriaEtapas = Map<String, dynamic>.from(
        dados['teoriaEtapas'] as Map? ?? const <String, dynamic>{},
      );
      if (tipo == 'Teórico') {
        questoesTeoriaRespondidas++;
        if (acertou) acertosTeoria++;
        if (dificuldade != null) {
          final etapa = Map<String, dynamic>.from(
            teoriaEtapas['$dificuldade'] as Map? ?? const <String, dynamic>{},
          );
          etapa['tentativas'] = _numero(etapa['tentativas']) + 1;
          etapa['acertos'] = _numero(etapa['acertos']) + (acertou ? 1 : 0);
          etapa['rodadaTentativas'] = _numero(etapa['rodadaTentativas']) + 1;
          etapa['rodadaAcertos'] =
              _numero(etapa['rodadaAcertos']) + (acertou ? 1 : 0);
          if (_numero(etapa['rodadaTentativas']) >= 10) {
            if (_numero(etapa['rodadaAcertos']) >= 7) {
              etapa['concluida'] = true;
            }
            etapa['rodadaTentativas'] = 0;
            etapa['rodadaAcertos'] = 0;
          }
          teoriaEtapas['$dificuldade'] = etapa;
        }
        if (dificuldade == null || dificuldade == nivelTeoria) {
          tentativasTeoriaNivel++;
          if (acertou) acertosTeoriaNivel++;
          if (tentativasTeoriaNivel >= 10) {
            if (nivelTeoria < 5 && acertosTeoriaNivel >= 7) {
              nivelTeoria++;
            }
            tentativasTeoriaNivel = 0;
            acertosTeoriaNivel = 0;
          }
        }
      }

      var nivelPratico = _nivel(dados['nivelPratico'], 5);
      var exerciciosPraticosRespondidos = _numero(
        dados['exerciciosPraticosRespondidos'],
      );
      var sequenciaAcertosPraticos = _numero(dados['sequenciaAcertosPraticos']);
      var melhorSequenciaAcertosPraticos = _numero(
        dados['melhorSequenciaAcertosPraticos'],
      );
      final praticaEtapas = Map<String, dynamic>.from(
        dados['praticaEtapas'] as Map? ?? const <String, dynamic>{},
      );
      if (tipo == 'Prático') {
        exerciciosPraticosRespondidos++;
        if (dificuldade != null) {
          final etapa = Map<String, dynamic>.from(
            praticaEtapas['$dificuldade'] as Map? ?? const <String, dynamic>{},
          );
          etapa['tentativas'] = _numero(etapa['tentativas']) + 1;
          etapa['acertos'] = _numero(etapa['acertos']) + (acertou ? 1 : 0);
          praticaEtapas['$dificuldade'] = etapa;
        }
        if (dificuldade == null || dificuldade == nivelPratico) {
          sequenciaAcertosPraticos = acertou ? sequenciaAcertosPraticos + 1 : 0;
          if (sequenciaAcertosPraticos > melhorSequenciaAcertosPraticos) {
            melhorSequenciaAcertosPraticos = sequenciaAcertosPraticos;
          }
          if (sequenciaAcertosPraticos >= nivelPratico * 3) {
            if (dificuldade != null) {
              final etapa = Map<String, dynamic>.from(
                praticaEtapas['$dificuldade'] as Map? ??
                    const <String, dynamic>{},
              );
              etapa['concluida'] = true;
              praticaEtapas['$dificuldade'] = etapa;
            }
            if (nivelPratico < 5) nivelPratico++;
          }
        }
      }

      var nivelIntervalos = _nivel(dados['nivelIntervalos'], 5);
      var intervalosRespondidos = _numero(dados['intervalosRespondidos']);
      var acertosIntervalos = _numero(dados['acertosIntervalos']);
      var tentativasIntervalosNivel = _numero(
        dados['tentativasIntervalosNivel'],
      );
      var acertosIntervalosNivel = _numero(dados['acertosIntervalosNivel']);
      final intervaloEtapas = Map<String, dynamic>.from(
        dados['intervaloEtapas'] as Map? ?? const <String, dynamic>{},
      );
      if (tipo == 'Intervalo') {
        intervalosRespondidos++;
        if (acertou) acertosIntervalos++;
        if (dificuldade != null) {
          final etapa = Map<String, dynamic>.from(
            intervaloEtapas['$dificuldade'] as Map? ??
                const <String, dynamic>{},
          );
          etapa['tentativas'] = _numero(etapa['tentativas']) + 1;
          etapa['acertos'] = _numero(etapa['acertos']) + (acertou ? 1 : 0);
          etapa['rodadaTentativas'] = _numero(etapa['rodadaTentativas']) + 1;
          etapa['rodadaAcertos'] =
              _numero(etapa['rodadaAcertos']) + (acertou ? 1 : 0);
          if (_numero(etapa['rodadaTentativas']) >= 10) {
            if (_numero(etapa['rodadaAcertos']) >= 7) {
              etapa['concluida'] = true;
            }
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
              final etapa = Map<String, dynamic>.from(
                intervaloEtapas['$nivelIntervalos'] as Map? ??
                    const <String, dynamic>{},
              );
              etapa['concluida'] = true;
              intervaloEtapas['$nivelIntervalos'] = etapa;
              nivelIntervalos++;
            } else if (nivelIntervalos == 5 && acertosIntervalosNivel >= 7) {
              final etapa = Map<String, dynamic>.from(
                intervaloEtapas['$nivelIntervalos'] as Map? ??
                    const <String, dynamic>{},
              );
              etapa['concluida'] = true;
              intervaloEtapas['$nivelIntervalos'] = etapa;
            }
            tentativasIntervalosNivel = 0;
            acertosIntervalosNivel = 0;
          }
        }
      }

      final nivel = calcularNivel(xp);
      final conquistasAtuais = List<String>.from(dados['conquistas'] ?? []);
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

      transaction.set(referencia, {
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
        'nivelPratico': nivelPratico,
        'exerciciosPraticosRespondidos': exerciciosPraticosRespondidos,
        'sequenciaAcertosPraticos': sequenciaAcertosPraticos,
        'melhorSequenciaAcertosPraticos': melhorSequenciaAcertosPraticos,
        'praticaEtapas': praticaEtapas,
        'ultimoDiaEstudo': hoje,
        'conquistas': conquistas,
        'ultimoExercicio': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(evento, {
        'tipo': tipo,
        'acertou': acertou,
        'xpGanho': acertou ? 10 : 0,
        'pontosGanhos': pontosGanhos,
        'pergunta': pergunta,
        'resposta': resposta,
        'respostaCorreta': respostaCorreta,
        'questaoId': questaoId,
        'categoria': categoria,
        'dificuldade': dificuldade,
        'duracaoSegundos': duracaoSegundos.clamp(0, 3600),
        'data': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> atualizarNome(String novoNome) async {
    final uid = _uid;
    if (uid == null) return;
    final nome = novoNome.trim();
    if (nome.isEmpty) return;
    await _firestore.collection('usuarios').doc(uid).set({
      'nome': nome,
    }, SetOptions(merge: true));
    await _auth.currentUser?.updateDisplayName(nome);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ouvirHistorico({
    int? dias,
    int? limite = 500,
  }) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    final consulta = _consultaHistorico(uid, dias);
    return limite == null
        ? consulta.snapshots()
        : consulta.limit(limite).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> buscarHistorico({
    int? dias,
    QueryDocumentSnapshot<Map<String, dynamic>>? depoisDe,
    int tamanhoPagina = 50,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError(
        'É necessário estar autenticado para consultar o histórico.',
      );
    }
    Query<Map<String, dynamic>> consulta = _consultaHistorico(uid, dias);
    if (depoisDe != null) consulta = consulta.startAfterDocument(depoisDe);
    return consulta.limit(tamanhoPagina).get();
  }

  Future<Set<String>> buscarQuestoesRecentes(int dificuldade) async {
    final uid = _uid;
    if (uid == null) return <String>{};
    final pagina = await _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('historico')
        .orderBy('data', descending: true)
        .limit(300)
        .get();
    return pagina.docs
        .map((documento) => documento.data())
        .where(
          (dados) =>
              dados['tipo'] == 'Teórico' && dados['dificuldade'] == dificuldade,
        )
        .map((dados) => dados['questaoId'])
        .whereType<String>()
        .toSet();
  }

  Query<Map<String, dynamic>> _consultaHistorico(String uid, int? dias) {
    Query<Map<String, dynamic>> consulta = _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('historico');
    if (dias != null) {
      final hoje = DateTime.now();
      final inicio = DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
      ).subtract(Duration(days: dias - 1));
      consulta = consulta.where(
        'data',
        isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
      );
    }
    return consulta.orderBy('data', descending: true);
  }

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

  Future<void> comprarIconePerfil(String iconeId) async {
    final uid = _uid;
    if (uid == null) throw StateError('Usuário não autenticado.');
    final encontrados = profileIconRewards.where((item) => item.id == iconeId);
    if (encontrados.isEmpty) throw StateError('Ícone indisponível.');
    final item = encontrados.first;
    final referencia = _firestore.collection('usuarios').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final documento = await transaction.get(referencia);
      final dados = documento.data() ?? <String, dynamic>{};
      final comprados = List<String>.from(
        dados['iconesComprados'] ?? <String>[],
      );
      if (comprados.contains(iconeId)) return;
      final pontos = _numero(dados['pontos']);
      if (pontos < item.price) {
        throw StateError('Pontos insuficientes para comprar este ícone.');
      }
      comprados.add(iconeId);
      final conquistas = List<String>.from(dados['conquistas'] ?? <String>[]);
      if (!conquistas.contains('primeira_compra')) {
        conquistas.add('primeira_compra');
      }
      if (comprados.length >= profileIconRewards.length &&
          !conquistas.contains('colecionador_icones')) {
        conquistas.add('colecionador_icones');
      }
      transaction.set(referencia, {
        'pontos': pontos - item.price,
        'iconesComprados': comprados,
        'conquistas': conquistas,
      }, SetOptions(merge: true));
    });
  }

  Future<void> atualizarIconePerfil(String? iconeId) async {
    final uid = _uid;
    if (uid == null) return;
    final itens = profileIconRewards.where((item) => item.id == iconeId);
    final referencia = _firestore.collection('usuarios').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final documento = await transaction.get(referencia);
      final conquistas = List<String>.from(
        documento.data()?['conquistas'] ?? <String>[],
      );
      final comprados = List<String>.from(
        documento.data()?['iconesComprados'] ?? <String>[],
      );
      final conquistaNecessaria = itens.isEmpty
          ? null
          : itens.first.achievementId;
      if (iconeId != null &&
          (itens.isEmpty ||
              (!comprados.contains(iconeId) &&
                  !conquistas.contains(conquistaNecessaria)))) {
        throw StateError(
          'Esta recompensa de perfil ainda não foi desbloqueada.',
        );
      }
      transaction.set(referencia, {
        'iconePerfilId': iconeId,
      }, SetOptions(merge: true));
    });
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

  int proximoNivel(int nivel) {
    switch (nivel) {
      case 1:
        return 100;
      case 2:
        return 250;
      case 3:
        return 500;
      case 4:
        return 1000;
      default:
        return 1000;
    }
  }

  int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;

  int _nivel(dynamic valor, int maximo) =>
      _numero(valor).clamp(1, maximo).toInt();

  String _chaveData(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}
