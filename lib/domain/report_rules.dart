/// Resultado de erros agrupados por exercício e elemento musical avaliado.
class ItemCritico {
  const ItemCritico({
    required this.tipo,
    required this.item,
    required this.erros,
    required this.tentativas,
  });

  final String tipo;
  final String item;
  final int erros;
  final int tentativas;
}

/// Agrupa erros recentes por tipo + item, ignorando eventos sem item.
/// O chamador deve fornecer `data` como DateTime local.
List<ItemCritico> agruparErrosCriticos(
  Iterable<Map<String, dynamic>> eventos, {
  required DateTime agora,
  int maximo = 5,
}) {
  final inicio = agora.subtract(const Duration(days: 7));
  final contagens = <(String, String), (int erros, int tentativas)>{};
  for (final evento in eventos) {
    final tipo = evento['tipo'];
    final item = evento['itemAvaliado'];
    final data = evento['data'];
    if (tipo is! String || item is! String || item.trim().isEmpty) continue;
    // Não descarta datas "futuras": o horário do servidor pode estar alguns
    // segundos à frente do relógio do aparelho.
    if (data is! DateTime || data.isBefore(inicio)) continue;
    final chave = (tipo, item.trim());
    final atual = contagens[chave] ?? (0, 0);
    contagens[chave] = (
      atual.$1 + (evento['acertou'] == true ? 0 : 1),
      atual.$2 + 1,
    );
  }
  final itens =
      contagens.entries
          .where((entry) => entry.value.$1 >= 2)
          .map(
            (entry) => ItemCritico(
              tipo: entry.key.$1,
              item: entry.key.$2,
              erros: entry.value.$1,
              tentativas: entry.value.$2,
            ),
          )
          .toList()
        ..sort((a, b) {
          final porErro = b.erros.compareTo(a.erros);
          return porErro != 0 ? porErro : a.item.compareTo(b.item);
        });
  return itens.take(maximo).toList(growable: false);
}
