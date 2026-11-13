# Créditos dos sons

As notas de piano e violão são sintetizadas em tempo real pelo serviço
`lib/services/note_player.dart`, usando ondas senoidal e triangular do SoLoud.
Não há samples ou SoundFont de terceiros distribuídos no aplicativo para esses
instrumentos. O serviço aplica ataque de 5 ms, liberação de 300 ms e limita o
ganho para reduzir estalos e clipping.

O motor de áudio é fornecido pelo pacote
[`flutter_soloud`](https://pub.dev/packages/flutter_soloud), publicado sob a
licença MIT. Os três arquivos WAV de metrônomo e ditado rítmico permanecem como
assets do aplicativo.
