import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final List<AudioPlayer> _players = [];

  @override
  void dispose() {
    for (final player in _players) {
      player.dispose();
    }

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
      debugPrint('Erro ao reproduzir $nota: $e');
    }
  }

  void voltarParaHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar para Home',
          onPressed: voltarParaHome,
        ),
        title: const Text('Teclado Musical'),
        centerTitle: true,
      ),

      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildKeyboard(),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    const double larguraBranca = 72;
    const double alturaBranca = 320;
    const double larguraPreta = 44;
    const double alturaPreta = 200;

    final teclasBrancas = [
      _PianoKey('Dó', 'C3.wav'),
      _PianoKey('Ré', 'D3.wav'),
      _PianoKey('Mi', 'E3.wav'),
      _PianoKey('Fá', 'F3.wav'),
      _PianoKey('Sol', 'G3.wav'),
      _PianoKey('Lá', 'A3.wav'),
      _PianoKey('Si', 'B3.wav'),
      _PianoKey('Dó', 'C4.wav'),
    ];

    final teclasPretas = [
      _BlackKey(
        nota: 'Dó#',
        arquivo: 'C#3.wav',
        posicao: larguraBranca * 1 - larguraPreta / 2,
      ),
      _BlackKey(
        nota: 'Ré#',
        arquivo: 'D#3.wav',
        posicao: larguraBranca * 2 - larguraPreta / 2,
      ),
      _BlackKey(
        nota: 'Fá#',
        arquivo: 'F#3.wav',
        posicao: larguraBranca * 4 - larguraPreta / 2,
      ),
      _BlackKey(
        nota: 'Sol#',
        arquivo: 'G#3.wav',
        posicao: larguraBranca * 5 - larguraPreta / 2,
      ),
      _BlackKey(
        nota: 'Lá#',
        arquivo: 'A#3.wav',
        posicao: larguraBranca * 6 - larguraPreta / 2,
      ),
      _BlackKey(
        nota: 'Dó#',
        arquivo: 'C#4.wav',
        posicao: larguraBranca * 8 - larguraPreta / 2,
      ),
    ];

    final larguraTotal =
        teclasBrancas.length * larguraBranca;

    return SizedBox(
      width: larguraTotal,
      height: alturaBranca + 30,

      child: Stack(
        children: [

          // TECLAS BRANCAS
          Row(
            children: teclasBrancas.map((tecla) {
              return GestureDetector(
                onTap: () {
                  tocarNota(
                    tecla.arquivo,
                    tecla.nota,
                  );
                },

                child: Container(
                  width: larguraBranca,
                  height: alturaBranca,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),

                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),

                  alignment: Alignment.bottomCenter,

                  padding: const EdgeInsets.only(
                    bottom: 20,
                  ),

                  child: Text(
                    tecla.nota,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // TECLAS PRETAS
          ...teclasPretas.map((tecla) {
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

                  decoration: BoxDecoration(
                    color: Colors.black,

                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 5,
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),

                  alignment: Alignment.bottomCenter,

                  padding: const EdgeInsets.only(
                    bottom: 15,
                  ),

                  child: Text(
                    tecla.nota,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PianoKey {
  final String nota;
  final String arquivo;

  const _PianoKey(
    this.nota,
    this.arquivo,
  );
}

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