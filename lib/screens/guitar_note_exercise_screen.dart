import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../services/music_audio_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../utils/guitar_sample_map.dart';
import '../utils/note_names.dart';
import '../utils/orientacao.dart';
import '../widgets/guitar_fretboard.dart';
import '../widgets/mh_ui.dart';

class GuitarNoteExerciseScreen extends StatefulWidget {
  const GuitarNoteExerciseScreen({super.key});

  @override
  State<GuitarNoteExerciseScreen> createState() =>
      _GuitarNoteExerciseScreenState();
}

class _GuitarNoteExerciseScreenState extends State<GuitarNoteExerciseScreen> {
  static const _cordas = ['Mi aguda', 'Si', 'Sol', 'Ré', 'Lá', 'Mi grave'];

  final _audio = MusicAudioService.instance;
  final _progresso = ProgressService();
  final _random = Random();
  final _cronometro = Stopwatch();

  bool _carregando = true;
  bool _tocando = false;
  bool _salvando = false;
  bool _mostrarDica = false;
  bool? _acertou;
  bool _mostrarNomes = true;
  String _tipoNota = 'solfejo';
  (int, int, int)? _alvo;
  (int, int)? _posicaoSelecionada;
  (int, int, int)? _selecionada;

  @override
  void initState() {
    super.initState();
    usarPaisagem();
    _inicializar();
  }

  @override
  void dispose() {
    _cronometro.stop();
    voltarRetrato();
    super.dispose();
  }

