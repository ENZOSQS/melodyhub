import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/theory_explanations.dart';
import '../domain/answer_feedback_rules.dart';
import '../domain/ear_training_levels.dart';
import '../services/note_player.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_ui.dart';
import '../widgets/theory_explanation_sheet.dart';

/// Intervalos: o aluno ouve duas notas e responde pelo nome do intervalo.
///
/// Antes de cada nível aparece "Conheça os sons", com um cartão por intervalo
/// para ouvir à vontade. Na questão, um toque longo numa resposta toca aquela
/// opção a partir da mesma nota inicial, para comparar antes de responder.
class IntervalExercisesScreen extends StatefulWidget {
  const IntervalExercisesScreen({super.key, this.nivelSelecionado});

  final int? nivelSelecionado;

  @override
  State<IntervalExercisesScreen> createState() =>
      _IntervalExercisesScreenState();
}

class _IntervalExercisesScreenState extends State<IntervalExercisesScreen>
    with WidgetsBindingObserver {
  static const _noteMs = 650;
  static const _gapMs = 120;

  final _notePlayer = NotePlayer.instance;
  final _progress = ProgressService();
  final _random = Random();
  final _timer = Stopwatch();

  int _level = 1;
  int _currentLevel = 1;
  int _nextLevel = 1;
  int _roundDone = 0;
  int _sessionQuestions = 0;
  int _sessionCorrect = 0;
  int _sessionStars = 0;
  int _combo = 0;
  int _attempts = 0;
  int _shakeToken = 0;
  int? _shaking;

  bool _loading = true;
  bool _intro = true;
  bool _playing = false;
  bool _saving = false;
  bool _solved = false;
  bool _revealed = false;
  bool _inForeground = true;
  String? _error;
  String? _feedback;
  bool? _feedbackPositive;

  late int _semitones;
  late bool _ascending;
  late int _start;
  final Set<int> _wrong = {};

  List<int> get _options => EarTrainingLevels.intervalSemitones(_level);
  int get _end => _ascending ? _start + _semitones : _start - _semitones;
  bool get _busy => _playing || _saving;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    _timer.stop();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_notePlayer.stopAll());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (!_inForeground) {
      _timer.stop();
      unawaited(_notePlayer.stopAll());
    }
  }

  Future<void> _initialize() async {
    try {
      final values = await Future.wait([
        _progress.buscarProgresso(),
        _notePlayer.initialize(),
      ]);
      final data = values[0] as Map<String, dynamic>;
      final currentLevel = _number(data['nivelIntervalos']).clamp(1, 5).toInt();
      final level = (widget.nivelSelecionado ?? currentLevel)
          .clamp(1, currentLevel)
          .toInt();
      if (!mounted) return;
      setState(() {
        _currentLevel = currentLevel;
        _nextLevel = level;
        _level = level;
        _roundDone = _roundFrom(data, level, currentLevel);
        _newQuestion();
        _loading = false;
        // O nível 1 (sobe ou desce?) não precisa de apresentação.
        _intro = level > 1;
      });
      if (!_intro) unawaited(_playQuestion());
    } catch (error) {
      debugPrint('Falha ao iniciar intervalos: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar seu progresso. Confira a conexão.';
      });
    }
  }

  int _roundFrom(Map<String, dynamic> data, int level, int currentLevel) {
    if (level == currentLevel) return _number(data['tentativasIntervalosNivel']);
    final stages = Map<String, dynamic>.from(
      data['intervaloEtapas'] as Map? ?? const <String, dynamic>{},
    );
    final stage = Map<String, dynamic>.from(
      stages['$level'] as Map? ?? const <String, dynamic>{},
    );
    return _number(stage['rodadaTentativas']);
  }

  void _newQuestion() {
    final options = _options;
    _semitones = options[_random.nextInt(options.length)];
    _ascending = EarTrainingLevels.intervalCanDescend(_level)
        ? _random.nextBool()
        : true;
    final starts = EarTrainingLevels.intervalStarts(
      _semitones,
      descending: !_ascending,
    );
    _start = starts[_random.nextInt(starts.length)];
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

  Future<void> _playInterval(int start, int semitones, bool ascending) async {
    final end = ascending ? start + semitones : start - semitones;
    await _notePlayer.playNote(start, durationMs: _noteMs);
    await Future<void>.delayed(const Duration(milliseconds: _gapMs));
    await _notePlayer.playNote(end, durationMs: _noteMs);
  }

  Future<void> _guarded(Future<void> Function() action) async {
    if (_playing || !_inForeground) return;
    _timer.stop();
    setState(() => _playing = true);
    try {
      await action();
    } catch (error) {
      debugPrint('Falha de áudio nos intervalos: $error');
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

  Future<void> _playQuestion() =>
      _guarded(() => _playInterval(_start, _semitones, _ascending));

  /// Toque longo: ouvir uma opção a partir da mesma nota inicial.
  Future<void> _preview(int semitones) {
    if (_level == 1) {
      // No nível 1 a opção é a direção: toca um salto de quinta nesse sentido.
      final up = semitones > 0;
      return _guarded(() => _playInterval(_start, 7, up));
    }
    return _guarded(() => _playInterval(_start, semitones, _ascending));
  }

  Future<void> _answer(int choice) async {
    if (_busy || _solved || _wrong.contains(choice)) return;
    _timer.stop();
    _attempts++;
    final correct = _level == 1
        ? (choice > 0) == _ascending
        : choice == _semitones;

    if (correct) {
      setState(() {
        _solved = true;
        _feedback = _successText();
        _feedbackPositive = true;
      });
      await _guarded(
        () => _notePlayer.playChord([_start, _end], durationMs: 900),
      );
      final saved = await _record();
      if (saved) await _advance();
      return;
    }

    _wrong.add(choice);
    _shakeToken++;
    if (_attempts >= 3) {
      setState(() {
        _revealed = true;
        _solved = true;
        _shaking = choice;
        _feedback = 'A resposta era ${_answerLabel()}. ${_songLine()}'.trim();
        _feedbackPositive = false;
      });
      await _guarded(() => _playInterval(_start, _semitones, _ascending));
      final saved = await _record();
      if (saved) await _advance(delay: const Duration(milliseconds: 2200));
      return;
    }

    setState(() {
      _shaking = choice;
      _feedback = _level == 1
          ? 'Ouça de novo: o som ${_ascending ? 'sobe' : 'desce'}?'
          : 'Você escolheu ${EarTrainingLevels.intervalName(choice)}. Ouça a diferença.';
      _feedbackPositive = false;
    });
    await _guarded(() async {
      if (_level > 1) {
        await _playInterval(_start, choice, _ascending);
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
      await _playInterval(_start, _semitones, _ascending);
    });
    if (mounted) setState(() => _shaking = null);
  }

  String _answerLabel() => _level == 1
      ? (_ascending ? 'Sobe' : 'Desce')
      : EarTrainingLevels.intervalName(_semitones);

  String _songLine() {
    if (_level == 1) return '';
    final song = intervalTheory[_semitones]?.song;
    return song == null ? '' : 'Lembra: $song.';
  }

  String _successText() {
    final base = _attempts == 1 ? 'Isso!' : 'Muito bem!';
    if (_level == 1) {
      return '$base O som ${_ascending ? 'sobe' : 'desce'}.';
    }
    final song = _songLine();
    return '$base ${EarTrainingLevels.intervalName(_semitones)}. $song'.trim();
  }

  Future<bool> _record() async {
    final countsAsCorrect = AnswerFeedbackRules.countsAsCorrect(
      _attempts,
      revealed: _revealed,
    );
    final stars = AnswerFeedbackRules.starsForAttempt(
      _attempts,
      revealed: _revealed,
    );
    final durationMs = _timer.elapsed.inMilliseconds;
    setState(() => _saving = true);
    try {
      await _progress.registrarExercicio(
        acertou: countsAsCorrect,
        tipo: 'Intervalo',
        pergunta: _level == 1
            ? 'O som sobe ou desce?'
            : 'Qual é este intervalo?',
        resposta: _revealed ? 'Resposta revelada' : _answerLabel(),
        respostaCorreta: _answerLabel(),
        dificuldade: _level,
        questaoId:
            'intervalo_${_level}_${_semitones}_${_ascending ? 'asc' : 'desc'}',
        categoria: 'Percepção de intervalos',
        itemAvaliado: _level == 1
            ? 'Direção do som'
            : EarTrainingLevels.intervalName(_semitones),
        duracaoSegundos: (durationMs / 1000).ceil(),
        duracaoMilissegundos: durationMs,
        tentativas: _attempts,
        estrelas: stars,
      );
      final data = await _progress.buscarProgresso();
      if (!mounted) return false;
      final wasCurrent = _level == _currentLevel;
      final currentLevel = _number(data['nivelIntervalos']).clamp(1, 5).toInt();
      final nextLevel = wasCurrent ? currentLevel : _level;
      setState(() {
        _currentLevel = currentLevel;
        _nextLevel = nextLevel;
        _roundDone = _roundFrom(data, nextLevel, currentLevel);
        _combo = countsAsCorrect && _attempts == 1 ? _combo + 1 : 0;
        _sessionStars += stars;
        _sessionQuestions++;
        if (countsAsCorrect) _sessionCorrect++;
        _saving = false;
      });
      return true;
    } catch (error) {
      debugPrint('Falha ao salvar intervalo: $error');
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _solved = false;
        _revealed = false;
        _feedback = null;
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
    final levelChanged = _nextLevel != _level;
    setState(() {
      _level = _nextLevel;
      _newQuestion();
      _intro = levelChanged && _level > 1;
    });
    if (!_intro) await _playQuestion();
  }

  void _startAfterIntro() {
    setState(() => _intro = false);
    unawaited(_playQuestion());
  }

  Future<void> _openTheory() => showTheoryExplanationSheet(
    context,
    explanation: _level == 1
        ? registerTheory
        : intervalTheory[_semitones] ?? registerTheory,
    theory: _level == 1
        ? registerTheory.theory
        : (intervalTheory[_semitones] ?? registerTheory).theory,
    onPlayExample: _intro ? null : _playQuestion,
    exampleLabel: 'Ouvir a pergunta de novo',
  );

  int _number(dynamic value) => value is num ? value.toInt() : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Intervalos'),
        actions: [
          if (!_loading && _error == null && _level > 1)
            IconButton(
              tooltip: 'Conheça os sons',
              onPressed: _busy ? null : () => setState(() => _intro = true),
              icon: const Icon(Icons.library_music_outlined),
            ),
          IconButton(
            tooltip: 'Entenda a teoria',
            onPressed: _loading ? null : _openTheory,
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : SafeArea(child: _intro ? _introView() : _questionView()),
    );
  }

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _initialize();
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );

  Widget _introView() => Column(
    children: [
      const SizedBox(height: 8),
      ExerciseQuestion(
        'Conheça os sons',
        subtitle: 'Nível $_level · toque para ouvir cada intervalo',
      ),
      const SizedBox(height: 12),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            for (final semitones in _options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _playing
                        ? null
                        : () => _guarded(
                            () => _playInterval(60, semitones, true),
                          ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  EarTrainingLevels.intervalName(semitones),
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (intervalTheory[semitones]?.song != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      intervalTheory[semitones]!.song!,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.primary,
                            size: 38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _playing ? null : _startAfterIntro,
            child: const Text('Começar'),
          ),
        ),
      ),
    ],
  );

  Widget _questionView() => Column(
    children: [
      ExerciseStatusBar(
        level: _level,
        roundDone: _roundDone,
        stars: _sessionStars,
        combo: _combo,
      ),
      ExerciseQuestion(
        _level == 1 ? 'O som sobe ou desce?' : 'Qual é este intervalo?',
      ),
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: _level == 1 ? _directionButtons() : _intervalButtons(),
      ),
      if (_level > 1 && !_solved)
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Segure uma opção para ouvi-la antes de responder',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        )
      else
        const SizedBox(height: 26),
    ],
  );

  AnswerState _stateFor(int choice) {
    final isAnswer = _level == 1
        ? (choice > 0) == _ascending
        : choice == _semitones;
    if (_solved && isAnswer) return AnswerState.correct;
    if (_wrong.contains(choice)) return AnswerState.wrong;
    return AnswerState.normal;
  }

  Widget _directionButtons() => Row(
    children: [
      for (final choice in const [1, -1]) ...[
        if (choice == -1) const SizedBox(width: 12),
        Expanded(
          child: AnswerPill(
            label: choice > 0 ? 'Sobe' : 'Desce',
            icon: choice > 0
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            height: 72,
            minWidth: 0,
            state: _stateFor(choice),
            enabled: !_busy && !_solved,
            shaking: _shaking == choice,
            shakeToken: _shakeToken,
            onTap: () => _answer(choice),
            onLongPress: () => _preview(choice),
          ),
        ),
      ],
    ],
  );

  Widget _intervalButtons() => Wrap(
    alignment: WrapAlignment.center,
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final semitones in _options)
        AnswerPill(
          label: EarTrainingLevels.intervalName(semitones),
          minWidth: _options.length > 6 ? 100.0 : 136.0,
          state: _stateFor(semitones),
          enabled: !_busy && !_solved,
          shaking: _shaking == semitones,
          shakeToken: _shakeToken,
          onTap: () => _answer(semitones),
          onLongPress: () => _preview(semitones),
        ),
    ],
  );
}
