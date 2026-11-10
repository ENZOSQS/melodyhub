import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/domain/report_rules.dart';

void main() {
  final agora = DateTime(2026, 11, 10, 12);

  test(
    'agrupa por tipo e item, conta erros e tentativas, e exige dois erros',
    () {
      final itens = agruparErrosCriticos([
        {
          'tipo': 'Intervalo',
          'itemAvaliado': 'Terça maior',
          'acertou': false,
          'data': agora,
        },
        {
          'tipo': 'Intervalo',
          'itemAvaliado': 'Terça maior',
          'acertou': true,
          'data': agora,
        },
        {
          'tipo': 'Intervalo',
          'itemAvaliado': 'Terça maior',
          'acertou': false,
          'data': agora,
        },
        {
          'tipo': 'Intervalo',
          'itemAvaliado': 'Quinta justa',
          'acertou': false,
          'data': agora,
        },
        {'tipo': 'Prático', 'acertou': false, 'data': agora},
      ], agora: agora);

      expect(itens, hasLength(1));
      expect(itens.single.tipo, 'Intervalo');
      expect(itens.single.item, 'Terça maior');
      expect(itens.single.erros, 2);
      expect(itens.single.tentativas, 3);
    },
  );

  test(
    'ignora registros fora da semana e limita os itens aos cinco mais errados',
    () {
      final eventos = <Map<String, dynamic>>[
        for (var i = 0; i < 7; i++)
          for (var tentativa = 0; tentativa < i + 2; tentativa++)
            {
              'tipo': 'Teórico',
              'itemAvaliado': 'Tema $i',
              'acertou': false,
              'data': agora,
            },
        {
          'tipo': 'Teórico',
          'itemAvaliado': 'Antigo',
          'acertou': false,
          'data': agora.subtract(const Duration(days: 8)),
        },
      ];
      final itens = agruparErrosCriticos(eventos, agora: agora);
      expect(itens, hasLength(5));
      expect(itens.first.item, 'Tema 6');
      expect(itens.any((item) => item.item == 'Antigo'), isFalse);
    },
  );

  test('conta eventos com horário do servidor à frente do aparelho', () {
    final adiantado = agora.add(const Duration(seconds: 30));
    final itens = agruparErrosCriticos([
      for (var i = 0; i < 2; i++)
        {
          'tipo': 'Intervalo',
          'itemAvaliado': 'Sexta menor',
          'acertou': false,
          'data': adiantado,
        },
    ], agora: agora);
    expect(itens.single.erros, 2);
  });
}
