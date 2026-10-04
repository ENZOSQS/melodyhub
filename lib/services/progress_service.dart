import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<DocumentSnapshot<Map<String, dynamic>>>?
      ouvirProgresso() {
    final uid = _uid;

    if (uid == null) {
      return null;
    }

    return _firestore
        .collection('usuarios')
        .doc(uid)
        .snapshots();
  }

  Future<Map<String, dynamic>> buscarProgresso() async {
    final uid = _uid;

    if (uid == null) {
      return _progressoInicial();
    }

    final documento = await _firestore
        .collection('usuarios')
        .doc(uid)
        .get();

    final dados = documento.data();

    if (dados == null) {
      return _progressoInicial();
    }

    return _normalizarProgresso(dados);
  }

  Map<String, dynamic> _progressoInicial() {
    return {
      'xp': 0,
      'nivel': 1,
      'exerciciosRespondidos': 0,
      'acertos': 0,
      'erros': 0,
      'sequenciaAtual': 0,
      'melhorSequencia': 0,
      'conquistas': <String>[],
    };
  }

  Map<String, dynamic> _normalizarProgresso(
    Map<String, dynamic> dados,
  ) {
    return {
      'xp': dados['xp'] ?? 0,
      'nivel': dados['nivel'] ?? 1,
      'exerciciosRespondidos':
          dados['exerciciosRespondidos'] ?? 0,
      'acertos': dados['acertos'] ?? 0,
      'erros': dados['erros'] ?? 0,
      'sequenciaAtual':
          dados['sequenciaAtual'] ?? 0,
      'melhorSequencia':
          dados['melhorSequencia'] ?? 0,
      'conquistas':
          dados['conquistas'] ?? <String>[],
    };
  }

  Future<void> adicionarXP(
    int quantidade,
  ) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    final referencia = _firestore
        .collection('usuarios')
        .doc(uid);

    final documento =
        await referencia.get();

    final dados =
        documento.data() ?? {};

    final xpAtual =
        _numero(dados['xp']);

    final novoXP =
        xpAtual + quantidade;

    final novoNivel =
        calcularNivel(novoXP);

    await referencia.set(
      {
        'xp': novoXP,
        'nivel': novoNivel,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> registrarExercicio({
    required bool acertou,
  }) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    final referencia = _firestore
        .collection('usuarios')
        .doc(uid);

    final documento =
        await referencia.get();

    final dados =
        documento.data() ?? {};

    final exerciciosAtuais =
        _numero(
      dados['exerciciosRespondidos'],
    );

    final acertosAtuais =
        _numero(
      dados['acertos'],
    );

    final errosAtuais =
        _numero(
      dados['erros'],
    );

    final xpAtual =
        _numero(
      dados['xp'],
    );

    final sequenciaAtual =
        _numero(
      dados['sequenciaAtual'],
    );

    final melhorSequencia =
        _numero(
      dados['melhorSequencia'],
    );

    final novoTotalExercicios =
        exerciciosAtuais + 1;

    final novosAcertos = acertou
        ? acertosAtuais + 1
        : acertosAtuais;

    final novosErros = acertou
        ? errosAtuais
        : errosAtuais + 1;

    final novaSequencia = acertou
        ? sequenciaAtual + 1
        : 0;

    final novaMelhorSequencia =
        novaSequencia > melhorSequencia
            ? novaSequencia
            : melhorSequencia;

    final xpGanho =
        acertou ? 10 : 0;

    final novoXP =
        xpAtual + xpGanho;

    final novoNivel =
        calcularNivel(novoXP);

    final conquistasAtuais =
        List<String>.from(
      dados['conquistas'] ?? [],
    );

    final novasConquistas =
        _verificarConquistas(
      exerciciosRespondidos:
          novoTotalExercicios,
      acertos: novosAcertos,
      xp: novoXP,
      nivel: novoNivel,
      melhorSequencia:
          novaMelhorSequencia,
      conquistasAtuais:
          conquistasAtuais,
    );

    await referencia.set(
      {
        'xp': novoXP,
        'nivel': novoNivel,
        'exerciciosRespondidos':
            novoTotalExercicios,
        'acertos': novosAcertos,
        'erros': novosErros,
        'sequenciaAtual':
            novaSequencia,
        'melhorSequencia':
            novaMelhorSequencia,
        'conquistas':
            novasConquistas,
        'ultimoExercicio':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  List<String> _verificarConquistas({
    required int exerciciosRespondidos,
    required int acertos,
    required int xp,
    required int nivel,
    required int melhorSequencia,
    required List<String> conquistasAtuais,
  }) {
    final conquistas =
        List<String>.from(
      conquistasAtuais,
    );

    void adicionar(String id) {
      if (!conquistas.contains(id)) {
        conquistas.add(id);
      }
    }

    if (exerciciosRespondidos >= 1) {
      adicionar('primeiro_exercicio');
    }

    if (acertos >= 10) {
      adicionar('dez_acertos');
    }

    if (acertos >= 50) {
      adicionar('cinquenta_acertos');
    }

    if (melhorSequencia >= 5) {
      adicionar('sequencia_cinco');
    }

    if (xp >= 100) {
      adicionar('cem_xp');
    }

    if (xp >= 500) {
      adicionar('quinhentos_xp');
    }

    if (nivel >= 5) {
      adicionar('nivel_cinco');
    }

    return conquistas;
  }

  int calcularNivel(int xp) {
    if (xp >= 1000) {
      return 5;
    }

    if (xp >= 500) {
      return 4;
    }

    if (xp >= 250) {
      return 3;
    }

    if (xp >= 100) {
      return 2;
    }

    return 1;
  }

  int xpParaProximoNivel(int xp) {
    if (xp < 100) {
      return 100 - xp;
    }

    if (xp < 250) {
      return 250 - xp;
    }

    if (xp < 500) {
      return 500 - xp;
    }

    if (xp < 1000) {
      return 1000 - xp;
    }

    return 0;
  }

  int xpNivelAnterior(int xp) {
    if (xp < 100) {
      return 0;
    }

    if (xp < 250) {
      return 100;
    }

    if (xp < 500) {
      return 250;
    }

    if (xp < 1000) {
      return 500;
    }

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

  int _numero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return 0;
  }
}