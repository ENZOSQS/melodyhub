import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final List<AudioPlayer> _players = [];

  // Tamanho vertical das teclas.
  // O tamanho horizontal será calculado automaticamente
  // para que todo o teclado caiba na tela.
  double _alturaTeclas = 300;

  static const double _alturaMinima = 220;
  static const double _alturaMaxima = 420;
  static const double _incrementoTamanho = 30;

  @override
  void initState() {
    super.initState();

    // Abre o simulador na horizontal.
    _entrarEmModoHorizontal();
  }

  Future<void> _entrarEmModoHorizontal() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Mantém a barra de navegação e status conforme o sistema permitir.
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  Future<void> _voltarParaOrientacaoNormal() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    for (final player in _players) {
      player.dispose();
    }

    // Quando sair do simulador, volta para vertical.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  Future<void> tocarNota(
    String arquivo,
    String nota,
  ) async {
    try {
      final player = AudioPlayer();

      _players.add(player);

      await player.play(
        AssetSource('sounds/$arquivo'),
      );

      debugPrint('Nota tocada: $nota');

      player.onPlayerComplete.listen((event) {
        player.dispose();
        _players.remove(player);
      });
    } catch (e) {
      debugPrint(
        'Erro ao reproduzir $nota: $e',
      );
    }
  }

  void _aumentarTeclas() {
    setState(() {
      if (_alturaTeclas + _incrementoTamanho <=
          _alturaMaxima) {
        _alturaTeclas += _incrementoTamanho;
      }
    });
  }

  void _diminuirTeclas() {
    setState(() {
      if (_alturaTeclas - _incrementoTamanho >=
          _alturaMinima) {
        _alturaTeclas -= _incrementoTamanho;
      }
    });
  }

  void _voltarParaHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1736),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1736),
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar para Home',
          onPressed: _voltarParaHome,
        ),

        title: const Text(
          'Teclado Musical',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

        actions: [
          PopupMenuButton<String>(
            tooltip: 'Tamanho das teclas',

            icon: const Icon(
              Icons.tune,
            ),

            onSelected: (valor) {
              if (valor == 'aumentar') {
                _aumentarTeclas();
              }

              if (valor == 'diminuir') {
                _diminuirTeclas();
              }
            },

            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: 'diminuir',

                  child: Row(
                    children: [
                      Icon(
                        Icons.remove,
                        color: Colors.black87,
                      ),

                      SizedBox(width: 12),

                      Text(
                        'Diminuir teclas',
                      ),
                    ],
                  ),
                ),

                const PopupMenuItem<String>(
                  value: 'aumentar',

                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.black87,
                      ),

                      SizedBox(width: 12),

                      Text(
                        'Aumentar teclas',
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return Center(
              child: _buildKeyboard(
                constraints.maxWidth,
                constraints.maxHeight,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKeyboard(
    double larguraDisponivel,
    double alturaDisponivel,
  ) {
    // São 8 teclas brancas:
    //
    // C3 - D3 - E3 - F3 - G3 - A3 - B3 - C4
    //
    // A largura é calculada automaticamente para
    // que TODAS caibam na tela.

    const double espacoLateral = 12;

    final larguraTeclado =
        larguraDisponivel - (espacoLateral * 2);

    final larguraBranca =
        larguraTeclado / 8;

    // Mantém uma margem para a AppBar e para não
    // encostar nas bordas da tela.
    final alturaMaximaDisponivel =
        alturaDisponivel - 20;

    final alturaBranca = _alturaTeclas.clamp(
      180.0,
      alturaMaximaDisponivel,
    );

    final larguraPreta =
        larguraBranca * 0.58;

    final alturaPreta =
        alturaBranca * 0.62;

    final teclasBrancas = [
      _PianoKey(
        'Dó',
        'C3.wav',
      ),
      _PianoKey(
        'Ré',
        'D3.wav',
      ),
      _PianoKey(
        'Mi',
        'E3.wav',
      ),
      _PianoKey(
        'Fá',
        'F3.wav',
      ),
      _PianoKey(
        'Sol',
        'G3.wav',
      ),
      _PianoKey(
        'Lá',
        'A3.wav',
      ),
      _PianoKey(
        'Si',
        'B3.wav',
      ),
      _PianoKey(
        'Dó',
        'C4.wav',
      ),
    ];

    final teclasPretas = [
      _BlackKey(
        nota: 'Dó#',
        arquivo: 'C#3.wav',
        posicao:
            larguraBranca * 1 -
            larguraPreta / 2,
      ),

      _BlackKey(
        nota: 'Ré#',
        arquivo: 'D#3.wav',
        posicao:
            larguraBranca * 2 -
            larguraPreta / 2,
      ),

      _BlackKey(
        nota: 'Fá#',
        arquivo: 'F#3.wav',
        posicao:
            larguraBranca * 4 -
            larguraPreta / 2,
      ),

      _BlackKey(
        nota: 'Sol#',
        arquivo: 'G#3.wav',
        posicao:
            larguraBranca * 5 -
            larguraPreta / 2,
      ),

      _BlackKey(
        nota: 'Lá#',
        arquivo: 'A#3.wav',
        posicao:
            larguraBranca * 6 -
            larguraPreta / 2,
      ),

      _BlackKey(
        nota: 'Dó#',
        arquivo: 'C#4.wav',
        posicao:
            larguraBranca * 8 -
            larguraPreta / 2,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: espacoLateral,
      ),

      child: SizedBox(
        width: larguraTeclado,
        height: alturaBranca,

        child: Stack(
          clipBehavior: Clip.none,

          children: [

            // ==========================================
            // TECLAS BRANCAS
            // ==========================================

            Row(
              children: teclasBrancas.map(
                (tecla) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        tocarNota(
                          tecla.arquivo,
                          tecla.nota,
                        );
                      },

                      child: Container(
                        height: alturaBranca,

                        decoration:
                            BoxDecoration(
                          color: Colors.white,

                          border: Border.all(
                            color: Colors.black87,
                            width: 1,
                          ),

                          borderRadius:
                              const BorderRadius.vertical(
                            bottom:
                                Radius.circular(8),
                          ),

                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 3),
                            ),
                          ],
                        ),

                        alignment:
                            Alignment.bottomCenter,

                        padding:
                            const EdgeInsets.only(
                          bottom: 15,
                        ),

                        child: Text(
                          tecla.nota,

                          style:
                              const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),

            // ==========================================
            // TECLAS PRETAS
            // ==========================================

            ...teclasPretas.map(
              (tecla) {
                return Positioned(
                  left: tecla.posicao,
                  top: 0,

                  child: GestureDetector(
                    onTap: () {
                      tocarNota(
                        tecla.arquivo,
                        tecla.nota,
                      );
                    },

                    child: Container(
                      width: larguraPreta,
                      height: alturaPreta,

                      decoration:
                          BoxDecoration(
                        color: Colors.black,

                        borderRadius:
                            const BorderRadius.vertical(
                          bottom:
                              Radius.circular(7),
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 5,
                            offset: Offset(2, 3),
                          ),
                        ],
                      ),

                      alignment:
                          Alignment.bottomCenter,

                      padding:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),

                      child: Text(
                        tecla.nota,

                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// TECLA BRANCA
// ======================================================

class _PianoKey {
  final String nota;
  final String arquivo;

  const _PianoKey(
    this.nota,
    this.arquivo,
  );
}

// ======================================================
// TECLA PRETA
// ======================================================

class _BlackKey {
  final String nota;
  final String arquivo;
  final double posicao;

  const _BlackKey({
    required this.nota,
    required this.arquivo,
    required this.posicao,
  });
}