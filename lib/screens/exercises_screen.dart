import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/theory_explanations.dart';
import '../domain/answer_feedback_rules.dart';
import '../domain/note_identification_rules.dart';
import '../services/app_preferences.dart';
import '../services/note_player.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../utils/note_names.dart';
import '../widgets/theory_explanation_sheet.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key, this.nivelSelecionado});

  final int? nivelSelecionado;

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen>
    with WidgetsBindingObserver {
  final NotePlayer _notePlayer = NotePlayer.instance;
  final ProgressService _progress = ProgressService();
  final math.Random _random = math.Random();
  final Stopwatch _questionTimer = Stopwatch();

  int _level = 1;
  int _currentLevel = 1;
  int _nextLevel = 1;
  int _attemptsAtLevel = 0;
  int _sessionQuestions = 0;
  int _sessionStars = 0;
  int _combo = 0;
  int _attempts = 0;
  int _targetMidi = 60;
  int? _selectedMidi;
  List<int> _resolution = const [];
  int _resolutionStep = -1;
  int? _shakingMidi;
  int _shakeToken = 0;
  String _noteType = 'solfejo';
  bool _loading = true;
  bool _playing = false;
  bool _saving = false;
  bool _revealed = false;
  bool _inForeground = true;
  bool _pendingAdvance = false;
  bool _advanceScheduled = false;
  String? _error;
  final Set<int> _wrongMidis = {};

  List<int> get _options => NoteIdentificationRules.notesForLevel(_level);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inForeground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionTimer.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (!_inForeground) {
      _questionTimer.stop();
      unawaited(_notePlayer.stopAll());
    } else if (!_loading && !_playing && !_saving) {
      if (_pendingAdvance) {
        unawaited(_advanceAfterFeedback());
      } else if (_selectedMidi == null) {
        _questionTimer.start();
      }
    }
  }

  Future<void> _initialize() async {
    try {
      final values = await Future.wait([
        _progress.buscarProgresso(),
        AppPreferences.noteType(),
        _notePlayer.initialize(),
      ]);
      final data = values[0] as Map<String, dynamic>;
      final currentLevel = _number(data['nivelPratico']).clamp(1, 5).toInt();
      final level = (widget.nivelSelecionado ?? currentLevel)
          .clamp(1, currentLevel)
          .toInt();
      final stages = Map<String, dynamic>.from(
        data['praticaEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final stage = Map<String, dynamic>.from(
        stages['$level'] as Map? ?? const <String, dynamic>{},
      );
      if (!mounted) return;
      setState(() {
        _noteType = values[1] as String;
        _currentLevel = currentLevel;
        _nextLevel = currentLevel;
        _level = level;
        _attemptsAtLevel = level == currentLevel
            ? _number(data['tentativasPraticasNivel'])
            : _number(stage['rodadaTentativas']);
        _loading = false;
        _newTarget();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_playQuestion(withContext: true));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar seu exercício. Tente novamente.';
      });
      debugPrint('Falha ao iniciar Identificar a nota: $error');
    }
  }

  void _newTarget() {
    _targetMidi = NoteIdentificationRules.drawTarget(_level, _random);
    _attempts = 0;
    _selectedMidi = null;
    _resolution = const [];
    _resolutionStep = -1;
    _shakingMidi = null;
    _revealed = false;
    _wrongMidis.clear();
    _questionTimer
      ..stop()
      ..reset();
  }

  Future<void> _playQuestion({required bool withContext}) async {
    if (_playing ||
        _saving ||
        _loading ||
        _selectedMidi != null ||
        !_inForeground) {
      return;
    }
    _questionTimer.stop();
    setState(() => _playing = true);
    try {
      if (withContext) {
        await _playCadence();
        // Pausa curta para separar a cadência da nota misteriosa.
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
      await _notePlayer.playNote(_targetMidi, durationMs: 650);
    } catch (error) {
      debugPrint('Falha ao tocar a questão: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível tocar o som.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _playing = false);
        if (_selectedMidi == null && _inForeground) _questionTimer.start();
      }
    }
  }

  Future<void> _playCadence() async {
    for (final chord in NoteIdentificationRules.cadenceChords) {
      if (!mounted || !_inForeground) return;
      // 320 ms de sustentação + 300 ms de release: cerca de 0,6 s por acorde.
      await _notePlayer.playChord(chord, durationMs: 320);
    }
  }

  Future<void> _answer(int midi) async {
    if (_playing ||
        _saving ||
        _loading ||
        _selectedMidi != null ||
        _wrongMidis.contains(midi)) {
      return;
    }
    _questionTimer.stop();
    _attempts++;
    final outcome = NoteIdentificationRules.evaluate(
      target: _targetMidi,
      selected: midi,
      attempt: _attempts,
    );
    if (outcome == NoteAnswerOutcome.correct) {
      setState(() {
        _selectedMidi = midi;
        _saving = true;
        _pendingAdvance = true;
      });
      final saved = await _recordAnswer(midi);
      if (!mounted) return;
      if (!saved) {
        setState(() {
          _selectedMidi = null;
          _pendingAdvance = false;
        });
        _questionTimer.start();
        return;
      }
      await _playResolution();
      await _advanceAfterFeedback();
      return;
    }

    _wrongMidis.add(midi);
    _shakeToken++;
    if (outcome == NoteAnswerOutcome.tryAgain) {
      setState(() {
        _shakingMidi = midi;
        _playing = true;
      });
      try {
        await _notePlayer.playNote(midi, durationMs: 400);
        await _notePlayer.playNote(_targetMidi, durationMs: 400);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível tocar a nota.')),
          );
        }
        debugPrint('Falha ao repetir a nota: $error');
      } finally {
        if (mounted) {
          setState(() {
            _playing = false;
            _shakingMidi = null;
          });
          _questionTimer.start();
        }
      }
      return;
    }

    setState(() {
      _selectedMidi = midi;
      _revealed = true;
      _saving = true;
      _playing = true;
      _pendingAdvance = true;
    });
    try {
      await _notePlayer.playNote(midi, durationMs: 350);
      await _notePlayer.playNote(_targetMidi, durationMs: 450);
      final saved = await _recordAnswer(midi, revealed: true);
      if (mounted && saved) await _playResolution();
      if (mounted && saved) {
        await _advanceAfterFeedback();
      } else if (mounted) {
        _resetQuestionAfterFailure();
      }
    } catch (error) {
      if (mounted) _resetQuestionAfterFailure();
      debugPrint('Falha ao tocar a resposta e resolução: $error');
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  /// Se salvar falhar, a mesma questão volta do zero.
  void _resetQuestionAfterFailure() {
    setState(() {
      _playing = false;
      _selectedMidi = null;
      _revealed = false;
      _wrongMidis.clear();
      _attempts = 0;
      _pendingAdvance = false;
      _resolution = const [];
      _resolutionStep = -1;
    });
    _questionTimer.start();
  }

  Future<void> _playResolution() async {
    // A resolução aparece só como texto ("Mi → Ré → Dó"); os botões não
    // mudam, para não parecer que o app está respondendo sozinho.
    final resolution = NoteIdentificationRules.resolutionFor(_targetMidi);
    setState(() => _resolution = resolution);
    for (var step = 0; step < resolution.length; step++) {
      if (!mounted || !_inForeground) break;
      setState(() => _resolutionStep = step);
      await _notePlayer.playNote(resolution[step], durationMs: 300);
    }
  }

  Future<void> _advanceAfterFeedback() async {
    if (_advanceScheduled || !_pendingAdvance) return;
    _advanceScheduled = true;
    await Future<void>.delayed(const Duration(seconds: 1));
    _advanceScheduled = false;
    if (!mounted || !_inForeground) return;
    setState(() {
      _pendingAdvance = false;
      _level = _nextLevel;
      if (_sessionQuestions >= 10) {
        _sessionQuestions = 0;
        _sessionStars = 0;
      }
      _newTarget();
    });
    await _playQuestion(withContext: true);
  }

  Future<bool> _recordAnswer(int selected, {bool revealed = false}) async {
    final isCountedCorrect = AnswerFeedbackRules.countsAsCorrect(
      _attempts,
      revealed: revealed,
    );
    final stars = revealed ? 0 : AnswerFeedbackRules.starsForAttempt(_attempts);
    final durationMs = _questionTimer.elapsed.inMilliseconds;
    try {
      await _progress.registrarExercicio(
        acertou: isCountedCorrect,
        tipo: 'Prático',
        pergunta: 'Qual nota da escala de Dó maior você ouviu?',
        resposta: _label(selected),
        respostaCorreta: _label(_targetMidi),
        dificuldade: _level,
        questaoId: 'nota_nivel_$_level',
        categoria: 'Identificação de notas',
        itemAvaliado: NoteIdentificationRules.criticalItemFor(_targetMidi),
        duracaoSegundos: (durationMs / 1000).ceil(),
        duracaoMilissegundos: durationMs,
        tentativas: _attempts,
        estrelas: stars,
      );
      final data = await _progress.buscarProgresso();
      if (!mounted) return false;
      final wasCurrentLevel = _level == _currentLevel;
      final currentLevel = _number(data['nivelPratico']).clamp(1, 5).toInt();
      final nextLevel = wasCurrentLevel ? currentLevel : _level;
      final stages = Map<String, dynamic>.from(
        data['praticaEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final stage = Map<String, dynamic>.from(
        stages['$nextLevel'] as Map? ?? const <String, dynamic>{},
      );
      setState(() {
        _currentLevel = currentLevel;
        _nextLevel = nextLevel;
        _attemptsAtLevel = nextLevel == currentLevel
            ? _number(data['tentativasPraticasNivel'])
            : _number(stage['rodadaTentativas']);
        _combo = isCountedCorrect && _attempts == 1 ? _combo + 1 : 0;
        _sessionStars += stars;
        _sessionQuestions++;
        _saving = false;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar sua resposta. Tente novamente.',
          ),
        ),
      );
      debugPrint('Falha ao salvar Identificar a nota: $error');
      return false;
    }
  }

  String _label(int midi) {
    final name = nomeNota(midi, _noteType);
    if (_level != 5) return name;
    final octave = midi ~/ 12 - 1;
    return '$name $octave';
  }

  Future<void> _openTheory() => showTheoryExplanationSheet(
    context,
    explanation: practiceNoteTheory,
    theory: practiceNoteTheory.theory,
    onPlayExample: () => _playQuestion(withContext: true),
    exampleLabel: 'Ouvir a cadência e a nota',
  );

  int _number(dynamic value) => value is num ? value.toInt() : 0;

  NoteButtonState _buttonState(int midi) => NoteIdentificationRules.buttonState(
    midi: midi,
    target: _targetMidi,
    wrongMidis: _wrongMidis,
    finished: _selectedMidi != null,
    revealed: _revealed,
  );

  Color _optionColor(NoteButtonState state) => switch (state) {
    NoteButtonState.correct => const Color(0xFF367F50),
    NoteButtonState.revealed => const Color(0xFF55A86A),
    NoteButtonState.wrong => const Color(0xFF6A343B),
    NoteButtonState.idle => AppColors.surfaceRaised,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Identificar a nota'),
        actions: [
          IconButton(
            tooltip: 'Entenda a teoria',
            onPressed: _openTheory,
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
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
            )
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: List.generate(10, (index) {
                              final isDone = index < _attemptsAtLevel;
                              return Expanded(
                                child: Container(
                                  height: 5,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? AppColors.primary
                                        : AppColors.surfaceRaised,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nível $_level',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '★ $_sessionStars',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        if (_combo > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '↻ $_combo',
                            style: const TextStyle(color: AppColors.secondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Text(
                    'Qual é esta nota?',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Tom de Dó maior',
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _playQuestion(withContext: false),
                        onLongPress: () => _playQuestion(withContext: true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _playing
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: _playing ? 0.20 : 0.08,
                                ),
                                blurRadius: 26,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _playing
                                    ? Icons.graphic_eq_rounded
                                    : Icons.replay_rounded,
                                color: AppColors.primary,
                                size: 40,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _playing ? 'Ouvindo' : 'Repetir',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedMidi != null) _feedback(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 10,
                      children: _options.map(_answerButton).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _feedback() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Text(
            _revealed
                ? 'A resposta era ${_label(_targetMidi)}'
                : 'Muito bem! ${_label(_targetMidi)}',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_resolution.length > 1) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  for (var i = 0; i < _resolution.length; i++) ...[
                    if (i > 0) const TextSpan(text: ' → '),
                    TextSpan(
                      text: _label(_resolution[i]),
                      style: TextStyle(
                        color: i == _resolutionStep
                            ? AppColors.primary
                            : AppColors.muted,
                        fontWeight: i == _resolutionStep
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _answerButton(int midi) {
    final state = _buttonState(midi);
    final color = _optionColor(state);
    final isTonic = midi % 12 == 0;

    final isDisabled =
        _playing ||
        _saving ||
        _selectedMidi != null ||
        _wrongMidis.contains(midi);
    final label = _label(midi);
    final diameter = _level == 5 ? 66.0 : 72.0;
    return TweenAnimationBuilder<double>(
      key: ValueKey('shake-$midi-$_shakeToken'),
      tween: Tween(begin: 0, end: _shakingMidi == midi ? 1 : 0),
      duration: const Duration(milliseconds: 280),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(math.sin(value * math.pi * 6) * 5 * (1 - value), 0),
        child: child,
      ),
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Material(
            color: color,
            // O Dó (tônica) é marcado só pela borda, para não parecer
            // uma resposta já escolhida.
            shape: CircleBorder(
              side: isTonic && state == NoteButtonState.idle
                  ? const BorderSide(color: AppColors.primary, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isDisabled ? null : () => _answer(midi),
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: state == NoteButtonState.wrong ? 0.28 : 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: _level == 5 ? 13 : 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
