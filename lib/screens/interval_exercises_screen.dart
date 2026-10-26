import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../services/progress_service.dart';

class IntervalExercisesScreen extends StatefulWidget {
  const IntervalExercisesScreen({super.key, this.nivelSelecionado});

  final int? nivelSelecionado;

  @override
  State<IntervalExercisesScreen> createState() =>
      _IntervalExercisesScreenState();
}

class _IntervalExercisesScreenState extends State<IntervalExercisesScreen> {
  static const _background = Color(0xFF0B1736);
  static const _accent = Color(0xFF16D9C5);
  static const _notes = [
    ('Dó', 'C3.wav'),
    ('Ré', 'D3.wav'),
    ('Mi', 'E3.wav'),
    ('Fá', 'F3.wav'),
    ('Sol', 'G3.wav'),
    ('Lá', 'A3.wav'),
    ('Si', 'B3.wav'),
  ];
  static const _intervalNames = [
    '',
    'Segunda maior',
    'Terça maior',
    'Quarta justa',
    'Quinta justa',
    'Sexta maior',
    'Sétima maior',
  ];

  final _audio = AudioPlayer();
  final _progress = ProgressService();
  final _random = Random();
  final _timer = Stopwatch();

  int _level = 1;
  int _currentLevel = 1;
  int _attempts = 0;
  bool _loading = true;
  bool _playing = false;
  bool _saving = false;
  bool? _correct;
  String? _selected;
  late int _degree;
  late bool _ascending;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _timer.stop();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final data = await _progress.buscarProgresso();
      if (!mounted) return;
      final currentLevel = _number(data['nivelIntervalos']).clamp(1, 5).toInt();
      final level = (widget.nivelSelecionado ?? currentLevel)
          .clamp(1, currentLevel)
          .toInt();
      final stages = Map<String, dynamic>.from(
        data['intervaloEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final stage = Map<String, dynamic>.from(
        stages['$level'] as Map? ?? const <String, dynamic>{},
      );
      setState(() {
        _currentLevel = currentLevel;
        _level = level;
        _attempts = level == currentLevel
            ? _number(data['tentativasIntervalosNivel'])
            : _number(stage['tentativas']) % 10;
        _loading = false;
      });
      _newQuestion();
      _timer.start();
      await _playPair();
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar seu progresso.'),
          ),
        );
      }
    }
  }

  void _newQuestion() {
    final maxDegree = _level + 1;
    _degree = 1 + _random.nextInt(maxDegree);
    _ascending = _level < 4 || _random.nextBool();
    final names = <String>{};
    while (names.length < min(4, maxDegree)) {
      names.add(_intervalNames[1 + _random.nextInt(maxDegree)]);
    }
    names.add(_intervalNames[_degree]);
    _options = names.toList()..shuffle(_random);
  }

  Future<void> _playPair() async {
    if (_playing) return;
    setState(() => _playing = true);
    try {
      final low = _notes.first;
      final high = _notes[_degree];
      final first = _ascending ? low : high;
      final second = _ascending ? high : low;
      for (final note in [first, second]) {
        await _audio.stop();
        await _audio.play(AssetSource('sounds/${note.$2}'));
        try {
          await _audio.onPlayerComplete.first.timeout(
            const Duration(seconds: 3),
          );
        } on TimeoutException {
          await _audio.stop();
        }
        await Future<void>.delayed(const Duration(milliseconds: 220));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível reproduzir os sons.')),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _answer(String answer) async {
    if (_saving || _selected != null) return;
    final isCorrect = answer == _intervalNames[_degree];
    final duration = _timer.elapsed.inSeconds;
    _timer.stop();
    setState(() {
      _selected = answer;
      _correct = isCorrect;
      _saving = true;
    });
    try {
      await _progress.registrarExercicio(
        acertou: isCorrect,
        tipo: 'Intervalo',
        pergunta: 'Identifique o intervalo entre as duas notas ouvidas.',
        resposta: answer,
        respostaCorreta: _intervalNames[_degree],
        dificuldade: _level,
        questaoId:
            'intervalo_${_level}_${_degree}_${_ascending ? 'asc' : 'desc'}',
        categoria: 'Percepção de intervalos',
        duracaoSegundos: duration,
      );
      final data = await _progress.buscarProgresso();
      if (!mounted) return;
      final wasCurrentLevel = _level == _currentLevel;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _currentLevel = _number(data['nivelIntervalos']).clamp(1, 5).toInt();
        _level = wasCurrentLevel ? _currentLevel : _level;
        final stages = Map<String, dynamic>.from(
          data['intervaloEtapas'] as Map? ?? const <String, dynamic>{},
        );
        final stage = Map<String, dynamic>.from(
          stages['$_level'] as Map? ?? const <String, dynamic>{},
        );
        _attempts = _level == _currentLevel
            ? _number(data['tentativasIntervalosNivel'])
            : _number(stage['tentativas']) % 10;
        _selected = null;
        _correct = null;
        _saving = false;
        _newQuestion();
        _timer
          ..reset()
          ..start();
      });
      await _playPair();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _selected = null;
          _correct = null;
          _timer
            ..reset()
            ..start();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a resposta.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('Intervalos auditivos'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.graphic_eq,
                            size: 40,
                            color: _background,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nível $_level · ${_levelName(_level)}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: _background,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ouça duas notas, uma após a outra. Escolha o nome da distância musical entre elas. Ignore se a melodia subiu ou desceu.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Exemplo: Dó → Mi = terça maior.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_attempts/10 respostas neste nível',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _playing || _saving ? null : _playPair,
                            icon: const Icon(Icons.volume_up),
                            label: Text(
                              _playing ? 'Reproduzindo…' : 'Ouvir novamente',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._options.map((option) {
                      final selected = _selected == option;
                      final right = option == _intervalNames[_degree];
                      final color = _selected == null
                          ? Colors.white
                          : right
                          ? Colors.green
                          : selected
                          ? Colors.red
                          : Colors.white;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : () => _answer(option),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: color == Colors.white
                                  ? _background
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              option,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_correct != null)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          _correct!
                              ? 'Isso! Intervalo reconhecido. +10 XP'
                              : 'Resposta correta: ${_intervalNames[_degree]}',
                          style: TextStyle(
                            color: _correct!
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  String _levelName(int level) => const [
    'Iniciante',
    'Básico',
    'Intermediário',
    'Avançado',
    'Especialista',
  ][level - 1];

  int _number(dynamic value) => value is num ? value.toInt() : 0;
}
