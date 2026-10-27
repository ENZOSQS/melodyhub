import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../services/progress_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key, this.nivelSelecionado});

  final int? nivelSelecionado;

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen>
    with WidgetsBindingObserver {
  static const Color _verde = Color(0xFF16D9C5);
  static const Color _preto = Color(0xFF0A1020);
  static const List<Map<String, String>> _notas = [
    {'nome': 'Dó', 'arquivo': 'C3.wav'},
    {'nome': 'Ré', 'arquivo': 'D3.wav'},
    {'nome': 'Mi', 'arquivo': 'E3.wav'},
    {'nome': 'Fá', 'arquivo': 'F3.wav'},
    {'nome': 'Sol', 'arquivo': 'G3.wav'},
    {'nome': 'Lá', 'arquivo': 'A3.wav'},
    {'nome': 'Si', 'arquivo': 'B3.wav'},
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ProgressService _progressService = ProgressService();
  final Random _random = Random();
  final Stopwatch _tempoQuestao = Stopwatch();

  int _nivel = 1;
  int _nivelAtual = 1;
  int _sequenciaAcertos = 0;
  bool _carregando = true;
  bool _respondendo = false;
  bool _reproduzindo = false;
  bool _emForeground = true;
  bool _mostrarFeedback = false;
  bool? _acertou;
  String? _erroInicializacao;
  List<Map<String, String>> _alvo = [];
  List<String> _respostas = [];

  int get _tamanhoSequencia => _nivel == 1 ? 1 : _nivel + 1;

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
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _emForeground = state == AppLifecycleState.resumed;
    if (_emForeground) {
      if (!_carregando && !_respondendo) _tempoQuestao.start();
    } else {
      _tempoQuestao.stop();
      _audioPlayer.stop();
    }
  }

  Future<void> _inicializar() async {
    try {
      final progresso = await _progressService.buscarProgresso();
      if (!mounted) return;
      final nivelAtual = _numero(progresso['nivelPratico']).clamp(1, 5).toInt();
      setState(() {
        _nivelAtual = nivelAtual;
        _nivel = (widget.nivelSelecionado ?? nivelAtual)
            .clamp(1, nivelAtual)
            .toInt();
        _sequenciaAcertos = _nivel == nivelAtual
            ? _numero(progresso['sequenciaAcertosPraticos'])
            : 0;
        _alvo = _sortearSequencia();
        _carregando = false;
      });
      if (_emForeground) _tempoQuestao.start();
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

  List<Map<String, String>> _sortearSequencia() {
    final resultado = <Map<String, String>>[];
    while (resultado.length < _tamanhoSequencia) {
      final nota = _notas[_random.nextInt(_notas.length)];
      if (resultado.isEmpty || resultado.last['nome'] != nota['nome']) {
        resultado.add(nota);
      }
    }
    return resultado;
  }

  Future<void> _tocarSequencia() async {
    if (!mounted || _respondendo || _reproduzindo || _alvo.isEmpty) return;
    setState(() => _reproduzindo = true);
    try {
      for (final nota in _alvo) {
        if (!mounted) return;
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('sounds/${nota['arquivo']}'));
        try {
          await _audioPlayer.onPlayerComplete.first.timeout(
            const Duration(seconds: 3),
          );
        } on TimeoutException {
          await _audioPlayer.stop();
        }
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
    } catch (erro) {
      debugPrint('Erro ao reproduzir sequência: $erro');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível reproduzir a sequência.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reproduzindo = false);
    }
  }

  void _receberNota(String resposta) {
    if (_respondendo || _reproduzindo || _carregando) return;
    final indice = _respostas.length;
    if (indice >= _alvo.length) return;
    final respostas = [..._respostas, resposta];
    final errou = resposta != _alvo[indice]['nome'];
    setState(() => _respostas = respostas);
    if (errou || respostas.length == _alvo.length) {
      _registrarSequencia(correta: !errou && respostas.length == _alvo.length);
    }
  }

  Future<void> _registrarSequencia({required bool correta}) async {
    _tempoQuestao.stop();
    final duracao = _tempoQuestao.elapsed.inSeconds;
    final respostaCorreta = _alvo.map((nota) => nota['nome']).join(' – ');
    final respostaUsuario = _respostas.join(' – ');
    setState(() {
      _respondendo = true;
      _mostrarFeedback = true;
      _acertou = correta;
    });
    try {
      await _progressService.registrarExercicio(
        acertou: correta,
        tipo: 'Prático',
        pergunta: _tamanhoSequencia == 1
            ? 'Identifique a nota ouvida.'
            : 'Repita a sequência de $_tamanhoSequencia notas.',
        resposta: respostaUsuario,
        respostaCorreta: respostaCorreta,
        dificuldade: _nivel,
        questaoId: 'sequencia_notas_nivel_$_nivel',
        categoria: 'Memória auditiva',
        duracaoSegundos: duracao,
      );
      final progresso = await _progressService.buscarProgresso();
      if (!mounted) return;
      final estavaNaEtapaAtual = _nivel == _nivelAtual;
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      setState(() {
        _nivelAtual = _numero(progresso['nivelPratico']).clamp(1, 5).toInt();
        _nivel = estavaNaEtapaAtual ? _nivelAtual : _nivel;
        _sequenciaAcertos = estavaNaEtapaAtual
            ? _numero(progresso['sequenciaAcertosPraticos'])
            : 0;
        _alvo = _sortearSequencia();
        _respostas = [];
        _mostrarFeedback = false;
        _acertou = null;
        _respondendo = false;
        _tempoQuestao
          ..reset()
          ..start();
        if (!_emForeground) _tempoQuestao.stop();
      });
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (mounted && _emForeground) await _tocarSequencia();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _respondendo = false;
        _mostrarFeedback = false;
        _acertou = null;
        _respostas = [];
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

  Color _corTecla(String nome) {
    if (_mostrarFeedback &&
        _acertou == true &&
        _alvo.any((nota) => nota['nome'] == nome)) {
      return Colors.green;
    }
    if (_mostrarFeedback &&
        _acertou == false &&
        _respostas.isNotEmpty &&
        _respostas.last == nome) {
      return Colors.red;
    }
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
                    _buildRespostas(),
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
    final faltaParaAvancar = (_nivel * 3 - _sequenciaAcertos).clamp(0, 99);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.hearing, color: _preto, size: 34),
          const SizedBox(height: 7),
          Text(
            'Sequência auditiva — nível $_nivel',
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
                ? 'Identifique a nota tocada. Nos próximos níveis, você repetirá sequências.'
                : 'Ouça as $_tamanhoSequencia notas e repita no teclado na mesma ordem.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (_nivel < 5) ...[
            const SizedBox(height: 6),
            Text(
              '$_sequenciaAcertos acertos seguidos · faltam $faltaParaAvancar para subir de nível',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0B756A),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Nível máximo · $_sequenciaAcertos acertos seguidos',
              style: const TextStyle(
                color: Color(0xFF0B756A),
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
                backgroundColor: preenchida ? _verde : Colors.white12,
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
        color: const Color(0xFF050B1B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: AspectRatio(
        aspectRatio: 7 / 3.2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _notas.map((nota) {
            final nome = nota['nome']!;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: _respondendo || _reproduzindo
                      ? null
                      : () => _receberNota(nome),
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
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    if (!_mostrarFeedback || _acertou == null) {
      return const SizedBox(height: 42);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _acertou! ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _acertou! ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 23,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _acertou! ? 'Sequência correta! +10 XP' : 'Sequência incorreta',
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
    );
  }

  int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;
}
