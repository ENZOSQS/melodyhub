import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/theory_explanations.dart';
import '../domain/tempo_rules.dart';
import '../services/music_audio_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_ui.dart';
import '../widgets/theory_explanation_sheet.dart';

/// Andamento (BPM): ouvir o andamento, ajustar o número, ouvir o próprio
/// andamento para comparar quantas vezes quiser e só então confirmar.
class RhythmExerciseScreen extends StatefulWidget {
  const RhythmExerciseScreen({super.key});

  @override
  State<RhythmExerciseScreen> createState() => _RhythmExerciseScreenState();
}

enum _Playing { none, target, guess }

class _RhythmExerciseScreenState extends State<RhythmExerciseScreen>
    with WidgetsBindingObserver {
  static const _downbeat = 'metronome_downbeat.wav';
  static const _beat = 'metronome_beat.wav';
  static const _theory = TheoryExplanation(
    objective: 'Perceber a velocidade de uma música, o andamento.',
    theory:
        'BPM quer dizer batidas por minuto. 60 BPM é uma batida por segundo; '
        '120 BPM são duas por segundo. Ouça o andamento, ajuste o número e '
        'compare os dois até soarem iguais. Bater o pé junto ajuda a sentir o pulso.',
  );

  final _progress = ProgressService();
  final _audio = MusicAudioService.instance;
  final _random = Random();
  final _timer = Stopwatch();

  int _level = 1;
  int _roundDone = 0;
  int _sessionQuestions = 0;
  int _sessionCorrect = 0;
  int _sessionStars = 0;
  int _target = 90;
  int _guess = 110;
  int _pulse = -1;
  int _playToken = 0;
  _Playing _playing = _Playing.none;
  bool _loading = true;
  bool _saving = false;
  bool _inForeground = true;
  bool _heardTarget = false;
  TempoResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    _playToken++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (!_inForeground) {
      _playToken++;
      if (mounted) {
        setState(() {
          _playing = _Playing.none;
          _pulse = -1;
        });
      }
    }
  }

  Future<void> _initialize() async {
    try {
      final values = await Future.wait([
        _progress.buscarProgresso(),
        _audio.preload(const [_downbeat, _beat]),
      ]);
      final data = values[0] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _applyProgress(data);
        _newQuestion();
        _loading = false;
      });
    } catch (error) {
      debugPrint('Falha ao iniciar o exercício de BPM: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar o exercício. Confira a conexão.';
      });
    }
  }

  void _applyProgress(Map<String, dynamic> data) {
    final skills = Map<String, dynamic>.from(
      data['habilidadesEtapas'] as Map? ?? const <String, dynamic>{},
    );
    final rhythm = Map<String, dynamic>.from(
      skills['ritmo'] as Map? ?? const <String, dynamic>{},
    );
    _level = _number(rhythm['nivel']).clamp(1, 5).toInt();
    final stage = Map<String, dynamic>.from(
      rhythm['$_level'] as Map? ?? const <String, dynamic>{},
    );
    _roundDone = _number(stage['rodadaTentativas']);
  }

  void _newQuestion() {
    final range = TempoRules.bpmRange(_level);
    _target = range.min + _random.nextInt(range.max - range.min + 1);
    final offset = (12 + _random.nextInt(18)) * (_random.nextBool() ? 1 : -1);
    _guess = TempoRules.startingGuess(_target, offset);
    _result = null;
    _heardTarget = false;
    _timer
      ..stop()
      ..reset();
  }

  /// Toca 4 tempos (o 1º acentuado) e acende um ponto em cada tempo.
  Future<void> _playBeats(int bpm, _Playing which) async {
    if (!mounted) return;
    final token = ++_playToken;
    setState(() {
      _playing = which;
      _pulse = -1;
    });
    final beatMs = TempoRules.beatMs(bpm);
    final clock = Stopwatch()..start();
    try {
      for (var beat = 0; beat < 4; beat++) {
        if (!mounted || token != _playToken || !_inForeground) return;
        setState(() => _pulse = beat);
        unawaited(_audio.playOneShot(beat == 0 ? _downbeat : _beat));
        final remaining =
            Duration(milliseconds: beatMs * (beat + 1)) - clock.elapsed;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
    } catch (error) {
      debugPrint('Falha ao tocar o metrônomo: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar as batidas. Aumente o volume e tente de novo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && token == _playToken) {
        setState(() {
          _playing = _Playing.none;
          _pulse = -1;
        });
      }
    }
  }

  Future<void> _listenTarget() async {
    if (_playing != _Playing.none || _saving) return;
    _heardTarget = true;
    _timer.start();
    await _playBeats(_target, _Playing.target);
  }

  Future<void> _listenGuess() async {
    if (_playing != _Playing.none || _saving) return;
    await _playBeats(_guess, _Playing.guess);
  }

  void _change(int delta) {
    if (_result != null) return;
    setState(() => _guess = TempoRules.clampBpm(_guess + delta));
  }

  Future<void> _confirm() async {
    if (_playing != _Playing.none || _saving || _result != null) return;
    _timer.stop();
    final result = TempoRules.evaluate(
      level: _level,
      target: _target,
      guess: _guess,
    );
    setState(() {
      _result = result;
      _saving = true;
    });
    try {
      await _progress.registrarExercicio(
        acertou: result.correct,
        tipo: 'Ritmo',
        pergunta: 'Qual é o andamento (BPM) que você ouviu?',
        resposta: '${result.guess} BPM',
        respostaCorreta: '${result.target} BPM',
        dificuldade: _level,
        questaoId: 'bpm_nivel_$_level',
        categoria: 'Andamento (BPM)',
        itemAvaliado: 'bpm_nivel$_level',
        duracaoSegundos: (_timer.elapsedMilliseconds / 1000).ceil(),
        duracaoMilissegundos: _timer.elapsedMilliseconds,
        tentativas: 1,
        estrelas: result.stars,
      );
      final data = await _progress.buscarProgresso();
      if (!mounted) return;
      setState(() {
        _applyProgress(data);
        _sessionQuestions++;
        _sessionStars += result.stars;
        if (result.correct) _sessionCorrect++;
        _saving = false;
      });
      // Toca o original e o do aluno em sequência, para comparar.
      await _playBeats(_target, _Playing.target);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) await _playBeats(_guess, _Playing.guess);
    } catch (error) {
      debugPrint('Falha ao salvar o BPM: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _result = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar sua resposta. Confira a conexão e confirme de novo.',
          ),
        ),
      );
    }
  }

  Future<void> _next() async {
    _playToken++;
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
    setState(() {
      _playing = _Playing.none;
      _pulse = -1;
      _newQuestion();
    });
  }

  Future<void> _openTheory() => showTheoryExplanationSheet(
    context,
    explanation: _theory,
    theory: _theory.theory,
  );

  int _number(dynamic value) => value is num ? value.toInt() : 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Andamento (BPM)'),
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
          )
        : SafeArea(
            child: Column(
              children: [
                ExerciseStatusBar(
                  level: _level,
                  roundDone: _roundDone,
                  stars: _sessionStars,
                ),
                const ExerciseQuestion('Ajuste o BPM até ficar igual'),
                const SizedBox(height: 18),
                _pulseDots(),
                Expanded(child: Center(child: _bpmControl())),
                if (_result != null) _resultView() else const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: _actions(),
                ),
              ],
            ),
          ),
  );

  Widget _pulseDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(4, (index) {
      final active = _pulse == index;
      final color = _playing == _Playing.guess
          ? AppColors.secondary
          : AppColors.primary;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        margin: const EdgeInsets.symmetric(horizontal: 9),
        width: active ? 26 : 16,
        height: active ? 26 : 16,
        decoration: BoxDecoration(
          color: active ? color : AppColors.surfaceRaised,
          shape: BoxShape.circle,
        ),
      );
    }),
  );

  Widget _bpmControl() {
    final locked = _result != null || _saving;
    Widget step(int delta) => SizedBox(
      width: 64,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: locked ? null : () => _change(delta),
        child: Text(delta > 0 ? '+$delta' : '$delta'),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_guess',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 72,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const Text('BPM', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            step(-5),
            const SizedBox(width: 8),
            step(-1),
            const SizedBox(width: 20),
            step(1),
            const SizedBox(width: 8),
            step(5),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Slider(
            value: _guess.toDouble(),
            min: TempoRules.minBpm.toDouble(),
            max: TempoRules.maxBpm.toDouble(),
            onChanged: locked
                ? null
                : (value) => setState(() => _guess = value.round()),
          ),
        ),
      ],
    );
  }

  Widget _resultView() {
    final result = _result!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Era ${result.target} · você marcou ${result.guess}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ExerciseFeedbackLine(
            '${result.description} ${'★' * result.stars}'.trim(),
            positive: result.correct,
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    if (_result != null) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _saving ? null : _next,
          child: const Text('Próximo'),
        ),
      );
    }
    final busy = _playing != _Playing.none || _saving;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton.tonalIcon(
                  onPressed: busy ? null : _listenTarget,
                  icon: Icon(
                    _playing == _Playing.target
                        ? Icons.graphic_eq_rounded
                        : Icons.volume_up_rounded,
                  ),
                  label: const Text('Ouvir o original'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _listenGuess,
                  icon: Icon(
                    _playing == _Playing.guess
                        ? Icons.graphic_eq_rounded
                        : Icons.hearing_rounded,
                  ),
                  label: const Text('Ouvir o meu'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: busy || !_heardTarget ? null : _confirm,
            child: const Text('Confirmar'),
          ),
        ),
      ],
    );
  }
}
