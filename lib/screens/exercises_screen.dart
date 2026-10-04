import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../services/progress_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({
    super.key,
  });

  @override
  State<ExercisesScreen>
      createState() =>
          _ExercisesScreenState();
}

class _ExercisesScreenState
    extends State<ExercisesScreen> {
  final AudioPlayer _player =
      AudioPlayer();

  final Random _random =
      Random();

  final ProgressService
      _progressService =
      ProgressService();

  final List<Map<String, String>>
      _notas = [
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

  late Map<String, String>
      _notaAtual;

  String? _respostaSelecionada;

  bool? _respostaCorreta;

  bool _tocando = false;

  bool _salvandoProgresso =
      false;

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
        _notas[
          _random.nextInt(
            _notas.length,
          )
        ];

    _respostaSelecionada =
        null;

    _respostaCorreta =
        null;

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
        const Duration(
          milliseconds: 900,
        ),
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

  Future<void> _verificarResposta(
    String resposta,
  ) async {
    if (_respostaCorreta != null ||
        _salvandoProgresso) {
      return;
    }

    final acertou =
        resposta ==
            _notaAtual['nome'];

    setState(() {
      _respostaSelecionada =
          resposta;

      _respostaCorreta =
          acertou;

      _salvandoProgresso = true;
    });

    try {
      await _progressService
          .registrarExercicio(
        acertou: acertou,
      );

      if (mounted && acertou) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content:
                Text('+10 XP! 🎉'),
            backgroundColor:
                Color(0xFF35A85B),
            duration:
                Duration(
              seconds: 1,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Erro ao salvar progresso: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o progresso.',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _salvandoProgresso =
              false;
        });
      }
    }
  }

  void _proximaNota() {
    if (_salvandoProgresso) {
      return;
    }

    setState(() {
      _sortearNota();
    });
  }

  Color _corTecla(
    String nota,
  ) {
    if (_respostaCorreta ==
        null) {
      return Colors.white;
    }

    if (nota ==
        _respostaSelecionada) {
      return _respostaCorreta!
          ? const Color(
              0xFF35A85B,
            )
          : const Color(
              0xFFD94B4B,
            );
    }

    if (nota ==
        _notaAtual['nome']) {
      return const Color(
        0xFF35A85B,
      );
    }

    return Colors.white;
  }

  Color _corTexto(
    String nota,
  ) {
    if (_respostaCorreta ==
        null) {
      return Colors.black87;
    }

    if (nota ==
        _respostaSelecionada) {
      return Colors.white;
    }

    if (nota ==
        _notaAtual['nome']) {
      return Colors.white;
    }

    return Colors.black54;
  }

  Widget _buildTecla(
    Map<String, String> nota,
  ) {
    final nome =
        nota['nome']!;

    return Expanded(
      child: GestureDetector(
        onTap: _respostaCorreta ==
                    null &&
                !_salvandoProgresso
            ? () =>
                _verificarResposta(
                  nome,
                )
            : null,
        child: Container(
          margin:
              const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          height: 240,
          decoration:
              BoxDecoration(
            color:
                _corTecla(nome),
            borderRadius:
                BorderRadius.circular(
              8,
            ),
            border: Border.all(
              color: Colors.black26,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset:
                    Offset(0, 4),
              ),
            ],
          ),
          child: Align(
            alignment:
                Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 18,
              ),
              child: Text(
                nome,
                style:
                    TextStyle(
                  color:
                      _corTexto(
                    nome,
                  ),
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeclado() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children:
          _notas.map(
        (nota) {
          return _buildTecla(
            nota,
          );
        },
      ).toList(),
    );
  }

  Widget _buildPlayer() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF151515),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hearing,
            color:
                Color(0xFF35A85B),
            size: 38,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            _tocando
                ? 'Reproduzindo...'
                : 'Ouça a nota',
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          const Text(
            'Identifique qual nota foi reproduzida.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _tocando
                      ? null
                      : _tocarNota,
              icon: const Icon(
                Icons.volume_up,
              ),
              label: Text(
                _tocando
                    ? 'Reproduzindo...'
                    : 'Ouvir novamente',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF35A85B,
                ),
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    if (_respostaCorreta ==
        null) {
      return const SizedBox
          .shrink();
    }

    final correto =
        _respostaCorreta!;

    return Container(
      margin:
          const EdgeInsets.only(
        top: 18,
      ),
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color: correto
            ? const Color(
                0xFF17251C,
              )
            : const Color(
                0xFF281717,
              ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: correto
              ? const Color(
                  0xFF35A85B,
                )
              : const Color(
                  0xFFD94B4B,
                ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            correto
                ? Icons.check_circle
                : Icons.cancel,
            color: correto
                ? const Color(
                    0xFF35A85B,
                  )
                : const Color(
                    0xFFD94B4B,
                  ),
            size: 34,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  correto
                      ? 'Muito bem! +10 XP'
                      : 'Resposta incorreta',
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  correto
                      ? 'Você identificou a nota corretamente.'
                      : 'A nota correta era ${_notaAtual['nome']}.',
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
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
    if (_respostaCorreta ==
        null) {
      return const SizedBox
          .shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        top: 18,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _salvandoProgresso
                  ? null
                  : _proximaNota,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.white,
            foregroundColor:
                Colors.black,
            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 15,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
          ),
          child: const Text(
            'Próxima nota',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
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
          const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text(
          'Exercícios auditivos',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(
            20,
          ),
          children: [
            const Text(
              'Identifique a nota',
              style: TextStyle(
                color:
                    Colors.white,
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            const Text(
              'Ouça o som e escolha a tecla correspondente.',
              style: TextStyle(
                color:
                    Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            _buildPlayer(),
            const SizedBox(
              height: 22,
            ),
            Container(
              padding:
                  const EdgeInsets
                      .all(12),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF151515,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: _buildTeclado(),
            ),
            _buildFeedback(),
            _buildProximaNota(),
          ],
        ),
      ),
    );
  }
}