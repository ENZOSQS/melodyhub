import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/feedback_rules.dart';
import '../services/music_audio_service.dart';
import '../services/progress_service.dart';
import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/note_names.dart';
import '../utils/sample_map.dart';
import '../widgets/mh_ui.dart';
import '../widgets/piano_answer_keyboard.dart';

class IntervalExercisesScreen extends StatefulWidget {
  const IntervalExercisesScreen({super.key, this.nivelSelecionado});

  final int? nivelSelecionado;

  @override
  State<IntervalExercisesScreen> createState() =>
      _IntervalExercisesScreenState();
}

class _IntervalExercisesScreenState extends State<IntervalExercisesScreen>
    with WidgetsBindingObserver {
  static const _background = Color(0xFF171316);
  static const _accent = Color(0xFFE9B96E);
  static const Duration _duracaoNormal = Duration(milliseconds: 300);
  static const Duration _duracaoLenta = Duration(milliseconds: 620);
  static const Duration _pausaNormal = Duration(milliseconds: 55);
  static const Duration _pausaLenta = Duration(milliseconds: 150);
  static final _notes = List.generate(
    13,
    (index) => (index, SampleMap.piano(48 + index)),
  );
  static const _intervalNames = [
    '',
    'Segunda menor',
    'Segunda maior',
    'Terça menor',
    'Terça maior',
    'Quarta justa',
    'Trítono',
    'Quinta justa',
    'Sexta menor',
    'Sexta maior',
    'Sétima menor',
    'Sétima maior',
    'Oitava justa',
  ];
  static const _intervalsByLevel = [
    [2, 4],
    [2, 3, 4, 5],
    [2, 3, 4, 5, 7],
    [2, 3, 4, 5, 7, 8, 9, 10],
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  ];

  final _audio = MusicAudioService.instance;
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
  bool _showHint = false;
  bool _showExplanation = false;
  bool _slowAudio = false;
  bool _inForeground = true;
  String? _selected;
  int _nextLevel = 1;
  int _nextAttempts = 0;
  int _sequenciaAcertosSessao = 0;
  int? _ultimaNotaTocada;
  NivelApoio? _apoioResposta;
  late int _degree;
  late bool _ascending;
  late (int, MappedSample) _firstNote;
  late (int, MappedSample) _secondNote;
  String _tipoNota = 'solfejo';

  Duration get _noteDuration => _slowAudio ? _duracaoLenta : _duracaoNormal;
  Duration get _noteGap => _slowAudio ? _pausaLenta : _pausaNormal;
  NivelApoio get _apoioAtual => nivelDeApoio(
    nivelEtapa: _level,
    sequenciaAcertos: _sequenciaAcertosSessao,
  );
  NivelApoio get _apoioExibido =>
      _selected != null ? _apoioResposta ?? _apoioAtual : _apoioAtual;

  String get _levelInstruction => const [
    'Compare dois saltos ascendentes: uma segunda maior e uma terça maior.',
    'Diferencie segundas e terças menores e maiores e a quarta justa. O sentido pode mudar.',
    'Inclua a quinta justa e compare saltos próximos, ascendentes ou descendentes.',
    'Amplie o ouvido para sextas e sétimas sem depender da direção do som.',
    'Reconheça os doze intervalos cromáticos em qualquer direção.',
  ][_level - 1];

  String get _intervalHint => _level == 1
      ? 'Imagine o teclado e conte teclas vizinhas entre os sons. Cada tecla, branca ou preta, representa um semitom.'
      : 'Cante primeiro a nota inicial e depois a seguinte. Ignore se o som subiu ou desceu; compare apenas o tamanho do salto.';

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (!_inForeground) {
      _timer.stop();
      _audio.stopAll();
    } else if (!_loading && _selected == null && !_playing) {
      _playPair();
    }
  }

  Future<void> _initialize() async {
    try {
      final data = await _progress.buscarProgresso();
      final tipoNota = await AppPreferences.noteType();
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
      await _audio.preload(_notes.map((note) => note.$2.file));
      if (!mounted) return;
      setState(() {
        _tipoNota = tipoNota;
        _currentLevel = currentLevel;
        _nextLevel = currentLevel;
        _level = level;
        _attempts = level == currentLevel
            ? _number(data['tentativasIntervalosNivel'])
            : _number(stage['rodadaTentativas']);
        _loading = false;
      });
      _newQuestion();
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
    final candidates = _intervalsByLevel[_level - 1];
    _degree = candidates[_random.nextInt(candidates.length)];
    _ascending = _level == 1 || _random.nextBool();
    final firstNoteIndex = _random.nextInt(_notes.length - _degree);
    final low = _notes[firstNoteIndex];
    final high = _notes[firstNoteIndex + _degree];
    _firstNote = _ascending ? low : high;
    _secondNote = _ascending ? high : low;
  }

  Future<void> _playPair() async {
    if (_playing) return;
    _timer.stop();
    setState(() => _playing = true);
    try {
      for (final note in [_firstNote, _secondNote]) {
        if (!_inForeground) return;
        await _audio.playFor(
          note.$2.file,
          _noteDuration,
          pitchRatio: note.$2.pitchRatio,
        );
        await Future<void>.delayed(_noteGap);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível reproduzir os sons.')),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
      if (mounted && _selected == null && _inForeground) {
        _timer.start();
      }
    }
  }

  int _midiOf((int, MappedSample) note) => 48 + note.$1;

  String _noteName(int midi) => nomeNota(midi, _tipoNota);

  Future<void> _playKeyboardAnswer(int midi) async {
    if (_playing || _saving || _selected != null) return;
    _timer.stop();
    setState(() => _playing = true);
    try {
      final sample = SampleMap.piano(midi);
      await _audio.playFor(
        sample.file,
        const Duration(milliseconds: 620),
        pitchRatio: sample.pitchRatio,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível tocar essa nota.')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _playing = false);
    }
    if (mounted) await _answer(_intervalNames[_degree], playedMidi: midi);
  }

  Future<void> _answer(String answer, {required int playedMidi}) async {
    if (_playing || _saving || _selected != null) return;
    final apoioResposta = _apoioAtual;
    final targetMidi = _midiOf(_secondNote);
    final isCorrect = playedMidi == targetMidi;
    final durationMs = _timer.elapsed.inMilliseconds;
    final duration = (durationMs / 1000).ceil();
    _timer.stop();
    setState(() {
      _selected = answer;
      _correct = isCorrect;
      _showExplanation = !isCorrect;
      _apoioResposta = apoioResposta;
      _ultimaNotaTocada = playedMidi;
      _saving = true;
    });
    try {
      if (!isCorrect && apoioResposta == NivelApoio.iniciante) {
        await _playCorrectExample();
      }
      await _progress.registrarExercicio(
        acertou: isCorrect,
        tipo: 'Intervalo',
        pergunta: 'Ouça o intervalo e reproduza no teclado a nota de chegada.',
        resposta: 'Nota ${_noteName(playedMidi)}',
        respostaCorreta:
            '${_intervalNames[_degree]} · nota ${_noteName(_midiOf(_secondNote))}',
        dificuldade: _level,
        questaoId:
            'intervalo_${_level}_${_degree}_${_ascending ? 'asc' : 'desc'}',
        categoria: 'Percepção de intervalos',
        itemAvaliado: _intervalNames[_degree],
        duracaoSegundos: duration,
        duracaoMilissegundos: durationMs,
      );
      final data = await _progress.buscarProgresso();
      if (!mounted) return;
      final wasCurrentLevel = _level == _currentLevel;
      final currentLevel = _number(data['nivelIntervalos']).clamp(1, 5).toInt();
      final nextLevel = wasCurrentLevel ? currentLevel : _level;
      final stages = Map<String, dynamic>.from(
        data['intervaloEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final stage = Map<String, dynamic>.from(
        stages['$nextLevel'] as Map? ?? const <String, dynamic>{},
      );
      setState(() {
        _currentLevel = currentLevel;
        _nextLevel = nextLevel;
        _nextAttempts = nextLevel == currentLevel
            ? _number(data['tentativasIntervalosNivel'])
            : _number(stage['rodadaTentativas']);
        _attempts = _nextAttempts;
        _sequenciaAcertosSessao = isCorrect ? _sequenciaAcertosSessao + 1 : 0;
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _selected = null;
          _correct = null;
          _apoioResposta = null;
          _ultimaNotaTocada = null;
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

  Future<void> _nextQuestion() async {
    setState(() {
      _level = _nextLevel;
      _attempts = _nextAttempts;
      _selected = null;
      _correct = null;
      _showHint = false;
      _showExplanation = false;
      _apoioResposta = null;
      _ultimaNotaTocada = null;
      _newQuestion();
    });
    await _playPair();
  }

  Future<void> _playCorrectExample() async {
    if (!_inForeground) return;
    setState(() => _playing = true);
    try {
      final initial = SampleMap.piano(_midiOf(_firstNote));
      final target = SampleMap.piano(_midiOf(_secondNote));
      await _audio.playFor(
        initial.file,
        _noteDuration,
        pitchRatio: initial.pitchRatio,
      );
      await Future<void>.delayed(_noteGap);
      await _audio.playFor(
        target.file,
        _noteDuration,
        pitchRatio: target.pitchRatio,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível repetir a demonstração do intervalo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  String get _intervalExplanation {
    final initialMidi = _midiOf(_firstNote);
    final targetMidi = _midiOf(_secondNote);
    final apoio = _apoioResposta ?? _apoioAtual;
    if (apoio == NivelApoio.iniciante) {
      return 'Tudo bem errar: o intervalo correto é ${_intervalNames[_degree]}, e ouvir as duas notas novamente ajuda seu ouvido a reconhecê-lo.';
    }
    final explicacao =
        '${_noteName(initialMidi)} → ${_noteName(targetMidi)} percorre $_degree semiton${_degree == 1 ? '' : 's'} e forma ${_intervalNames[_degree]}. O sentido é ${_ascending ? 'ascendente' : 'descendente'}, mas o tamanho do intervalo permanece o mesmo. No teclado, conte cada tecla vizinha como um semitom.';
    if (apoio != NivelApoio.avancado || _ultimaNotaTocada == null) {
      return explicacao;
    }
    final distanciaTocada = (_ultimaNotaTocada! - initialMidi).abs();
    return 'Você tocou ${_noteName(_ultimaNotaTocada!)}: a partir de ${_noteName(initialMidi)}, seu salto foi de $distanciaTocada semiton${distanciaTocada == 1 ? '' : 's'}. A nota correta era ${_noteName(targetMidi)}, a $_degree semiton${_degree == 1 ? '' : 's'} da nota inicial. $explicacao';
  }

  @override
  Widget build(BuildContext context) {
    final respondendo = _selected == null;
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  const MelodyHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Intervalos auditivos',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nível $_level · ${nomeNivelApoio(_apoioExibido)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 16),
                        MhSegmentedProgress(total: 10, concluidos: _attempts),
                        const SizedBox(height: 8),
                        Text(
                          '$_attempts/10 respostas · ${_levelName(_level)} · 7 acertos em 10 liberam a próxima fase',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: SizedBox(
                            width: 300,
                            height: 58,
                            child: OutlinedButton.icon(
                              onPressed: _playing || _saving ? null : _playPair,
                              icon: Icon(
                                _playing
                                    ? Icons.graphic_eq_rounded
                                    : Icons.play_arrow_rounded,
                                size: 30,
                              ),
                              label: Text(
                                _playing ? 'Reproduzindo…' : 'Ouvir novamente',
                                style: const TextStyle(fontSize: 19),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton.icon(
                            onPressed: _playing || _saving
                                ? null
                                : () =>
                                      setState(() => _slowAudio = !_slowAudio),
                            icon: Icon(
                              _slowAudio
                                  ? Icons.slow_motion_video
                                  : Icons.speed,
                              size: 18,
                            ),
                            label: Text(
                              _slowAudio
                                  ? 'Escuta guiada lenta'
                                  : 'Escuta normal',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (respondendo) ...[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: MhCard(
                              key: ValueKey(
                                '$_level-$_degree-$_ascending-$_firstNote',
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.headphones_rounded,
                                    color: AppColors.secondary,
                                    size: 40,
                                  ),
                                  const MhDividerVertical(altura: 52),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _apoioAtual == NivelApoio.avancado
                                              ? 'Nota inicial: ${_noteName(_midiOf(_firstNote))}. Toque a nota de chegada.'
                                              : 'Comece em ${_noteName(_midiOf(_firstNote))}. Toque no piano a nota que ouviu por último.',
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontSize: 17,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _level == 1
                                              ? '${nomeNota(48, _tipoNota)} → ${nomeNota(50, _tipoNota)} = 2 semitons · ${nomeNota(48, _tipoNota)} → ${nomeNota(52, _tipoNota)} = 4 semitons'
                                              : _levelInstruction,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          MhCard(
                            padding: const EdgeInsets.all(8),
                            child: PianoAnswerKeyboard(
                              enabled: !_playing && !_saving,
                              selectedMidi: const <int>{},
                              tipoNota: _tipoNota,
                              onNotePressed: _playKeyboardAnswer,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: TextButton.icon(
                              onPressed: _playing || _saving
                                  ? null
                                  : () =>
                                        setState(() => _showHint = !_showHint),
                              icon: const Icon(Icons.lightbulb_outline),
                              label: Text(
                                _showHint
                                    ? 'Ocultar dica'
                                    : 'Preciso de uma dica',
                              ),
                            ),
                          ),
                          if (_showHint)
                            _learningCard(_intervalHint, Icons.lightbulb),
                        ],
                        if (_correct != null) ...[
                          const SizedBox(height: 6),
                          MhFeedbackCard(
                            acertou: _correct!,
                            titulo: _correct!
                                ? 'Isso! Intervalo reconhecido.'
                                : 'A resposta correta é ${_intervalNames[_degree]}.',
                            detalhe: _correct!
                                ? '+10 XP'
                                : 'Vamos entender por quê.',
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              onPressed: _saving || _playing
                                  ? null
                                  : () => setState(
                                      () =>
                                          _showExplanation = !_showExplanation,
                                    ),
                              icon: const Icon(Icons.school_outlined),
                              label: Text(
                                _showExplanation
                                    ? 'Ocultar explicação'
                                    : 'Ver explicação',
                              ),
                            ),
                          ),
                          if (_showExplanation)
                            _learningCard(_intervalExplanation, Icons.hearing),
                          if (_nextLevel > _level)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Fase concluída! A próxima etapa foi desbloqueada.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_saving)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: _accent,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 54,
                              child: FilledButton.icon(
                                onPressed: _nextQuestion,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text('Próximo intervalo'),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
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

  Widget _learningCard(String text, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: MhCard(
      destaque: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.text, height: 1.4),
            ),
          ),
        ],
      ),
    ),
  );

  int _number(dynamic value) => value is num ? value.toInt() : 0;
}
