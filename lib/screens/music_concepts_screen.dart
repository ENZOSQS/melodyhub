import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/theory_explanations.dart';
import '../domain/answer_feedback_rules.dart';
import '../services/note_player.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_ui.dart';
import '../widgets/theory_explanation_sheet.dart';

/// O exercício auditivo de acordes saiu do escopo; resta o de escalas.
enum ConceptExercise { scale }

class MusicConceptsScreen extends StatefulWidget {
  const MusicConceptsScreen({
    super.key,
    this.exercise = ConceptExercise.scale,
  });

  final ConceptExercise exercise;

  @override
  State<MusicConceptsScreen> createState() => _MusicConceptsScreenState();
}

class _MusicConceptsScreenState extends State<MusicConceptsScreen>
    with WidgetsBindingObserver {
  static const _scales = <String, List<int>>{
    'Maior': [0, 2, 4, 5, 7, 9, 11, 12],
    'Menor': [0, 2, 3, 5, 7, 8, 10, 12],
    'Pentatônica maior': [0, 2, 4, 7, 9, 12],
    'Pentatônica menor': [0, 3, 5, 7, 10, 12],
  };
  static const _hints = <String, String>{
    'Maior': 'soa alegre e aberta',
    'Menor': 'soa mais triste ou escura',
    'Pentatônica maior': 'tem só 5 notas e soa leve, como música folclórica',
    'Pentatônica menor': 'tem só 5 notas e soa como blues e rock',
  };

  final _random = Random();
  final _progress = ProgressService();
  final _notePlayer = NotePlayer.instance;
  final _timer = Stopwatch();

  int _level = 1;
  int _root = 60;
  int _roundDone = 0;
  int _attempts = 0;
  int _shakeToken = 0;
  int _sessionQuestions = 0;
  int _sessionCorrect = 0;
  int _sessionStars = 0;
  int _combo = 0;
  bool _loading = true;
  bool _playing = false;
  bool _saving = false;
  bool _solved = false;
  bool _revealed = false;
  bool _inForeground = true;
  String _answer = 'Maior';
  String? _shaking;
  String? _feedback;
  bool? _feedbackPositive;
  final Set<String> _wrong = {};

  List<String> get _options => switch (_level) {
    1 => const ['Maior', 'Menor'],
    2 => const ['Maior', 'Menor', 'Pentatônica maior'],
    _ => _scales.keys.toList(),
  };

  bool get _busy => _playing || _saving;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_notePlayer.stopAll());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (!_inForeground) unawaited(_notePlayer.stopAll());
  }

  Future<void> _initialize() async {
    try {
      final values = await Future.wait([
        _progress.buscarProgresso(),
        _notePlayer.initialize(),
      ]);
      if (!mounted) return;
      setState(() {
        _applyProgress(values[0] as Map<String, dynamic>);
        _newQuestion();
        _loading = false;
      });
      unawaited(_playQuestion());
    } catch (error) {
      debugPrint('Falha ao iniciar escalas: $error');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyProgress(Map<String, dynamic> data) {
    final skills = Map<String, dynamic>.from(
      data['habilidadesEtapas'] as Map? ?? const <String, dynamic>{},
    );
    final skill = Map<String, dynamic>.from(
      skills['escalas'] as Map? ?? const <String, dynamic>{},
    );
    _level = _number(skill['nivel']).clamp(1, 5).toInt();
    final stage = Map<String, dynamic>.from(
      skill['$_level'] as Map? ?? const <String, dynamic>{},
    );
    _roundDone = _number(stage['rodadaTentativas']);
  }

  void _newQuestion() {
    final options = _options;
    _answer = options[_random.nextInt(options.length)];
    // Até o nível 2 a escala começa sempre em Dó; depois, em qualquer nota.
    _root = _level <= 2 ? 60 : 55 + _random.nextInt(8);
    _attempts = 0;
    _solved = false;
    _revealed = false;
    _wrong.clear();
    _feedback = null;
    _feedbackPositive = null;
    _timer
      ..stop()
      ..reset();
  }

  Future<void> _playScale(String name) async {
    for (final step in _scales[name]!) {
      if (!mounted || !_inForeground) return;
      await _notePlayer.playNote(_root + step, durationMs: 260);
    }
  }

  Future<void> _guarded(Future<void> Function() action) async {
    if (_playing || !_inForeground) return;
    _timer.stop();
    setState(() => _playing = true);
    try {
      await action();
    } catch (error) {
      debugPrint('Falha de áudio nas escalas: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar o som. Aumente o volume e toque em Repetir.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _playing = false);
        if (!_solved && _inForeground) _timer.start();
      }
    }
  }

  Future<void> _playQuestion() => _guarded(() => _playScale(_answer));

  Future<void> _select(String choice) async {
    if (_busy || _solved || _wrong.contains(choice)) return;
    _attempts++;
    if (choice == _answer) {
      setState(() {
        _solved = true;
        _feedback = '${_attempts == 1 ? 'Isso!' : 'Muito bem!'} '
            'A escala $_answer ${_hints[_answer]}.';
        _feedbackPositive = true;
      });
      final saved = await _record();
      if (saved) await _advance();
      return;
    }
    _wrong.add(choice);
    _shakeToken++;
    if (_attempts >= 3) {
      setState(() {
        _shaking = choice;
        _solved = true;
        _revealed = true;
        _feedback = 'Era a escala $_answer: ela ${_hints[_answer]}.';
        _feedbackPositive = false;
      });
      await _guarded(() => _playScale(_answer));
      final saved = await _record();
      if (saved) await _advance(delay: const Duration(milliseconds: 2200));
      return;
    }
    setState(() {
      _shaking = choice;
      _feedback = 'Você escolheu $choice. Ouça a diferença.';
      _feedbackPositive = false;
    });
    await _guarded(() async {
      await _playScale(choice);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await _playScale(_answer);
    });
    if (mounted) setState(() => _shaking = null);
  }

  Future<bool> _record() async {
    final counts = AnswerFeedbackRules.countsAsCorrect(
      _attempts,
      revealed: _revealed,
    );
    final stars = AnswerFeedbackRules.starsForAttempt(
      _attempts,
      revealed: _revealed,
    );
    setState(() => _saving = true);
    try {
      await _progress.registrarExercicio(
        acertou: counts,
        tipo: 'Escala',
        pergunta: 'Qual é esta escala?',
        resposta: _revealed ? 'Resposta revelada' : _answer,
        respostaCorreta: _answer,
        dificuldade: _level,
        categoria: 'Escalas',
        itemAvaliado: _answer,
        duracaoMilissegundos: _timer.elapsedMilliseconds,
        duracaoSegundos: (_timer.elapsedMilliseconds / 1000).ceil(),
        tentativas: _attempts,
        estrelas: stars,
      );
      final data = await _progress.buscarProgresso();
      if (!mounted) return false;
      setState(() {
        _applyProgress(data);
        _combo = counts && _attempts == 1 ? _combo + 1 : 0;
        _sessionStars += stars;
        _sessionQuestions++;
        if (counts) _sessionCorrect++;
        _saving = false;
      });
      return true;
    } catch (error) {
      debugPrint('Falha ao salvar escala: $error');
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _solved = false;
        _revealed = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar sua resposta. Confira a conexão e responda de novo.',
          ),
        ),
      );
      return false;
    }
  }

  Future<void> _advance({
    Duration delay = const Duration(milliseconds: 1600),
  }) async {
    await Future<void>.delayed(delay);
    if (!mounted) return;
    if (_sessionQuestions >= 10) {
      final again = await showRoundSummary(
        context,
        stars: _sessionStars,
        correct: _sessionCorrect,
        total: _sessionQuestions,
      );
      if (!mounted) return;
      if (again != true) {
        Navigator.pop(context);
        return;
      }
      _sessionQuestions = 0;
      _sessionCorrect = 0;
      _sessionStars = 0;
    }
    setState(_newQuestion);
    await _playQuestion();
  }

  Future<void> _openTheory() {
    final theory =
        'Uma escala é uma sequência de notas em ordem. A escala $_answer '
        '${_hints[_answer]}. A diferença mais fácil de ouvir está na 3ª nota: '
        'na maior ela fica 4 semitons acima da primeira; na menor, 3.';
    return showTheoryExplanationSheet(
      context,
      explanation: TheoryExplanation(
        objective: theoryObjectiveForCategory('Escalas'),
        theory: theory,
      ),
      theory: theory,
      onPlayExample: _playQuestion,
      exampleLabel: 'Ouvir a escala de novo',
    );
  }

  int _number(dynamic value) => value is num ? value.toInt() : 0;

  AnswerState _stateFor(String option) {
    if (_solved && option == _answer) return AnswerState.correct;
    if (_wrong.contains(option)) return AnswerState.wrong;
    return AnswerState.normal;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Escalas'),
      actions: [
        IconButton(
          tooltip: 'Entenda a teoria',
          onPressed: _loading ? null : _openTheory,
          icon: const Icon(Icons.menu_book_outlined),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: Column(
              children: [
                ExerciseStatusBar(
                  level: _level,
                  roundDone: _roundDone,
                  stars: _sessionStars,
                  combo: _combo,
                ),
                const ExerciseQuestion('Qual é esta escala?'),
                Expanded(
                  child: Center(
                    child: ExercisePlayButton(
                      playing: _playing,
                      onTap: _busy ? null : _playQuestion,
                    ),
                  ),
                ),
                ExerciseFeedbackLine(_feedback, positive: _feedbackPositive),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option in _options)
                        AnswerPill(
                          label: option,
                          state: _stateFor(option),
                          enabled: !_busy && !_solved,
                          shaking: _shaking == option,
                          shakeToken: _shakeToken,
                          onTap: () => _select(option),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
  );
}
