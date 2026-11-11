import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/domain/continue_rules.dart';

void main() {
  test('sem histórico não há sugestão', () {
    expect(sugestaoContinuar(null), isNull);
  });

  test('intervalo mostra a etapa do último exercício', () {
    final sugestao = sugestaoContinuar({'tipo': 'Intervalo', 'dificuldade': 2});
    expect(sugestao!.atividade, AtividadeContinuar.intervalos);
    expect(sugestao.etapa, 2);
    expect(sugestao.rotulo, 'Intervalos – Etapa 2');
  });

  test('etapa fica entre 1 e 5', () {
    expect(
      sugestaoContinuar({'tipo': 'Teórico', 'dificuldade': 9})!.etapa,
      5,
    );
  });

  test('atividades sem trilha não mostram etapa', () {
    final sugestao = sugestaoContinuar({'tipo': 'Violão', 'dificuldade': 1});
    expect(sugestao!.atividade, AtividadeContinuar.violao);
    expect(sugestao.etapa, isNull);
    expect(sugestao.rotulo, 'Notas no violão');
  });

  test('tipo desconhecido é ignorado', () {
    expect(sugestaoContinuar({'tipo': 'Outro'}), isNull);
  });
}
