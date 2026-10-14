import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    'nivel': 1,
    'exerciciosRespondidos': 0,
    'acertos': 0,
    'erros': 0,
    'sequenciaAtual': 0,
    'melhorSequencia': 0,
    'sequenciaDiasAtual': 0,
    'melhorSequenciaDias': 0,
    'conquistas': <String>[],
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

      final nivel = calcularNivel(xp);
      final conquistasAtuais = List<String>.from(dados['conquistas'] ?? []);
      final conquistas = _verificarConquistas(
        exerciciosRespondidos: total,
        acertos: acertos,
        xp: xp,
        nivel: nivel,
        melhorSequenciaRespostas: melhorSequenciaRespostas,
        melhorSequenciaDias: melhorSequenciaDias,
        conquistasAtuais: conquistasAtuais,
      );

      transaction.set(referencia, {
        'xp': xp,
        'nivel': nivel,
        'exerciciosRespondidos': total,
        'acertos': acertos,
        'erros': erros,
        // Mantido por compatibilidade; representa acertos consecutivos.
        'sequenciaAtual': sequenciaRespostas,
        'melhorSequencia': melhorSequenciaRespostas,
        'sequenciaDiasAtual': sequenciaDias,
        'melhorSequenciaDias': melhorSequenciaDias,
        'ultimoDiaEstudo': hoje,
        'conquistas': conquistas,
        'ultimoExercicio': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(evento, {
        'tipo': tipo,
        'acertou': acertou,
        'xpGanho': acertou ? 10 : 0,
        'pergunta': pergunta,
        'resposta': resposta,
        'respostaCorreta': respostaCorreta,
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
    required int melhorSequenciaRespostas,
    required int melhorSequenciaDias,
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
    return conquistas;
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

  String _chaveData(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-'
      '${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';
}
