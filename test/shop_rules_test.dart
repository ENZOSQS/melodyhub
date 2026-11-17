import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/data/profile_icon_rewards.dart';
import 'package:melodyhub/domain/shop_rules.dart';

void main() {
  test('três faixas de preço: comum, raro e épico', () {
    expect(ShopRules.precoDaRaridade(ShopRules.comum), 150);
    expect(ShopRules.precoDaRaridade(ShopRules.raro), 400);
    expect(ShopRules.precoDaRaridade(ShopRules.epico), 900);
  });

  test('todo ícone à venda segue o preço da sua raridade', () {
    for (final icone in profileIconRewards) {
      expect(
        icone.price,
        ShopRules.precoDaRaridade(icone.rarity),
        reason: icone.id,
      );
      expect(icone.achievementId, isNull, reason: 'compra só por pontos');
    }
  });

  test('ícone comum exige de 2 a 3 rodadas de 10 questões bem feitas', () {
    // Rodada só com ★★★ rende 100; com ★★ rende 60.
    expect(ShopRules.precoComum, greaterThan(100));
    expect(ShopRules.precoComum, lessThanOrEqualTo(3 * 60));
  });

  test('pontos que faltam e liberação da compra', () {
    expect(ShopRules.pontosFaltando(0, 150), 150);
    expect(ShopRules.pontosFaltando(120, 150), 30);
    expect(ShopRules.pontosFaltando(150, 150), 0);
    expect(ShopRules.pontosFaltando(999, 400), 0);
    expect(ShopRules.podeComprar(149, 150), isFalse);
    expect(ShopRules.podeComprar(150, 150), isTrue);
  });
}
