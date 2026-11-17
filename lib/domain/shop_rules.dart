/// Regras da loja de ícones: só pontos, sem exigir módulos concluídos.
///
/// Três faixas de preço, pensadas a partir dos pontos por resposta
/// (★★★ = 10): uma rodada de 10 questões rende de 30 a 100 pontos.
/// - Comum (150): 2 ou 3 rodadas bem feitas;
/// - Raro (400): cerca de uma semana de prática leve;
/// - Épico (900): objetivo de longo prazo.
abstract final class ShopRules {
  static const int precoComum = 150;
  static const int precoRaro = 400;
  static const int precoEpico = 900;

  static const String comum = 'Comum';
  static const String raro = 'Raro';
  static const String epico = 'Épico';

  static int precoDaRaridade(String raridade) => switch (raridade) {
    comum => precoComum,
    raro => precoRaro,
    epico => precoEpico,
    _ => throw ArgumentError.value(raridade, 'raridade'),
  };

  static bool podeComprar(int pontos, int preco) => pontos >= preco;

  /// Quanto falta para comprar; zero quando já dá.
  static int pontosFaltando(int pontos, int preco) =>
      pontos >= preco ? 0 : preco - pontos;
}
