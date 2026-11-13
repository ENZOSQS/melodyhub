import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/feedback_rules.dart';
import '../domain/answer_feedback_rules.dart';
import '../domain/ear_training_levels.dart';
import '../data/theory_explanations.dart';
import '../services/note_player.dart';
import '../services/progress_service.dart';
import '../services/app_preferences.dart';
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
  static const Color _verde = Color(0xFFE9B96E);
  static const Color _preto = Color(0xFF171316);
  static const _semitones = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  List<Map<String, dynamic>> get _notas => _semitones.map((semitone) {
    final midi = 48 + semitone;
    return <String, dynamic>{
      'nome': nomeNota(semitone, _tipoNota),
      'midi': midi,
    };
  }).toList();
  List<Map<String, dynamic>> get _notasPermitidas => _notas
      .where(
        (nota) => EarTrainingLevels.practiceNotes(
          _nivel,
        ).contains((nota['midi'] as int) % 12),
      )
      .toList();

  final NotePlayer _notePlayer = NotePlayer.instance;
  final ProgressService _progressService = ProgressService();
  final Random _random = Random();
  final Stopwatch _tempoQuestao = Stopwatch();

  int _nivel = 1;
  int _nivelAtual = 1;
  int _sequenciaAcertos = 0;
  int _sequenciaAcertosSessao = 0;
  int _tentativasNoNivel = 0;
  int _acertosNoNivel = 0;
  int _proximoNivel = 1;
  int _tentativasProximoNivel = 0;
  int _acertosProximoNivel = 0;
  int _sequenciaProxima = 0;
  bool _carregando = true;
  bool _respondendo = false;
  bool _reproduzindo = false;
  bool _emForeground = true;
  bool _mostrarFeedback = false;
  bool _mostrarDica = false;
  bool _mostrarExplicacao = false;
  bool _audioLento = false;
  bool? _acertou;
  NivelApoio? _apoioResposta;
  String? _erroInicializacao;
  String _tipoNota = 'solfejo';
  List<Map<String, dynamic>> _alvo = [];
  List<String> _respostas = [];
  final Map<String, AnswerDistance> _tentativasColoridas = {};
  int _tentativasQuestao = 0;
  int _errosQuestao = 0;
  int _tentativasPosicao = 0;
  int _maiorTentativaPosicao = 1;
  int _comboPrimeiraTentativa = 0;
  int _estrelasRodada = 0;
  int _questoesRodada = 0;
  int? _ultimaNotaTocada;
  String? _ultimoPalpite;
  bool _respostaRevelada = false;

  Duration get _duracaoNota =>
      Duration(milliseconds: (_nivel <= 2 ? 900 : 300) * (_audioLento ? 2 : 1));
  Duration get _pausaEntreNotas =>
      Duration(milliseconds: (_nivel <= 2 ? 400 : 55) * (_audioLento ? 2 : 1));
  NivelApoio get _apoioAtual => nivelDeApoio(
    nivelEtapa: _nivel,
    sequenciaAcertos: _sequenciaAcertosSessao,
  );
  NivelApoio get _apoioExibido =>
      _mostrarFeedback ? _apoioResposta ?? _apoioAtual : _apoioAtual;

  int get _tamanhoSequencia => EarTrainingLevels.practiceSequenceLength(_nivel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _emForeground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _inicializar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tempoQuestao.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _emForeground = state == AppLifecycleState.resumed;
    if (_emForeground) {
      if (!_carregando &&
          !_respondendo &&
          !_reproduzindo &&
          !_mostrarFeedback) {
        _tempoQuestao.start();
      }
    } else {
      _tempoQuestao.stop();
      _notePlayer.stopAll();
    }
  }

  Future<void> _inicializar() async {
    try {
      final progresso = await _progressService.buscarProgresso();
      final tipoNota = await AppPreferences.noteType();
      if (!mounted) return;
      final nivelAtual = _numero(progresso['nivelPratico']).clamp(1, 5).toInt();
      final etapas = Map<String, dynamic>.from(
        progresso['praticaEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final etapa = Map<String, dynamic>.from(
        etapas['${widget.nivelSelecionado ?? nivelAtual}'] as Map? ??
            const <String, dynamic>{},
      );
      await _notePlayer.initialize();
      if (!mounted) return;
      setState(() {
        _tipoNota = tipoNota;
        _nivelAtual = nivelAtual;
        _proximoNivel = nivelAtual;
        _nivel = (widget.nivelSelecionado ?? nivelAtual)
            .clamp(1, nivelAtual)
            .toInt();
        _sequenciaAcertos = _nivel == nivelAtual
            ? _numero(progresso['sequenciaAcertosPraticos'])
            : 0;
        _tentativasNoNivel = _nivel == nivelAtual
            ? _numero(progresso['tentativasPraticasNivel'])
            : _numero(etapa['rodadaTentativas']);
        _acertosNoNivel = _nivel == nivelAtual
            ? _numero(progresso['acertosPraticasNivel'])
            : _numero(etapa['rodadaAcertos']);
        _alvo = _sortearSequencia();
        _carregando = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _tocarSequencia());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erroInicializacao =
            'Não foi possível carregar seu nível. Confira sua conexão e tente novamente.';
        _carregando = false;
      });
    }
  }

  List<Map<String, dynamic>> _sortearSequencia() {
    final resultado = <Map<String, dynamic>>[];
    final disponiveis = _notasPermitidas;
    while (resultado.length < _tamanhoSequencia) {
      final nota = disponiveis[_random.nextInt(disponiveis.length)];
      if (resultado.isEmpty || resultado.last['nome'] != nota['nome']) {
        resultado.add(nota);
      }
    }
    return resultado;
  }

  Future<void> _tocarSequencia() async {
    if (!mounted || _respondendo || _reproduzindo || _alvo.isEmpty) return;
    _tempoQuestao.stop();
    setState(() => _reproduzindo = true);
    try {
      await _notePlayer.playNote(48, durationMs: _duracaoNota.inMilliseconds);
      await Future<void>.delayed(_pausaEntreNotas);
      for (final nota in _alvo) {
        if (!mounted || !_emForeground) break;
        await _notePlayer.playNote(
          nota['midi'] as int,
          durationMs: _duracaoNota.inMilliseconds,
        );
        await Future<void>.delayed(_pausaEntreNotas);
      }
    } catch (erro) {
      debugPrint('Erro ao reproduzir sequência: $erro');
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
      if (mounted) {
        setState(() => _reproduzindo = false);
        if (_emForeground && !_mostrarFeedback && !_respondendo) {
          _tempoQuestao.start();
        }
      }
    }
  }

  Future<void> _ouvirDo() async {
    if (_reproduzindo || _respondendo) return;
    setState(() => _reproduzindo = true);
    try {
      await _notePlayer.playNote(48, durationMs: 900);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar o Dó. Confira o volume e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reproduzindo = false);
    }
  }

  Future<void> _ouvirEscala() async {
    if (_reproduzindo || _respondendo) return;
    setState(() => _reproduzindo = true);
    try {
      for (final semitone in const [0, 2, 4, 5, 7, 9, 11]) {
        await _notePlayer.playNote(48 + semitone, durationMs: 500);
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar a escala. Confira o volume e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reproduzindo = false);
    }
  }

  Future<void> _abrirTeoria() => showTheoryExplanationSheet(
    context,
    explanation: practiceNoteTheory,
    theory: practiceNoteTheory.theory,
    onPlayExample: _ouvirEscala,
    exampleLabel: 'Ouvir a escala Dó–Ré–Mi–Fá–Sol–Lá–Si',
  );

  String get _feedbackProximidade {
    if (_ultimaNotaTocada == null || _respostas.length >= _alvo.length) {
      return '';
    }
    final alvo = _alvo[_respostas.length]['midi'] as int;
    final direction = AnswerFeedbackRules.direction(alvo, _ultimaNotaTocada!);
    final arrow = direction == NoteDirection.higher ? '↑' : '↓';
    final side = direction == NoteDirection.higher
        ? 'direita (mais aguda)'
        : 'esquerda (mais grave)';
    final distance = AnswerFeedbackRules.distance(alvo, _ultimaNotaTocada!);
    return distance == AnswerDistance.close
        ? 'Quase! A nota certa é um pouco mais ${direction == NoteDirection.higher ? 'aguda' : 'grave'} $arrow'
        : 'Longe. Tente mais para a $side $arrow';
  }

  void _receberNota(String resposta) {
    if (_respondendo || _reproduzindo || _carregando || _mostrarFeedback) {
      return;
    }
    final indice = _respostas.length;
    if (indice >= _alvo.length) return;
    final tocada = _notas.firstWhere((nota) => nota['nome'] == resposta);
    final alvo = _alvo[indice];
    final midiTocada = tocada['midi'] as int;
    final midiAlvo = alvo['midi'] as int;
    _tentativasQuestao++;
    _tentativasPosicao++;
    if (resposta != alvo['nome']) {
      _errosQuestao++;
      _comboPrimeiraTentativa = 0;
      setState(() {
        _ultimoPalpite = resposta;
        _ultimaNotaTocada = midiTocada;
        _tentativasColoridas[resposta] = AnswerFeedbackRules.distance(
          midiAlvo,
          midiTocada,
        );
      });
      unawaited(_compararNotas(midiTocada, midiAlvo));
      return;
    }
    setState(() {
      _respostas = [..._respostas, resposta];
      _ultimoPalpite = null;
      _ultimaNotaTocada = midiTocada;
    });
    _maiorTentativaPosicao = max(_maiorTentativaPosicao, _tentativasPosicao);
    _tentativasPosicao = 0;
    if (_respostas.length == _alvo.length) _registrarSequencia(correta: true);
  }

  Future<void> _compararNotas(int tocada, int alvo) async {
    if (!mounted) return;
    setState(() => _reproduzindo = true);
    try {
      for (final midi in [tocada, alvo]) {
        await _notePlayer.playNote(midi, durationMs: 620);
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
      if (mounted) setState(() => _reproduzindo = false);
    }
  }

  Future<void> _mostrarResposta() async {
    if (_errosQuestao < 3 || _respondendo || _mostrarFeedback) return;
    _maiorTentativaPosicao = max(_maiorTentativaPosicao, _tentativasPosicao);
    setState(() {
      _respostaRevelada = true;
      _respostas = _alvo.map((nota) => nota['nome'] as String).toList();
    });
    await _registrarSequencia(correta: false, revelada: true);
  }

  Future<void> _registrarSequencia({
    required bool correta,
    bool revelada = false,
  }) async {
    final apoioResposta = _apoioAtual;
    final contaComoAcerto = AnswerFeedbackRules.countsAsCorrect(
      _maiorTentativaPosicao,
      revealed: revelada,
    );
    final estrelas = AnswerFeedbackRules.starsForAttempt(
      _maiorTentativaPosicao,
      revealed: revelada,
    );
    _tempoQuestao.stop();
    final duracaoMs = _tempoQuestao.elapsed.inMilliseconds;
    final duracao = (duracaoMs / 1000).ceil();
    final respostaCorreta = _alvo.map((nota) => nota['nome']).join(' – ');
    final respostaUsuario = _respostas.join(' – ');
    setState(() {
      _respondendo = true;
      _mostrarFeedback = true;
      _acertou = correta;
      _mostrarExplicacao = !correta;
      _apoioResposta = apoioResposta;
      _respostaRevelada = revelada;
    });
    try {
      if (revelada && apoioResposta == NivelApoio.iniciante) {
        await _tocarSequenciaCorreta();
      }
      await _progressService.registrarExercicio(
        acertou: contaComoAcerto,
        tipo: 'Prático',
        pergunta: _tamanhoSequencia == 1
            ? 'Identifique a nota ouvida.'
            : 'Repita a sequência de $_tamanhoSequencia notas.',
        resposta: respostaUsuario,
        respostaCorreta: respostaCorreta,
        dificuldade: _nivel,
        questaoId: 'sequencia_notas_nivel_$_nivel',
        categoria: 'Memória auditiva',
        itemAvaliado: _tamanhoSequencia == 1
            ? _alvo.first['nome'] as String
            : null,
        duracaoSegundos: duracao,
        duracaoMilissegundos: duracaoMs,
        tentativas: _tentativasQuestao,
        estrelas: estrelas,
      );
      final progresso = await _progressService.buscarProgresso();
      if (!mounted) return;
      final estavaNaEtapaAtual = _nivel == _nivelAtual;
      final nivelAtual = _numero(progresso['nivelPratico']).clamp(1, 5).toInt();
      final nivelSeguinte = estavaNaEtapaAtual ? nivelAtual : _nivel;
      final etapas = Map<String, dynamic>.from(
        progresso['praticaEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final etapaSeguinte = Map<String, dynamic>.from(
        etapas['$nivelSeguinte'] as Map? ?? const <String, dynamic>{},
      );
      final tentativasSeguintes = nivelSeguinte == nivelAtual
          ? _numero(progresso['tentativasPraticasNivel'])
          : _numero(etapaSeguinte['rodadaTentativas']);
      final acertosSeguintes = nivelSeguinte == nivelAtual
          ? _numero(progresso['acertosPraticasNivel'])
          : _numero(etapaSeguinte['rodadaAcertos']);
      setState(() {
        _nivelAtual = nivelAtual;
        _proximoNivel = nivelSeguinte;
        _tentativasProximoNivel = tentativasSeguintes;
        _acertosProximoNivel = acertosSeguintes;
        _sequenciaAcertos = estavaNaEtapaAtual
            ? _numero(progresso['sequenciaAcertosPraticos'])
            : 0;
        _sequenciaProxima = _sequenciaAcertos;
        _sequenciaAcertosSessao = contaComoAcerto
            ? _sequenciaAcertosSessao + 1
            : 0;
        _comboPrimeiraTentativa = _maiorTentativaPosicao == 1 && contaComoAcerto
            ? _comboPrimeiraTentativa + 1
            : 0;
        _estrelasRodada += estrelas;
        _questoesRodada++;
        _respondendo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _respondendo = false;
        _mostrarFeedback = false;
        _mostrarDica = false;
        _mostrarExplicacao = false;
        _acertou = null;
        _apoioResposta = null;
        _respostas = [];
        _tentativasQuestao = 0;
        _errosQuestao = 0;
        _tentativasPosicao = 0;
        _maiorTentativaPosicao = 1;
        _tentativasColoridas.clear();
        _ultimoPalpite = null;
        _ultimaNotaTocada = null;
        _tempoQuestao
          ..reset()
          ..start();
        if (!_emForeground) _tempoQuestao.stop();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar seu exercício. Confira sua conexão e tente novamente.',
          ),
        ),
      );
    }
  }

  Future<void> _tocarSequenciaCorreta() async {
    if (!_emForeground || _alvo.isEmpty) return;
    setState(() => _reproduzindo = true);
    try {
      for (final nota in _alvo) {
        if (!mounted || !_emForeground) break;
        await _notePlayer.playNote(
          nota['midi'] as int,
          durationMs: _duracaoNota.inMilliseconds,
        );
        await Future<void>.delayed(_pausaEntreNotas);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível tocar a sequência. Confira o volume e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reproduzindo = false);
    }
  }

  Future<void> _avancarSequencia() async {
    final encerrouRodada = _questoesRodada >= 10;
    setState(() {
      _nivel = _proximoNivel;
      _tentativasNoNivel = _tentativasProximoNivel;
      _acertosNoNivel = _acertosProximoNivel;
      _sequenciaAcertos = _sequenciaProxima;
      _alvo = _sortearSequencia();
      _respostas = [];
      _tentativasQuestao = 0;
      _errosQuestao = 0;
      _tentativasPosicao = 0;
      _maiorTentativaPosicao = 1;
      _tentativasColoridas.clear();
      _ultimoPalpite = null;
      _ultimaNotaTocada = null;
      _respostaRevelada = false;
      if (encerrouRodada) {
        _questoesRodada = 0;
        _estrelasRodada = 0;
      }
      _mostrarFeedback = false;
      _mostrarDica = false;
      _mostrarExplicacao = false;
      _apoioResposta = null;
      _acertou = null;
      _respondendo = false;
      _tempoQuestao
        ..reset()
        ..start();
      if (!_emForeground) _tempoQuestao.stop();
    });
    await Future<void>.delayed(_pausaEntreNotas);
    if (mounted && _emForeground) await _tocarSequencia();
  }

  String get _explicacaoSequencia {
    final correta = _alvo.map((nota) => nota['nome']).join(' → ');
    final apoio = _apoioResposta ?? _apoioAtual;
    if (_acertou == false && apoio == NivelApoio.iniciante) {
      return 'Tudo bem errar: ouça a sequência correta mais uma vez e tente cantá-la antes de tocar.';
    }
    if (_acertou == true) {
      if (_tamanhoSequencia == 1) {
        return 'Você identificou a nota ${_alvo.first['nome']}. Cante junto com o som para fixar essa referência.';
      }
      return 'Você manteve a ordem das notas: $correta. Agrupar a sequência em pequenos blocos ajuda a memória auditiva.';
    }
    var primeiraDiferenca = -1;
    for (var i = 0; i < _respostas.length && i < _alvo.length; i++) {
      if (_respostas[i] != _alvo[i]['nome']) {
        primeiraDiferenca = i;
        break;
      }
    }
    if (primeiraDiferenca >= 0) {
      if (apoio == NivelApoio.avancado) {
        return 'Na ${primeiraDiferenca + 1}ª nota, você tocou ${_respostas[primeiraDiferenca]}, mas era ${_alvo[primeiraDiferenca]['nome']}. A sequência completa era $correta.';
      }
      return 'Na posição ${primeiraDiferenca + 1}, você tocou ${_respostas[primeiraDiferenca]}, mas o som era ${_alvo[primeiraDiferenca]['nome']}. A sequência completa era $correta. Tente cantar cada nota antes de repeti-la.';
    }
    if (_tamanhoSequencia == 1) {
      return 'A nota tocada foi ${_alvo.first['nome']}. Compare a altura do som com as teclas do piano e cante junto para fixar a referência.';
    }
    return 'A sequência completa era $correta. Tente cantá-la em blocos de duas ou três notas antes de tocar.';
  }

  Color _corTecla(String nome) {
    if (_mostrarFeedback &&
        _acertou == true &&
        _alvo.any((nota) => nota['nome'] == nome)) {
      return Colors.green;
    }
    final distance = _tentativasColoridas[nome];
    if (distance == AnswerDistance.close) return const Color(0xFFF0C84B);
    if (distance == AnswerDistance.far) return const Color(0xFFB9474F);
    if (nome == nomeNota(0, _tipoNota)) return _verde;
    if (_respostas.contains(nome) && !_mostrarFeedback) {
      return _verde.withValues(alpha: 0.8);
    }
    return Colors.white;
  }

  Color _corTextoTecla(String nome) {
    final cor = _corTecla(nome);
    return cor == Colors.white ? _preto : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _preto,
      appBar: AppBar(
        backgroundColor: _preto,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Exercício Prático',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: _verde))
          : _erroInicializacao != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _erroInicializacao!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _carregando = true;
                          _erroInicializacao = null;
                        });
                        _inicializar();
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                child: Column(
                  children: [
                    _buildCabecalho(),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.97, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(
                          '${_alvo.map((nota) => nota['nome']).join('|')}-${_respostas.join('|')}',
                        ),
                        child: _buildRespostas(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPiano(),
                    const SizedBox(height: 12),
                    _buildFeedback(),
                  ],
                ),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              key: ValueKey(_reproduzindo),
              _reproduzindo ? Icons.graphic_eq_rounded : Icons.hearing_rounded,
              color: _preto,
              size: 34,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Sequência auditiva — nível $_nivel · ${nomeNivelApoio(_apoioExibido)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _preto,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _tamanhoSequencia == 1
                ? 'Esta é a nota Dó. Compare a nota ouvida com esta referência.'
                : 'Esta é a nota Dó. Ouça a sequência de $_tamanhoSequencia notas e repita na mesma ordem.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (_nivel < 5) ...[
            const SizedBox(height: 6),
            Text(
              '$_tentativasNoNivel/10 tentativas · $_acertosNoNivel acertos · mínimo de 7 para avançar',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF70502E),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Nível máximo · pratique para manter sua sequência de acertos',
              style: const TextStyle(
                color: Color(0xFF70502E),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: _respondendo || _reproduzindo ? null : _tocarSequencia,
              icon: const Icon(Icons.volume_up, size: 19),
              label: Text(
                _reproduzindo ? 'Reproduzindo…' : 'Ouvir sequência novamente',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _preto,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _reproduzindo || _respondendo ? null : _ouvirDo,
            icon: const Icon(Icons.music_note, size: 17),
            label: const Text('Ouvir o Dó de novo'),
          ),
          Text(
            '🔥 $_comboPrimeiraTentativa seguidas na primeira tentativa',
            style: const TextStyle(
              color: Color(0xFF70502E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ActionChip(
            avatar: Icon(
              _audioLento ? Icons.slow_motion_video : Icons.speed,
              size: 18,
            ),
            label: Text(_audioLento ? 'Áudio mais lento' : 'Áudio normal'),
            onPressed: _reproduzindo || _respondendo
                ? null
                : () => setState(() => _audioLento = !_audioLento),
          ),
          if (_tentativasNoNivel > 0 && _nivel < 5) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _tentativasNoNivel / 10,
                minHeight: 6,
                backgroundColor: Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF70502E),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRespostas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            'Sua sequência',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            children: List.generate(_tamanhoSequencia, (index) {
              final preenchida = index < _respostas.length;
              return CircleAvatar(
                radius: 16,
                backgroundColor: preenchida ? Colors.green : Colors.white12,
                child: Text(
                  preenchida ? _respostas[index] : '${index + 1}',
                  style: TextStyle(
                    color: preenchida ? _preto : Colors.white54,
                    fontSize: preenchida ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
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
        color: const Color(0xFF100D10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: AspectRatio(
        aspectRatio: 7 / 3.2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _notas.map((nota) {
            final nome = nota['nome'] as String;
            final habilitada = _notasPermitidas.any(
              (item) => item['nome'] == nome,
            );
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap:
                      !habilitada ||
                          _respondendo ||
                          _reproduzindo ||
                          _mostrarFeedback
                      ? null
                      : () => _receberNota(nome),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: habilitada ? 1 : .28,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: _corTecla(nome) == Colors.green ? 1.04 : 1,
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
      return Column(
        children: [
          if (_ultimoPalpite != null && _ultimaNotaTocada != null) ...[
            Text(
              'Você tocou $_ultimoPalpite; ouça a diferença.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              _feedbackProximidade,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: _reproduzindo || _respondendo
                ? null
                : () => setState(() => _mostrarDica = !_mostrarDica),
            icon: const Icon(Icons.lightbulb_outline, color: _verde),
            label: Text(
              _mostrarDica ? 'Ocultar dica' : 'Preciso de uma dica',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (_mostrarDica)
            _cartaoAprendizado(
              _tamanhoSequencia == 1
                  ? 'Cante a nota e compare se ela é mais grave ou mais aguda que as notas que você já conhece. Você pode ouvir novamente.'
                  : 'Cante a sequência em voz baixa e agrupe as notas em blocos de duas ou três. Você pode ouvir novamente antes de responder.',
              Icons.lightbulb,
            ),
          OutlinedButton.icon(
            onPressed: _abrirTeoria,
            icon: const Icon(Icons.menu_book, color: _verde),
            label: const Text('Entenda a teoria'),
          ),
          if (_errosQuestao >= 3)
            TextButton.icon(
              onPressed: _mostrarResposta,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Mostrar resposta'),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _acertou! ? Colors.green : const Color(0xFF9E3A48),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _acertou! ? Icons.check_circle : Icons.menu_book,
                color: Colors.white,
                size: 23,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _acertou!
                      ? 'Sequência resolvida! ${'★' * AnswerFeedbackRules.starsForAttempt(_maiorTentativaPosicao, revealed: _respostaRevelada)} · $_tentativasQuestao tentativa(s)'
                      : 'Resposta revelada. Sem estrelas desta vez.',
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
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _reproduzindo || _respondendo
              ? null
              : () => setState(() => _mostrarExplicacao = !_mostrarExplicacao),
          icon: const Icon(Icons.school_outlined, color: _verde),
          label: Text(
            _mostrarExplicacao ? 'Ocultar explicação' : 'Ver explicação',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        if (_mostrarExplicacao)
          _cartaoAprendizado(_explicacaoSequencia, Icons.hearing),
        OutlinedButton.icon(
          onPressed: _abrirTeoria,
          icon: const Icon(Icons.menu_book, color: _verde),
          label: const Text('Entenda a teoria'),
        ),
        if (_questoesRodada >= 10)
          _cartaoAprendizado(
            'Rodada concluída: $_estrelasRodada de 30 estrelas. ${_estrelasRodada >= 24
                ? 'Excelente ouvido!'
                : _estrelasRodada >= 15
                ? 'Bom progresso: continue praticando.'
                : 'Cada tentativa ensina. Tente outra rodada!'}',
            Icons.emoji_events,
          ),
        if (_proximoNivel > _nivel)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Fase concluída! A próxima etapa foi desbloqueada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _verde, fontWeight: FontWeight.bold),
            ),
          ),
        if (_respondendo)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: _verde),
            ),
          )
        else
          FilledButton.icon(
            onPressed: _avancarSequencia,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Próxima sequência'),
          ),
      ],
    );
  }

  Widget _cartaoAprendizado(String texto, IconData icone) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: const Color(0xFF70502E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: _preto, height: 1.35),
          ),
        ),
      ],
    ),
  );

  int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;
}
