import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/domain/progress_rules.dart';

final _hoje = DateTime(2026, 10, 20, 12);

Map<String, dynamic> _rodada({
  required String tipo,
  required int acertos,
  required int nivel,
  required String campoNivel,
}) {
  var dados = <String, dynamic>{campoNivel: nivel};
  for (var i = 0; i < 10; i++) {
    dados = aplicarExercicio(
      dados: dados,
      acertou: i < acertos,
      tipo: tipo,
      dificuldade: nivel,
      agora: _hoje,
    ).camposPerfil;
  }
  return dados;
}

void main() {
  test('XP, pontos e limites de nível', () {
    for (var dificuldade = 1; dificuldade <= 5; dificuldade++) {
      final r = aplicarExercicio(
        dados: {},
        acertou: true,
        tipo: 'Prático',
        dificuldade: dificuldade,
        agora: _hoje,
      );
      expect(r.xpGanho, 10);
      expect(r.pontosGanhos, 8 + 2 * dificuldade);
    }
    final erro = aplicarExercicio(
      dados: {},
      acertou: false,
      tipo: 'Prático',
      agora: _hoje,
    );
    expect(erro.xpGanho, 0);
    expect(erro.pontosGanhos, 5);
    for (final caso in {
      99: 1,
      100: 2,
      249: 2,
      250: 3,
      499: 3,
      500: 4,
      999: 4,
      1000: 5,
    }.entries) {
      expect(calcularNivel(caso.key), caso.value);
    }
    expect(xpParaProximoNivel(99), 1);
    expect(xpNivelAnterior(250), 250);
    expect(proximoNivel(4), 1000);
  });

  test('teoria avança com 7/10, não com 6/10 e não passa de 5', () {
    expect(
      _rodada(
        tipo: 'Teórico',
        acertos: 7,
        nivel: 1,
        campoNivel: 'nivelTeoria',
      )['nivelTeoria'],
      2,
    );
    expect(
      _rodada(
        tipo: 'Teórico',
        acertos: 6,
        nivel: 1,
        campoNivel: 'nivelTeoria',
      )['nivelTeoria'],
      1,
    );
    expect(
      _rodada(
        tipo: 'Teórico',
        acertos: 10,
        nivel: 5,
        campoNivel: 'nivelTeoria',
      )['nivelTeoria'],
      5,
    );
  });

  for (final tipo in ['Prático', 'Intervalo']) {
    test('$tipo exige 7/10, conclui etapa e limita o nível em 5', () {
      final campo = tipo == 'Prático' ? 'nivelPratico' : 'nivelIntervalos';
      final etapa = tipo == 'Prático' ? 'praticaEtapas' : 'intervaloEtapas';
      final passou = _rodada(
        tipo: tipo,
        acertos: 7,
        nivel: 1,
        campoNivel: campo,
      );
      final falhou = _rodada(
        tipo: tipo,
        acertos: 6,
        nivel: 1,
        campoNivel: campo,
      );
      expect(passou[campo], 2);
      expect((passou[etapa] as Map)['1']['concluida'], isTrue);
      expect(falhou[campo], 1);
      expect(
        _rodada(tipo: tipo, acertos: 10, nivel: 5, campoNivel: campo)[campo],
        5,
      );
    });
  }

  for (final tipo in ['Ritmo', 'Escala']) {
    test('habilidade $tipo progride em habilidadesEtapas', () {
      final dados = _rodada(
        tipo: tipo,
        acertos: 7,
        nivel: 1,
        campoNivel: 'unused',
      );
      final chave = {
        'Ritmo': 'ritmo',
        'Escala': 'escalas',
      }[tipo]!;
      final habilidade = (dados['habilidadesEtapas'] as Map)[chave] as Map;
      expect(habilidade['nivel'], 2);
      expect(habilidade['1']['concluida'], isTrue);
    });
  }

  test('sequência de dias considera mesmo dia, próximo, pausa e mês', () {
    Map<String, dynamic> responder(Map<String, dynamic> dados, DateTime dia) =>
        aplicarExercicio(
          dados: dados,
          acertou: true,
          tipo: 'Prático',
          agora: dia,
        ).camposPerfil;
    var dados = responder({
      'sequenciaDiasAtual': 2,
      'ultimoDiaEstudo': '2026-10-20',
    }, _hoje);
    expect(dados['sequenciaDiasAtual'], 2);
    dados = responder(dados, DateTime(2026, 10, 21, 12));
    expect(dados['sequenciaDiasAtual'], 3);
    dados = responder(dados, DateTime(2026, 10, 23, 12));
    expect(dados['sequenciaDiasAtual'], 1);
    dados = responder({
      'sequenciaDiasAtual': 2,
      'ultimoDiaEstudo': '2026-02-28',
    }, DateTime(2026, 3, 1, 12));
    expect(dados['sequenciaDiasAtual'], 3);
  });

  test('recupera sequência legada a partir de ultimoExercicio DateTime', () {
    final resultado = aplicarExercicio(
      dados: {
        'sequenciaDiasAtual': 1,
        'ultimoExercicio': _hoje.subtract(const Duration(days: 1)),
      },
      acertou: true,
      tipo: 'Prático',
      agora: _hoje,
    );
    expect(resultado.camposPerfil['sequenciaDiasAtual'], 2);
    expect(resultado.camposPerfil['ultimoDiaEstudo'], '2026-10-20');
  });

  test(
    'teoria abaixo do nível atual conclui a etapa sem mudar a rodada atual',
    () {
      var dados = <String, dynamic>{'nivelTeoria': 3};
      for (var i = 0; i < 10; i++) {
        dados = aplicarExercicio(
          dados: dados,
          acertou: true,
          tipo: 'Teórico',
          dificuldade: 1,
          agora: _hoje,
        ).camposPerfil;
      }
      expect(dados['nivelTeoria'], 3);
      expect(dados['tentativasTeoriaNivel'], 0);
      expect((dados['teoriaEtapas'] as Map)['1']['concluida'], isTrue);
    },
  );

  test('conquistas solicitadas são concedidas sem duplicação', () {
    var dados = <String, dynamic>{};
    for (var i = 0; i < 10; i++) {
      final r = aplicarExercicio(
        dados: dados,
        acertou: true,
        tipo: 'Prático',
        agora: _hoje,
      );
      dados = r.camposPerfil;
      if (i == 0) expect(r.conquistasNovas, contains('primeiro_exercicio'));
      if (i == 4) expect(r.conquistasNovas, contains('sequencia_cinco'));
      if (i == 9) expect(r.conquistasNovas, contains('dez_acertos'));
    }
    final conquistas = dados['conquistas'] as List;
    expect(conquistas.toSet().length, conquistas.length);
    final repetido = aplicarExercicio(
      dados: {
        'conquistas': ['primeiro_exercicio'],
        'exerciciosRespondidos': 1,
      },
      acertou: false,
      tipo: 'Prático',
      agora: _hoje,
    );
    expect(repetido.conquistasNovas, isNot(contains('primeiro_exercicio')));
  });
}
