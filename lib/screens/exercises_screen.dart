import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() =>
      _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  final List<Map<String, String>> _notas = [
    {
      'nome': 'Dó',
      'arquivo': 'C3.wav',
    },
    {
      'nome': 'Ré',
      'arquivo': 'D3.wav',
    },
    {
      'nome': 'Mi',
      'arquivo': 'E3.wav',
    },
    {
      'nome': 'Fá',
      'arquivo': 'F3.wav',
    },
    {
      'nome': 'Sol',
      'arquivo': 'G3.wav',
    },
    {
      'nome': 'Lá',
      'arquivo': 'A3.wav',
    },
    {
      'nome': 'Si',
      'arquivo': 'B3.wav',
    },
  ];

  late Map<String, String> _notaAtual;

  String? _respostaSelecionada;

  bool? _respostaCorreta;

  bool _tocando = false;

  @override
  void initState() {
    super.initState();

    _sortearNota();
  }

  @override
  void dispose() {
    _player.dispose();

    super.dispose();
  }

  void _sortearNota() {
    _notaAtual =
        _notas[_random.nextInt(_notas.length)];

    _respostaSelecionada = null;

    _respostaCorreta = null;

    _tocando = false;

    _tocarNota();
  }

  Future<void> _tocarNota() async {
    try {
      if (mounted) {
        setState(() {
          _tocando = true;
        });
      }

      await _player.stop();

      await _player.play(
        AssetSource(
          'sounds/${_notaAtual['arquivo']}',
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 900),
      );

      if (mounted) {
        setState(() {
          _tocando = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Erro ao reproduzir nota: $e',
      );

      if (mounted) {
        setState(() {
          _tocando = false;
        });
      }
    }
  }

  void _verificarResposta(
    String resposta,
  ) {
    if (_respostaCorreta != null) {
      return;
    }

    setState(() {
      _respostaSelecionada = resposta;

      _respostaCorreta =
          resposta == _notaAtual['nome'];
    });
  }

  void _proximaNota() {
    setState(() {
      _sortearNota();
    });
  }

  Color _corTecla(
    String nota,
  ) {
    if (_respostaCorreta == null) {
      return Colors.white;
    }

    if (nota == _notaAtual['nome']) {
      return const Color(0xFFD9F7E3);
    }

    if (nota == _respostaSelecionada) {
      return const Color(0xFFFFE0E0);
    }

    return Colors.white;
  }

  Color _corBorda(
    String nota,
  ) {
    if (_respostaCorreta == null) {
      return const Color(0xFFD8DCE4);
    }

    if (nota == _notaAtual['nome']) {
      return const Color(0xFF35A85B);
    }

    if (nota == _respostaSelecionada) {
      return const Color(0xFFD64545);
    }

    return const Color(0xFFD8DCE4);
  }

  Color _corTexto(
    String nota,
  ) {
    if (_respostaCorreta == null) {
      return const Color(0xFF0B1736);
    }

    if (nota == _notaAtual['nome']) {
      return const Color(0xFF18763B);
    }

    if (nota == _respostaSelecionada) {
      return const Color(0xFFB52F2F);
    }

    return const Color(0xFF0B1736);
  }

  Widget _buildTecla(
    Map<String, String> nota,
    double largura,
  ) {
    final nome = nota['nome']!;

    final selecionada =
        nome == _respostaSelecionada;

    final correta =
        nome == _notaAtual['nome'];

    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 180),

      width: largura,

      height: 230,

      decoration: BoxDecoration(
        color: _corTecla(nome),

        border: Border.all(
          color: _corBorda(nome),
          width:
              selecionada || correta
                  ? 2
                  : 1,
        ),

        borderRadius:
            const BorderRadius.only(
          bottomLeft:
              Radius.circular(10),
          bottomRight:
              Radius.circular(10),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.16),

            blurRadius: 7,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            _verificarResposta(nome);
          },

          borderRadius:
              const BorderRadius.only(
            bottomLeft:
                Radius.circular(10),
            bottomRight:
                Radius.circular(10),
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.end,

            children: [
              if (_respostaCorreta != null &&
                  (correta ||
                      selecionada))
                Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),

                  child: Icon(
                    correta
                        ? Icons.check_circle
                        : Icons.cancel,

                    color: correta
                        ? const Color(
                            0xFF35A85B,
                          )
                        : const Color(
                            0xFFD64545,
                          ),

                    size: 26,
                  ),
                ),

              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 20,
                ),

                child: Text(
                  nome,

                  style: TextStyle(
                    color:
                        _corTexto(nome),

                    fontSize: 18,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeclado(
    double larguraDisponivel,
  ) {
    const espacamento = 2.0;

    final larguraTecla =
        (larguraDisponivel -
                (espacamento * 6)) /
            7;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        14,
      ),

      decoration: BoxDecoration(
        color:
            const Color(0xFF151B2B),

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              const Color(0xFF293247),
        ),

        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 15,
            offset:
                Offset(0, 7),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder:
            (context, constraints) {
          final largura =
              (constraints.maxWidth -
                      (espacamento * 6)) /
                  7;

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              for (
                int i = 0;
                i < _notas.length;
                i++
              ) ...[
                _buildTecla(
                  _notas[i],
                  largura,
                ),

                if (i <
                    _notas.length - 1)
                  const SizedBox(
                    width: espacamento,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayer() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 20,
      ),

      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF16D9C5),
            Color(0xFF28CFC1),
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(22),

        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset:
                Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 200,
            ),

            width:
                _tocando ? 64 : 58,

            height:
                _tocando ? 64 : 58,

            decoration:
                const BoxDecoration(
              color:
                  Color(0xFF0B1736),

              shape:
                  BoxShape.circle,
            ),

            child: IconButton(
              onPressed:
                  _tocarNota,

              iconSize: 30,

              color: Colors.white,

              icon: Icon(
                _tocando
                    ? Icons.volume_up
                    : Icons.play_arrow,
              ),
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  _tocando
                      ? 'Reproduzindo nota...'
                      : 'Ouça a nota',

                  style:
                      const TextStyle(
                    color:
                        Color(0xFF0B1736),

                    fontSize: 18,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Clique no botão para ouvir novamente',

                  style:
                      const TextStyle(
                    color:
                        Color(0xCC0B1736),

                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final correta =
        _respostaCorreta!;

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 250,
      ),

      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: correta
            ? const Color(0xFFE7F8ED)
            : const Color(0xFFFFEAEA),

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: correta
              ? const Color(0xFF8DD5A6)
              : const Color(0xFFE59B9B),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: correta
                  ? const Color(
                      0xFF35A85B,
                    )
                  : const Color(
                      0xFFD64545,
                    ),

              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              correta
                  ? Icons.check
                  : Icons.close,

              color: Colors.white,

              size: 27,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  correta
                      ? 'Muito bem!'
                      : 'Quase lá!',

                  style: TextStyle(
                    color: correta
                        ? const Color(
                            0xFF18763B,
                          )
                        : const Color(
                            0xFFB52F2F,
                          ),

                    fontSize: 18,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  correta
                      ? 'Você identificou a nota corretamente.'
                      : 'A nota tocada era ${_notaAtual['nome']}.',

                  style: TextStyle(
                    color: correta
                        ? const Color(
                            0xFF267B45,
                          )
                        : const Color(
                            0xFFB52F2F,
                          ),

                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProximaNota() {
    return SizedBox(
      width: double.infinity,

      height: 54,

      child:
          ElevatedButton.icon(
        onPressed:
            _proximaNota,

        icon: const Icon(
          Icons.arrow_forward,
        ),

        label: const Text(
          'PRÓXIMA NOTA',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(
            0xFF16D9C5,
          ),

          foregroundColor:
              const Color(
            0xFF0B1736,
          ),

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0B1736),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B1736),

        foregroundColor:
            Colors.white,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),

          tooltip: 'Voltar',

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Treino Auditivo',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                28,
              ),

              child: Column(
                children: [
                  Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.all(
                      20,
                    ),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFE5FFFC,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),

                          child:
                              const Icon(
                            Icons.hearing,

                            color:
                                Color(
                              0xFF16D9C5,
                            ),

                            size: 28,
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                'Qual nota você ouviu?',
                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF0B1736,
                                  ),

                                  fontSize:
                                      20,

                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Ouça o som e toque na tecla correspondente.',
                                style:
                                    TextStyle(
                                  color:
                                      Colors
                                          .black54,

                                  fontSize:
                                      13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildPlayer(),

                  const SizedBox(
                    height: 18,
                  ),

                  Align(
                    alignment:
                        Alignment.centerLeft,

                    child: Row(
                      children: [
                        const Icon(
                          Icons.piano,

                          color:
                              Colors.white,

                          size: 22,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        const Text(
                          'Escolha a nota no teclado',

                          style:
                              TextStyle(
                            color:
                                Colors.white,

                            fontSize: 17,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _buildTeclado(
                    constraints.maxWidth,
                  ),

                  if (_respostaCorreta !=
                      null) ...[
                    const SizedBox(
                      height: 18,
                    ),

                    _buildFeedback(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildProximaNota(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}