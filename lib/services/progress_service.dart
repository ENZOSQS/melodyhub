import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/profile_icon_rewards.dart';
import '../domain/progress_rules.dart' as rules;
import '../utils/study_streak.dart';
import 'reminder_service.dart';

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

  /// Retorna zero quando a sequência salva ficou desatualizada após um dia
  /// inteiro sem estudo. A pessoa pode manter a sequência praticando hoje ou
  /// retomá-la no dia seguinte ao último dia estudado.
  int calcularSequenciaDiasAtual(
    Map<String, dynamic> dados, {
    DateTime? agora,
  }) {
    var ultimoDia = dados['ultimoDiaEstudo'] as String?;
    final ultimoExercicio = dados['ultimoExercicio'];
    if (ultimoDia == null && ultimoExercicio is Timestamp) {
      ultimoDia = StudyStreak.dateKey(ultimoExercicio.toDate().toLocal());
    }
    return StudyStreak.currentCount(
      savedCount: _numero(dados['sequenciaDiasAtual']),
      lastStudyDate: ultimoDia,
      now: agora ?? DateTime.now(),
    );
  }

  /// Persiste uma sequência vencida para que os dados do perfil também sejam
  /// coerentes, mesmo antes da próxima resposta a um exercício.
  Future<void> reconciliarSequenciaDias() async {
    final uid = _uid;
    if (uid == null) return;

    final referencia = _firestore.collection('usuarios').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final documento = await transaction.get(referencia);
      final dados = documento.data() ?? <String, dynamic>{};
      final atual = _numero(dados['sequenciaDiasAtual']);
      final vigente = calcularSequenciaDiasAtual(dados);
      if (vigente != atual) {
        transaction.set(referencia, {
          'sequenciaDiasAtual': vigente,
        }, SetOptions(merge: true));
      }
    });
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
    'habilidadesEtapas': <String, dynamic>{},
    'ditadosRitmicosRespondidos': 0,
    'escalasRespondidas': 0,
    'acordesRespondidos': 0,
    'questoesTeoriaRespondidas': 0,
    'acertosTeoria': 0,
    'tentativasTeoriaNivel': 0,
    'acertosTeoriaNivel': 0,
    'exerciciosPraticosRespondidos': 0,
    'nivelPratico': 1,
    'tentativasPraticasNivel': 0,
    'acertosPraticasNivel': 0,
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
  Future<void> registrarExercicio({
    required bool acertou,
    String tipo = 'Prático',
    String? pergunta,
    String? resposta,
    String? respostaCorreta,
    int duracaoSegundos = 0,
    int? duracaoMilissegundos,
    int? dificuldade,
    String? questaoId,
    String? categoria,
    String? itemAvaliado,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final referencia = _firestore.collection('usuarios').doc(uid);
    final evento = referencia.collection('historico').doc();
    final agora = DateTime.now();
    late rules.ResultadoExercicio resultado;
    await _firestore.runTransaction((transaction) async {
      final documento = await transaction.get(referencia);
      final dados = Map<String, dynamic>.from(
        documento.data() ?? <String, dynamic>{},
      );
      final ultimoExercicio = dados['ultimoExercicio'];
      if (ultimoExercicio is Timestamp) {
        dados['ultimoExercicio'] = ultimoExercicio.toDate().toLocal();
      }
      resultado = rules.aplicarExercicio(
        dados: dados,
        acertou: acertou,
        tipo: tipo,
        dificuldade: dificuldade,
        agora: agora,
      );
      transaction.set(referencia, {
        ...resultado.camposPerfil,
        'ultimoExercicio': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(evento, {
        'tipo': tipo,
        'acertou': acertou,
        'xpGanho': resultado.xpGanho,
        'pontosGanhos': resultado.pontosGanhos,
        'pergunta': pergunta,
        'resposta': resposta,
        'respostaCorreta': respostaCorreta,
        'questaoId': questaoId,
        'categoria': categoria,
        'itemAvaliado': itemAvaliado,
        'dificuldade': dificuldade,
        'duracaoSegundos': duracaoSegundos.clamp(0, 3600),
        if (duracaoMilissegundos != null)
          'duracaoMilissegundos': duracaoMilissegundos.clamp(0, 3600000),
        'data': FieldValue.serverTimestamp(),
      });
    });
    for (final conquista in resultado.conquistasNovas) {
      unawaited(
        ReminderService.instance.showAchievement(_nomeConquista(conquista)),
      );
    }
  }

  String _nomeConquista(String id) => switch (id) {
    'primeiro_exercicio' => 'Primeiro passo',
    'dez_acertos' => 'Ouvido afiado',
    'cinquenta_acertos' => 'Mestre da percepção',
    'sequencia_cinco' => 'Em sequência',
    'cinco_dias_estudados' => 'Hábito musical',
    'vinte_exercicios' => 'Prática constante',
    'cem_exercicios' => 'Cem passos musicais',
    'intervalista' => 'Caçador de intervalos',
    'mestre_intervalos' => 'Mestre dos intervalos',
    'teoria_intermediaria' => 'Teoria em movimento',
    'teoria_avancada' => 'Mente harmônica',
    'teoria_mestre' => 'Teórico especialista',
    'memoria_musical' => 'Memória musical',
    'memoria_musical_mestre' => 'Mestre das sequências',
    _ => 'Nova conquista musical',
  };

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
      final novosIconesComprados = comprados
          .where((id) => profileIconRewards.any((item) => item.id == id))
          .toSet();
      if (novosIconesComprados.length >= profileIconRewards.length &&
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
    final itens = allProfileIconRewards.where((item) => item.id == iconeId);
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

  int calcularNivel(int xp) => rules.calcularNivel(xp);

  int xpParaProximoNivel(int xp) => rules.xpParaProximoNivel(xp);

  int xpNivelAnterior(int xp) => rules.xpNivelAnterior(xp);

  int proximoNivel(int nivel) => rules.proximoNivel(nivel);

  int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;
}
