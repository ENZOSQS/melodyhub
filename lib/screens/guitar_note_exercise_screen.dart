import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../services/music_audio_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../utils/guitar_sample_map.dart';
import '../utils/note_names.dart';
import '../widgets/guitar_fretboard.dart';

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
  String _tipoNota = 'solfejo';
  (int, int, int)? _alvo;
  (int, int)? _posicaoSelecionada;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _cronometro.stop();
    super.dispose();
  }

  Future<void> _inicializar() async {
    try {
      _tipoNota = await AppPreferences.noteType();
      final amostras = <String>{
        for (var corda = 0; corda < 6; corda++)
          for (var casa = 0; casa <= 5; casa++)
            GuitarSampleMap.forPosition(corda, casa),
      };
      await _audio.preload(amostras);
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
      await _audio.playFor(
        GuitarSampleMap.forPosition(alvo.$1, alvo.$2),
        const Duration(milliseconds: 1600),
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

  Future<void> _responder(int corda, int casa, int midi) async {
    final alvo = _alvo;
    if (alvo == null || _tocando || _salvando || _acertou != null) return;
    final acertou = midi == alvo.$3;
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
        setState(() => _posicaoSelecionada = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a resposta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      title: const Text('Encontre a nota no violão'),
    ),
    body: _carregando
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Ouça a nota tocada e encontre qualquer posição com a mesma altura no braço.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.text, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _tocando || _salvando
                                  ? null
                                  : _repetirNota,
                              icon: const Icon(Icons.replay),
                              label: const Text('Ouvir novamente'),
                            ),
                            TextButton.icon(
                              onPressed: _acertou == null
                                  ? () => setState(
                                      () => _mostrarDica = !_mostrarDica,
                                    )
                                  : null,
                              icon: const Icon(Icons.lightbulb_outline),
                              label: Text(
                                _mostrarDica ? 'Ocultar dica' : 'Dica',
                              ),
                            ),
                          ],
                        ),
                        if (_mostrarDica && _alvo != null)
                          Text(
                            'Uma posição possível: corda ${_cordas[_alvo!.$1]}, casa ${_alvo!.$2}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        if (_acertou != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _acertou!
                                ? 'Correto! Essa posição produz ${nomeNota(_alvo!.$3, _tipoNota)}.'
                                : 'A nota era ${nomeNota(_alvo!.$3, _tipoNota)}. Compare a altura e procure a mesma nota em outra corda ou casa.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _acertou!
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_acertou!)
                            Text(
                              'Exemplo: corda ${_cordas[_alvo!.$1]}, casa ${_alvo!.$2}.',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          TextButton.icon(
                            onPressed: _novaQuestao,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Próxima nota'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'CASAS 0–12 · QUALQUER POSIÇÃO COM A MESMA NOTA VALE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: GuitarFretboard(
                    onPositionPressed: _responder,
                    showNoteNames: true,
                    tipoNota: _tipoNota,
                    activePosition: _posicaoSelecionada,
                  ),
                ),
              ],
            ),
          ),
  );
}
