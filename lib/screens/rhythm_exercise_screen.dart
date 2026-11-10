import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../services/music_audio_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';

class RhythmExerciseScreen extends StatefulWidget {
  const RhythmExerciseScreen({super.key});

  @override
  State<RhythmExerciseScreen> createState() => _RhythmExerciseScreenState();
}

class _RhythmExerciseScreenState extends State<RhythmExerciseScreen>
    with WidgetsBindingObserver {
  static const _background = AppColors.background;
  static const _accent = AppColors.primary;
  static const _downbeatSound = 'metronome_downbeat.wav';
  static const _beatSound = 'metronome_beat.wav';
  static const _rhythmSound = 'rhythm_note.wav';
  static const _patterns = <List<double>>[
    [0, 1, 2, 3],
    [0, 1.5, 2, 3.5],
    [0, 0.5, 1.5, 2.5, 3],
    [0, 1, 2.5, 3],
    [0, 0.5, 1, 2.5, 3.5],
  ];

  final _progress = ProgressService();
  final _audio = MusicAudioService.instance;
  final _random = Random();
  final _clock = Stopwatch();
  final List<int> _tapTimesMs = [];
  Timer? _timer;

  int _level = 1;
  int _attempts = 0;
  int _bpm = 80;
  int _pulse = -1;
  bool _loading = true;
  bool _playing = false;
  bool _recording = false;
  bool _saving = false;
  bool _showHint = false;
  double? _averageErrorMs;
  bool? _correct;
  late List<double> _target;
  late int _patternIndex;

  Duration get _beat => Duration(milliseconds: (60000 / _bpm).round());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _timer?.cancel();
      _clock.stop();
      _audio.stopAll();
      if (mounted && (_playing || _recording)) {
        setState(() {
          _playing = false;
          _recording = false;
        });
      }
    }
  }

  Future<void> _initialize() async {
    try {
      final results = await Future.wait([
        _progress.buscarProgresso(),
        AppPreferences.defaultBpm(),
      ]);
      final data = results.first as Map<String, dynamic>;
      final preferences = Map<String, dynamic>.from(
        data['habilidadesEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final rhythm = Map<String, dynamic>.from(
        preferences['ritmo'] as Map? ?? const <String, dynamic>{},
      );
      _level = _number(rhythm['nivel']).clamp(1, 5).toInt();
      _attempts = _number(
        Map<String, dynamic>.from(
          rhythm['$_level'] as Map? ?? const <String, dynamic>{},
        )['rodadaTentativas'],
      );
      _bpm = results.last as int;
      _newPattern();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _newPattern() {
    final available = min(_level, _patterns.length);
    _patternIndex = _random.nextInt(available);
    _target = List<double>.from(_patterns[_patternIndex]);
  }

  Future<void> _listen() async {
    if (_playing || _recording || _saving) return;
    setState(() {
      _playing = true;
      _pulse = -1;
    });
    try {
      await _audio.preload([_downbeatSound, _beatSound, _rhythmSound]);
      final clock = Stopwatch()..start();
      for (var halfBeat = 0; halfBeat < 8; halfBeat++) {
        if (!mounted) return;
        if (halfBeat.isEven) {
          final beat = halfBeat ~/ 2;
          setState(() => _pulse = beat);
          unawaited(
            _audio.playFor(
              beat == 0 ? _downbeatSound : _beatSound,
              const Duration(milliseconds: 70),
            ),
          );
        }
        if (_target.any((value) => (value - halfBeat / 2).abs() < 0.01)) {
          unawaited(
            _audio.playFor(_rhythmSound, const Duration(milliseconds: 85)),
          );
        }
        final nextTick = Duration(
          milliseconds: (_beat.inMilliseconds * (halfBeat + 1) / 2).round(),
        );
        final remaining = nextTick - clock.elapsed;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível reproduzir o ritmo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _startRecording() async {
    if (_playing || _recording || _saving) return;
    setState(() {
      _playing = true;
      _pulse = -1;
      _tapTimesMs.clear();
      _averageErrorMs = null;
      _correct = null;
    });
    try {
      await _audio.preload([_downbeatSound, _beatSound]);
      // Four audible count-in beats give the learner a stable tempo anchor.
      final countInClock = Stopwatch()..start();
      for (var beat = 0; beat < 4; beat++) {
        if (!mounted) return;
        setState(() => _pulse = beat);
        unawaited(
          _audio.playFor(
            beat == 0 ? _downbeatSound : _beatSound,
            const Duration(milliseconds: 70),
          ),
        );
        final nextTick = Duration(
          milliseconds: _beat.inMilliseconds * (beat + 1),
        );
        final remaining = nextTick - countInClock.elapsed;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      if (!mounted) return;
      _clock
        ..reset()
        ..start();
      setState(() {
        _playing = false;
        _recording = true;
        _pulse = 0;
      });
      var lastPulse = 0;
      _timer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
        if (!mounted || !_recording) {
          timer.cancel();
          return;
        }
        final elapsed = _clock.elapsedMilliseconds;
        final beatIndex = (elapsed / _beat.inMilliseconds).floor();
        if (beatIndex != lastPulse && beatIndex < 4) {
          lastPulse = beatIndex;
          setState(() => _pulse = beatIndex);
          unawaited(
            _audio.playFor(_beatSound, const Duration(milliseconds: 70)),
          );
        }
        if (elapsed >= _beat.inMilliseconds * 4 + _beat.inMilliseconds ~/ 2) {
          timer.cancel();
          _clock.stop();
          setState(() => _recording = false);
          unawaited(_finishRecording());
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _recording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível iniciar o exercício.'),
          ),
        );
      }
    }
  }

  void _tap() {
    if (!_recording) return;
    setState(() => _tapTimesMs.add(_clock.elapsedMilliseconds));
  }

  Future<void> _finishRecording() async {
    final expected = _target
        .map((halfBeat) => (halfBeat * _beat.inMilliseconds / 2).round())
        .toList();
    final count = max(expected.length, _tapTimesMs.length);
    var totalError = 0.0;
    for (var index = 0; index < count; index++) {
      if (index >= expected.length || index >= _tapTimesMs.length) {
        totalError += _beat.inMilliseconds * 0.5;
      } else {
        totalError += (_tapTimesMs[index] - expected[index]).abs();
      }
    }
    final average = count == 0
        ? _beat.inMilliseconds.toDouble()
        : totalError / count;
    final tolerance = max(135, _beat.inMilliseconds * 0.22);
    final correct =
        _tapTimesMs.length == expected.length && average <= tolerance;
    setState(() {
      _averageErrorMs = average;
      _correct = correct;
      _saving = true;
    });

    try {
      await _progress.registrarExercicio(
        acertou: correct,
        tipo: 'Ritmo',
        pergunta: 'Reproduza o padrão rítmico do nível $_level em $_bpm BPM.',
        resposta:
            '${_tapTimesMs.length} batidas; erro médio ${average.round()} ms',
        respostaCorreta: '${expected.length} batidas no padrão ouvido',
        dificuldade: _level,
        questaoId: 'ritmo_${_level}_$_patternIndex',
        categoria: 'Ditado rítmico',
        duracaoMilissegundos: _clock.elapsedMilliseconds,
      );
      final data = await _progress.buscarProgresso();
      final skills = Map<String, dynamic>.from(
        data['habilidadesEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final rhythm = Map<String, dynamic>.from(
        skills['ritmo'] as Map? ?? const <String, dynamic>{},
      );
      final level = _number(rhythm['nivel']).clamp(1, 5).toInt();
      final stage = Map<String, dynamic>.from(
        rhythm['$level'] as Map? ?? const <String, dynamic>{},
      );
      if (mounted) {
        setState(() {
          _level = level;
          _attempts = _number(stage['rodadaTentativas']);
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o resultado.')),
        );
      }
    }
  }

  Future<void> _next() async {
    setState(() {
      _showHint = false;
      _averageErrorMs = null;
      _correct = null;
      _newPattern();
    });
    await _listen();
  }

  Future<void> _changeBpm(int value) async {
    final bpm = value.clamp(40, 180);
    await AppPreferences.setDefaultBpm(bpm);
    if (mounted) setState(() => _bpm = bpm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('Ditado rítmico'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _panel(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.graphic_eq,
                          color: _background,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nível $_level · ${_levelName(_level)}',
                          style: const TextStyle(
                            color: _background,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.slow_motion_video,
                              color: _background,
                            ),
                            const Text(
                              'BPM',
                              style: TextStyle(
                                color: _background,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _bpm.toDouble(),
                                min: 40,
                                max: 180,
                                divisions: 28,
                                label: '$_bpm',
                                onChanged: _playing || _recording
                                    ? null
                                    : (value) => _changeBpm(value.round()),
                              ),
                            ),
                            Text(
                              '$_bpm',
                              style: const TextStyle(
                                color: _background,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$_attempts/10 tentativas · 7 acertos liberam a próxima fase',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _recording ? _tap : null,
                    behavior: HitTestBehavior.opaque,
                    child: _beatDisplay(),
                  ),
                  if (_recording)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Toque no pulso para reproduzir o ritmo',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_averageErrorMs == null) ...[
                    OutlinedButton.icon(
                      onPressed: _playing || _recording || _saving
                          ? null
                          : _listen,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Ouvir o ritmo'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _playing || _recording || _saving
                          ? null
                          : _startRecording,
                      icon: const Icon(Icons.mic_none),
                      label: Text(
                        _playing ? 'Prepare-se…' : 'Repetir com batidas',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showHint = !_showHint),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(
                        _showHint ? 'Ocultar dica' : 'Preciso de uma dica',
                      ),
                    ),
                    if (_showHint) _hintCard,
                  ] else ...[
                    _resultCard,
                    if (_saving)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(color: _accent),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Próximo ritmo'),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _beatDisplay() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(4, (index) {
      final active = _pulse == index;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        width: active ? 56 : 46,
        height: active ? 56 : 46,
        decoration: BoxDecoration(
          color: active ? _accent : Colors.white12,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: active ? _background : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      );
    }),
  );

  Widget get _hintCard => _learningCard(
    'Conte “1 e 2 e 3 e 4 e”. Os números marcam as batidas principais; o “e” ajuda a localizar toques no contratempo. Espere quatro pulsos de contagem e comece no primeiro tempo.',
    Icons.lightbulb_outline,
  );

  Widget get _resultCard => _learningCard(
    '${_correct == true ? 'Boa! ' : 'Vamos ajustar o pulso. '}${_tapTimesMs.length} toques registrados para ${_target.length} batidas-alvo. Erro médio: ${_averageErrorMs!.round()} ms. ${_correct == true ? 'Você manteve o padrão dentro da tolerância deste nível.' : 'Ouça novamente e conte os contratempos antes de tocar.'}',
    _correct == true ? Icons.check_circle_outline : Icons.school_outlined,
  );

  String get _instruction => switch (_level) {
    1 => 'Comece sentindo quatro pulsos regulares. Toque junto com cada pulso.',
    2 => 'Agora alguns sons caem entre os pulsos. Conte também o “e”.',
    3 => 'Combine pulsos e contratempos; mantenha a subdivisão constante.',
    4 => 'Observe os silêncios e retome no tempo certo.',
    _ => 'Desafio misto: ouça, conte e repita o padrão no tempo.',
  };

  String _levelName(int level) => const [
    'Pulso',
    'Contratempo',
    'Subdivisão',
    'Silêncio',
    'Desafio misto',
  ][level - 1];

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF4E5), Color(0xFFEFE0CF)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _learningCard(String text, IconData icon) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _background),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _background, height: 1.4),
          ),
        ),
      ],
    ),
  );

  int _number(dynamic value) => value is num ? value.toInt() : 0;
}
