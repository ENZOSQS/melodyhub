// lib/screens/exercises_screen.dart

import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../services/progress_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen>
    with WidgetsBindingObserver {
  static const Color verde = Color(0xFF16D9C5);
  static const Color preto = Color(0xFF0B1736);

  final AudioPlayer _audioPlayer = AudioPlayer();

  final ProgressService _progressService = ProgressService();

  final Random _random = Random();
  final Stopwatch _tempoQuestao = Stopwatch();

  bool _respondendo = false;
  bool _mostrarFeedback = false;
  bool? _acertou;

  String? _respostaSelecionada;

  late Map<String, String> _notaAtual;

  final List<Map<String, String>> _notas = [
    {'nome': 'Dó', 'arquivo': 'C3.wav'},
    {'nome': 'Ré', 'arquivo': 'D3.wav'},
    {'nome': 'Mi', 'arquivo': 'E3.wav'},
    {'nome': 'Fá', 'arquivo': 'F3.wav'},
    {'nome': 'Sol', 'arquivo': 'G3.wav'},
    {'nome': 'Lá', 'arquivo': 'A3.wav'},
    {'nome': 'Si', 'arquivo': 'B3.wav'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _notaAtual = _sortearNota();
    _tempoQuestao.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tocarNota();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_respondendo) _tempoQuestao.start();
    } else {
      _tempoQuestao.stop();
    }
  }

  Map<String, String> _sortearNota() {
    return _notas[_random.nextInt(_notas.length)];
  }

  Future<void> _tocarNota() async {
    try {
      await _audioPlayer.stop();

      await _audioPlayer.play(AssetSource('sounds/${_notaAtual['arquivo']}'));
    } catch (e) {
      debugPrint('Erro ao reproduzir áudio: $e');
    }
  }

  Future<void> _responder(String resposta) async {
    if (_respondendo) {
      return;
    }

    final correta = resposta == _notaAtual['nome'];
    _tempoQuestao.stop();
    final duracaoSegundos = _tempoQuestao.elapsed.inSeconds;

    setState(() {
      _respondendo = true;
      _respostaSelecionada = resposta;
      _acertou = correta;
      _mostrarFeedback = true;
    });

    try {
      await _progressService.registrarExercicio(
        acertou: correta,
        tipo: 'Prático',
        pergunta: 'Identifique a nota tocada.',
        resposta: resposta,
        respostaCorreta: _notaAtual['nome'],
        duracaoSegundos: duracaoSegundos,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _respondendo = false;
        _mostrarFeedback = false;
        _acertou = null;
        _respostaSelecionada = null;
      });
      _tempoQuestao
        ..reset()
        ..start();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar seu exercício. Confira sua conexão e tente novamente.',
          ),
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) {
      return;
    }

    setState(() {
      _notaAtual = _sortearNota();
      _respondendo = false;
      _mostrarFeedback = false;
      _acertou = null;
      _respostaSelecionada = null;
      _tempoQuestao
        ..reset()
        ..start();
    });

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      await _tocarNota();
    }
  }

  Color _corTecla(String nome) {
    if (!_mostrarFeedback) {
      return Colors.white;
    }

    if (nome == _notaAtual['nome']) {
      return Colors.green;
    }

    if (nome == _respostaSelecionada && _acertou == false) {
      return Colors.red;
    }

    return Colors.white;
  }

  Color _corTextoTecla(String nome) {
    if (!_mostrarFeedback) {
      return preto;
    }

    if (nome == _notaAtual['nome']) {
      return Colors.white;
    }

    if (nome == _respostaSelecionada && _acertou == false) {
      return Colors.white;
    }

    return preto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: preto,
      appBar: AppBar(
        backgroundColor: preto,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Exercício Prático',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                  child: Column(
                    children: [
                      _buildCabecalho(),
                      const SizedBox(height: 12),
                      _buildPiano(),
                      const SizedBox(height: 12),
                      _buildFeedback(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.hearing, color: preto, size: 34),
          const SizedBox(height: 7),
          const Text(
            'Identifique a nota',
            style: TextStyle(
              color: preto,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ouça a nota e toque a tecla correspondente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: _respondendo ? null : _tocarNota,
              icon: const Icon(Icons.volume_up, size: 19),
              label: const Text(
                'Ouvir novamente',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: preto,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiano() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF050B1B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: AspectRatio(
        aspectRatio: 7 / 3.2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _notas.map((nota) {
            final nome = nota['nome']!;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: _respondendo
                      ? null
                      : () {
                          _responder(nome);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: _corTecla(nome),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                      border: Border.all(color: Colors.black38),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          nome,
                          style: TextStyle(
                            color: _corTextoTecla(nome),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    if (!_mostrarFeedback || _acertou == null) {
      return const SizedBox(height: 48);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _acertou! ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _acertou! ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 23,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _acertou! ? 'Correto! +10 XP' : 'Incorreto',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
