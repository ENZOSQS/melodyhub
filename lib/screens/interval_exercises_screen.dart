import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/feedback_rules.dart';
import '../domain/answer_feedback_rules.dart';
import '../domain/ear_training_levels.dart';
import '../data/theory_explanations.dart';
import '../services/music_audio_service.dart';
import '../services/progress_service.dart';
import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/note_names.dart';
import '../utils/sample_map.dart';
import '../widgets/mh_ui.dart';
import '../widgets/piano_answer_keyboard.dart';
import '../widgets/theory_explanation_sheet.dart';

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
  int _tentativasQuestao = 0;
  int _comboPrimeiraTentativa = 0;
  int _estrelasRodada = 0;
  int _questoesRodada = 0;
  int? _ultimoPalpiteMidi;
  bool _respostaRevelada = false;
  final Map<int, AnswerDistance> _tentativasColoridas = {};
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
    'Escolha se a segunda nota ficou mais aguda ou mais grave. O tamanho do salto varia.',
    'Ouça saltos ascendentes de 2, 7 ou 12 semitons: 2ª maior, 5ª justa ou 8ª justa.',
    'Ouça saltos ascendentes de 2, 4, 5, 7 ou 12 semitons.',
    'Reconheça intervalos ascendentes de 1 a 12 semitons.',
    'Reconheça intervalos de 1 a 12 semitons, subindo ou descendo.',
  ][_level - 1];

  String get _intervalHint => _level == 1
      ? 'Compare o contorno do som: notas agudas são finas como apito; notas graves, encorpadas como trovão.'
      : 'Cante primeiro a nota inicial e depois a seguinte. Ignore se o som subiu ou desceu; compare apenas o tamanho do salto.';

  Set<int>? get _allowedAnswerMidis {
    if (_level < 2 || _level > 3) return null;
    final initialMidi = _midiOf(_firstNote);
    return EarTrainingLevels.intervalSemitones(_level)
        .map((semitone) => initialMidi + semitone)
        .where((midi) => midi >= 48 && midi <= 60)
        .toSet();
  }

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
    final candidates = EarTrainingLevels.intervalSemitones(_level);
    _degree = candidates[_random.nextInt(candidates.length)];
    _ascending = EarTrainingLevels.intervalCanDescend(_level)
        ? _random.nextBool()
        : _level == 1
        ? _random.nextBool()
        : true;
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
          const SnackBar(
            content: Text(
              'Não foi possível tocar o som. Confira o volume e toque em Ouvir novamente.',
            ),
          ),
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
    if (_playing || _saving || _selected != null || _level == 1) return;
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
          const SnackBar(
            content: Text(
              'Não foi possível tocar o som. Confira o volume e toque em Ouvir novamente.',
            ),
          ),
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
    final targetMidi = _midiOf(_secondNote);
    _tentativasQuestao++;
    if (playedMidi != targetMidi) {
      _comboPrimeiraTentativa = 0;
      setState(() {
        _ultimoPalpiteMidi = playedMidi;
        _tentativasColoridas[playedMidi] = AnswerFeedbackRules.distance(
          targetMidi,
          playedMidi,
        );
        _showExplanation = true;
      });
      await _compararIntervalo(playedMidi, targetMidi);
      if (_inForeground) _timer.start();
      return;
    }
    await _registrarResultado(
      answer: answer,
      response: 'Nota ${_noteName(playedMidi)}',
      solved: true,
    );
  }

  Future<void> _chooseDirection(bool selectedAscending) async {
    if (_playing || _saving || _selected != null) return;
    _tentativasQuestao++;
    if (selectedAscending != _ascending) {
      _comboPrimeiraTentativa = 0;
      setState(() {
        _ultimoPalpiteMidi = null;
        _showExplanation = true;
      });
      await _compararIntervalo(_midiOf(_firstNote), _midiOf(_secondNote));
      if (_inForeground) _timer.start();
      return;
    }
    await _registrarResultado(
      answer: selectedAscending ? 'Mais aguda' : 'Mais grave',
      response: selectedAscending ? 'Mais aguda' : 'Mais grave',
      solved: true,
    );
  }

  Future<void> _compararIntervalo(int firstMidi, int secondMidi) async {
    if (!mounted) return;
    _timer.stop();
    setState(() => _playing = true);
    try {
      for (final midi in [firstMidi, secondMidi]) {
        final sample = SampleMap.piano(midi);
        await _audio.playFor(
          sample.file,
          const Duration(milliseconds: 700),
          pitchRatio: sample.pitchRatio,
        );
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível comparar os sons. Confira o volume e toque em Ouvir novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _mostrarResposta() async {
    if (_tentativasQuestao < 3 || _selected != null || _saving) return;
    _respostaRevelada = true;
    await _registrarResultado(
      answer: 'Resposta revelada',
      response: 'Resposta revelada após $_tentativasQuestao tentativas',
      solved: false,
      revealed: true,
    );
  }

  Future<void> _registrarResultado({
    required String answer,
    required String response,
    required bool solved,
    bool revealed = false,
  }) async {
    final apoioResposta = _apoioAtual;
    final targetMidi = _midiOf(_secondNote);
    final isCountedCorrect = AnswerFeedbackRules.countsAsCorrect(
      _tentativasQuestao,
      revealed: revealed,
    );
    final stars = AnswerFeedbackRules.starsForAttempt(
      _tentativasQuestao,
      revealed: revealed,
    );
    final durationMs = _timer.elapsed.inMilliseconds;
    final duration = (durationMs / 1000).ceil();
    _timer.stop();
    setState(() {
      _selected = answer;
      _correct = solved;
      _showExplanation = !solved || _tentativasQuestao > 1;
      _apoioResposta = apoioResposta;
      _respostaRevelada = revealed;
      _saving = true;
    });
    try {
      if (revealed && apoioResposta == NivelApoio.iniciante) {
        await _playCorrectExample();
      }
      await _progress.registrarExercicio(
        acertou: isCountedCorrect,
        tipo: 'Intervalo',
        pergunta: _level == 1
            ? 'A segunda nota é mais aguda ou mais grave?'
            : 'Ouça o intervalo e reproduza no teclado a nota de chegada.',
        resposta: response,
        respostaCorreta: _level == 1
            ? (_ascending ? 'Mais aguda' : 'Mais grave')
            : '${_intervalNames[_degree]} · nota ${_noteName(targetMidi)}',
        dificuldade: _level,
        questaoId:
            'intervalo_${_level}_${_degree}_${_ascending ? 'asc' : 'desc'}',
        categoria: 'Percepção de intervalos',
        itemAvaliado: _intervalNames[_degree],
        duracaoSegundos: duration,
        duracaoMilissegundos: durationMs,
        tentativas: _tentativasQuestao,
        estrelas: stars,
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
        _sequenciaAcertosSessao = isCountedCorrect
            ? _sequenciaAcertosSessao + 1
            : 0;
        _comboPrimeiraTentativa = _tentativasQuestao == 1 && isCountedCorrect
            ? _comboPrimeiraTentativa + 1
            : 0;
        _estrelasRodada += stars;
        _questoesRodada++;
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _selected = null;
          _correct = null;
          _apoioResposta = null;
          _ultimoPalpiteMidi = null;
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
    final encerrouRodada = _questoesRodada >= 10;
    setState(() {
      _level = _nextLevel;
      _attempts = _nextAttempts;
      _selected = null;
      _correct = null;
      _tentativasQuestao = 0;
      _tentativasColoridas.clear();
      _ultimoPalpiteMidi = null;
      _respostaRevelada = false;
      _showHint = false;
      _showExplanation = false;
      _apoioResposta = null;
      _newQuestion();
      if (encerrouRodada) {
        _questoesRodada = 0;
        _estrelasRodada = 0;
      }
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
              'Não foi possível tocar a demonstração. Confira o volume e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _playBothTogether() async {
    if (_playing || _saving) return;
    setState(() => _playing = true);
    try {
      final notes = [
        SampleMap.piano(_midiOf(_firstNote)),
        SampleMap.piano(_midiOf(_secondNote)),
      ];
      final handles = await Future.wait([
        for (var i = 0; i < notes.length; i++)
          _audio.startPianoNote(notes[i].file, pitchRatio: notes[i].pitchRatio),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 850));
      await Future.wait(handles.map(_audio.stopPianoNote));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar as notas juntas. Confira o volume e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _playTheoryExample() async {
    if (_playing || _saving) return;
    setState(() => _playing = true);
    try {
      for (final midi in [48, 48 + _degree]) {
        final sample = SampleMap.piano(midi);
        await _audio.playFor(
          sample.file,
          const Duration(milliseconds: 750),
          pitchRatio: sample.pitchRatio,
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar o exemplo. Confira o volume e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _openTheory() {
    final explanation = intervalTheory[_degree]!;
    return showTheoryExplanationSheet(
      context,
      explanation: explanation,
      theory:
          '${explanation.theory} Este intervalo tem $_degree semitons. Em uma oitava, há doze semitons.',
      onPlayExample: _playTheoryExample,
      exampleLabel: 'Ouvir este intervalo a partir do Dó',
    );
  }

  String get _intervalExplanation {
    final initialMidi = _midiOf(_firstNote);
    final targetMidi = _midiOf(_secondNote);
    final apoio = _apoioResposta ?? _apoioAtual;
    final base = intervalTheory[_degree]!.theory;
    if (_level == 1) {
      final direction = _ascending ? 'mais aguda ↑' : 'mais grave ↓';
      return 'A segunda nota é $direction. ${_noteName(initialMidi)} soa primeiro, depois ${_noteName(targetMidi)}. $base';
    }
    if (_ultimoPalpiteMidi == null) {
      return '$base ${_intervalNames[_degree]} tem $_degree semitons. Toque a nota inicial destacada e conte até a nota de chegada.';
    }
    final distance = (_ultimoPalpiteMidi! - initialMidi).abs();
    final delta = distance - _degree;
    final extra = delta == 0
        ? 'Você chegou à nota certa.'
        : 'Seu salto teve ${delta.abs()} semitom${delta.abs() == 1 ? '' : 's'} ${delta > 0 ? 'a mais' : 'a menos'} que a resposta.';
    final apoioText = apoio == NivelApoio.iniciante
        ? 'Tudo bem errar: compare os dois sons e tente mais uma vez.'
        : 'Você tocou ${_noteName(_ultimoPalpiteMidi!)} ($distance semitons a partir de ${_noteName(initialMidi)}). $extra';
    return '$apoioText A resposta forma ${_intervalNames[_degree]}: $_degree semitons. $base';
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
                        Text(
                          '🔥 $_comboPrimeiraTentativa seguidas na primeira tentativa',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                        if (_questoesRodada >= 10)
                          _learningCard(
                            'Rodada concluída: $_estrelasRodada de 30 estrelas. ${_estrelasRodada >= 24
                                ? 'Excelente ouvido!'
                                : _estrelasRodada >= 15
                                ? 'Bom progresso: continue praticando.'
                                : 'Cada tentativa ensina. Tente outra rodada!'}',
                            Icons.emoji_events,
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
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _playing || _saving
                                ? null
                                : _playBothTogether,
                            icon: const Icon(Icons.graphic_eq_rounded),
                            label: const Text('Ouvir as duas notas juntas'),
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
                                          _level == 1
                                              ? 'A segunda nota é mais aguda ou mais grave?'
                                              : _apoioAtual ==
                                                    NivelApoio.avancado
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
                                              ? 'Ouça o contorno: subiu ou desceu?'
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
                          if (_level == 1)
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 68,
                                    child: FilledButton.icon(
                                      onPressed: _playing || _saving
                                          ? null
                                          : () => _chooseDirection(true),
                                      icon: const Icon(
                                        Icons.arrow_upward_rounded,
                                      ),
                                      label: const Text('Mais aguda'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 68,
                                    child: FilledButton.icon(
                                      onPressed: _playing || _saving
                                          ? null
                                          : () => _chooseDirection(false),
                                      icon: const Icon(
                                        Icons.arrow_downward_rounded,
                                      ),
                                      label: const Text('Mais grave'),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            MhCard(
                              padding: const EdgeInsets.all(8),
                              child: PianoAnswerKeyboard(
                                enabled: !_playing && !_saving,
                                selectedMidi: {_midiOf(_firstNote)},
                                enabledMidis: _allowedAnswerMidis,
                                feedbackColors: {
                                  for (final entry
                                      in _tentativasColoridas.entries)
                                    entry.key:
                                        entry.value == AnswerDistance.close
                                        ? const Color(0xFFF0C84B)
                                        : const Color(0xFFB9474F),
                                  if (_correct == true ||
                                      (_tentativasQuestao > 0 && _level > 1))
                                    _midiOf(_secondNote): Colors.green,
                                },
                                tipoNota: _tipoNota,
                                onNotePressed: _playKeyboardAnswer,
                              ),
                            ),
                          const SizedBox(height: 6),
                          if (_tentativasQuestao > 0 && _selected == null) ...[
                            Text(
                              _level == 1
                                  ? (_ascending
                                        ? 'A resposta aponta para cima ↑'
                                        : 'A resposta aponta para baixo ↓')
                                  : _ultimoPalpiteMidi == null
                                  ? 'Compare seu som com a nota inicial destacada.'
                                  : 'Você tocou ${_noteName(_ultimoPalpiteMidi!)}; ouça a diferença.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            if (_showExplanation)
                              _learningCard(
                                _intervalExplanation,
                                Icons.hearing,
                              ),
                          ],
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: _playing || _saving
                                      ? null
                                      : () => setState(
                                          () => _showHint = !_showHint,
                                        ),
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: Text(
                                    _showHint
                                        ? 'Ocultar dica'
                                        : 'Preciso de uma dica',
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _openTheory,
                                  icon: const Icon(Icons.menu_book),
                                  label: const Text('Entenda a teoria'),
                                ),
                              ],
                            ),
                          ),
                          if (_showHint)
                            _learningCard(_intervalHint, Icons.lightbulb),
                          if (_tentativasQuestao >= 3 && _selected == null)
                            Center(
                              child: TextButton.icon(
                                onPressed: _mostrarResposta,
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Mostrar resposta'),
                              ),
                            ),
                        ],
                        if (_correct != null) ...[
                          const SizedBox(height: 6),
                          MhFeedbackCard(
                            acertou: _correct!,
                            titulo: _correct!
                                ? 'Isso! Intervalo reconhecido.'
                                : 'Resposta revelada: ${_intervalNames[_degree]}.',
                            detalhe:
                                '${'★' * AnswerFeedbackRules.starsForAttempt(_tentativasQuestao, revealed: _respostaRevelada)} · $_tentativasQuestao tentativa(s)${AnswerFeedbackRules.countsAsCorrect(_tentativasQuestao, revealed: _respostaRevelada) ? ' · +10 XP' : ''}',
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
                          OutlinedButton.icon(
                            onPressed: _openTheory,
                            icon: const Icon(Icons.menu_book),
                            label: const Text('Entenda a teoria'),
                          ),
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