  Future<void> _inicializar() async {
    try {
      _tipoNota = await AppPreferences.noteType();
      // Todo o braço pode ser tocado para comparar, então todos os samples
      // são carregados antes da primeira questão.
      await _audio.preload(GuitarSampleMap.fretboardAssets);
      if (!mounted) return;
      setState(() => _carregando = false);
      await _novaQuestao();
    } catch (erro) {
      if (!mounted) return;
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar o exercício de violão.'),
        ),
      );
      debugPrint('Falha ao iniciar o exercício de violão: $erro');
    }
  }

  Future<void> _novaQuestao() async {
    final opcoes = <(int, int, int)>[];
    for (var corda = 0; corda < 6; corda++) {
      for (var casa = 0; casa <= 5; casa++) {
        opcoes.add((corda, casa, GuitarSampleMap.openMidiNotes[corda] + casa));
      }
    }
    _alvo = opcoes[_random.nextInt(opcoes.length)];
    _posicaoSelecionada = null;
    _selecionada = null;
    _mostrarDica = false;
    _acertou = null;
    _cronometro
      ..reset()
      ..start();
    await _repetirNota();
  }

  Future<void> _repetirNota() async {
    final alvo = _alvo;
    if (alvo == null || _tocando || _salvando) return;
    _cronometro.stop();
    setState(() => _tocando = true);
    try {
      final sample = GuitarSampleMap.forPosition(alvo.$1, alvo.$2);
      await _audio.playFor(
        sample.file,
        const Duration(milliseconds: 1600),
        pitchRatio: sample.pitchRatio,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível reproduzir a nota.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _tocando = false);
        if (_acertou == null && !_salvando) _cronometro.start();
      }
    }
  }

  /// Tocar no braço só seleciona e reproduz a posição. A resposta é enviada
  /// em [_confirmar], para que o aluno possa comparar sons e rolar o braço
  /// sem que o primeiro toque seja tratado como resposta.
  Future<void> _selecionar(int corda, int casa, int midi) async {
    if (_alvo == null || _tocando || _salvando || _acertou != null) return;
    setState(() {
      _selecionada = (corda, casa, midi);
      _posicaoSelecionada = (corda, casa);
    });
    try {
      final sample = GuitarSampleMap.forPosition(corda, casa);
      await _audio.playFor(
        sample.file,
        const Duration(milliseconds: 900),
        pitchRatio: sample.pitchRatio,
      );
    } catch (_) {
      // A seleção continua válida mesmo se o som falhar.
    }
  }

  Future<void> _confirmar() async {
    final selecionada = _selecionada;
    if (selecionada == null) return;
    await _responder(selecionada.$1, selecionada.$2, selecionada.$3);
  }

  Future<void> _responder(int corda, int casa, int midi) async {
    final alvo = _alvo;
    if (alvo == null || _tocando || _salvando || _acertou != null) return;
    // Para iniciantes vale o nome da nota em qualquer oitava.
    final acertou = midi % 12 == alvo.$3 % 12;
    final duracaoMs = _cronometro.elapsed.inMilliseconds;
    _cronometro.stop();
    setState(() {
      _salvando = true;
      _posicaoSelecionada = (corda, casa);
    });
    try {
      await _progresso.registrarExercicio(
        acertou: acertou,
        tipo: 'Violão',
        categoria: 'Violão: identificar notas',
        pergunta: 'Ouça a nota e encontre no braço do violão.',
        resposta:
            '${_cordas[corda]}, casa $casa · ${nomeNota(midi, _tipoNota)}',
        respostaCorreta:
            '${nomeNota(alvo.$3, _tipoNota)} · ${_cordas[alvo.$1]}, casa ${alvo.$2}',
        dificuldade: 1,
        questaoId: 'violao_nota_${alvo.$3}',
        itemAvaliado: nomeNota(alvo.$3, 'solfejo'),
        duracaoSegundos: (duracaoMs / 1000).ceil(),
        duracaoMilissegundos: duracaoMs,
      );
      if (mounted) setState(() => _acertou = acertou);
    } catch (_) {
      if (mounted) {
        setState(() {
          _posicaoSelecionada = null;
          _selecionada = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a resposta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alvo = _alvo;
    final respondido = _acertou != null;
    final podeConfirmar =
        _selecionada != null && !respondido && !_salvando && !_tocando;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.text,
                            size: 28,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Encontre a nota no violão',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Toque para ouvir e confirme a posição.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: _mostrarNomes
                              ? 'Ocultar nomes das notas'
                              : 'Mostrar nomes das notas',
                          onPressed: () =>
                              setState(() => _mostrarNomes = !_mostrarNomes),
                          icon: Icon(
                            _mostrarNomes
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GuitarFretboard(
                      onPositionPressed: _selecionar,
                      showNoteNames: _mostrarNomes,
                      tipoNota: _tipoNota,
                      activePosition: _posicaoSelecionada,
                    ),
                  ),
                  if (_mostrarDica && alvo != null && !respondido)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Dica: corda ${_cordas[alvo.$1]}, casa ${alvo.$2}.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (respondido && alvo != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        _acertou!
                            ? 'Correto! Essa posição produz ${nomeNota(alvo.$3, _tipoNota)}${_selecionada != null && _selecionada!.$3 != alvo.$3 ? ', em outra oitava' : ''}.'
                            : 'A nota era ${nomeNota(alvo.$3, _tipoNota)}: por exemplo, corda ${_cordas[alvo.$1]}, casa ${alvo.$2}. Compare a altura e procure a mesma nota em outra corda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _acertou!
                              ? MhFeedbackCard.verde
                              : MhFeedbackCard.coral,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton.icon(
                              onPressed: _tocando || _salvando
                                  ? null
                                  : _repetirNota,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 20,
                              ),
                              label: const Text('Ouvir novamente'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: respondido
                                ? FilledButton.icon(
                                    onPressed: _novaQuestao,
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                    label: const Text('Próxima nota'),
                                  )
                                : FilledButton.icon(
                                    onPressed: podeConfirmar
                                        ? _confirmar
                                        : null,
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                    ),
                                    label: const Text('Confirmar'),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                side: const BorderSide(
                                  color: AppColors.secondary,
                                  width: 1.4,
                                ),
                              ),
                              onPressed: respondido
                                  ? null
                                  : () => setState(
                                      () => _mostrarDica = !_mostrarDica,
                                    ),
                              icon: const Icon(Icons.lightbulb_outline_rounded),
                              label: Text(
                                _mostrarDica ? 'Ocultar dica' : 'Dica',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
