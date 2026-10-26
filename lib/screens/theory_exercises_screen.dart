import 'dart:math';

import 'package:flutter/material.dart';

import '../data/theory_question_bank.dart';
import '../services/progress_service.dart';

class TheoryExercisesScreen extends StatefulWidget {
  const TheoryExercisesScreen({super.key, this.nivelSelecionado});

  final int? nivelSelecionado;

  @override
  State<TheoryExercisesScreen> createState() => _TheoryExercisesScreenState();
}

class _TheoryExercisesScreenState extends State<TheoryExercisesScreen>
    with WidgetsBindingObserver {
  static const Color _verde = Color(0xFF16D9C5);
  static const Color _preto = Color(0xFF0B1736);
  static const List<String> _nomesDificuldade = [
    'Iniciante',
    'Intermediário',
    'Avançado I',
    'Avançado II',
    'Especialista',
  ];

  final ProgressService _progressService = ProgressService();
  final Random _random = Random();
  final Stopwatch _tempoQuestao = Stopwatch();
  final Set<String> _questoesVistas = {};

  int _nivel = 1;
  int _nivelAtual = 1;
  int _tentativasNoNivel = 0;
  bool _carregando = true;
  bool _respondendo = false;
  String? _erroInicializacao;
  String? _respostaSelecionada;
  String _perguntaExibida = '';
  String _respostaCorretaExibida = '';
  String _modoQuestao = 'Múltipla escolha';
  bool? _acertou;
  late TheoryQuestion _questao;
  late List<String> _opcoes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (state == AppLifecycleState.resumed) {
      if (!_carregando && !_respondendo) _tempoQuestao.start();
    } else {
      _tempoQuestao.stop();
    }
  }

  Future<void> _inicializar() async {
    try {
      final progresso = await _progressService.buscarProgresso();
      final nivelAtual = _numero(progresso['nivelTeoria']).clamp(1, 5).toInt();
      final nivel = (widget.nivelSelecionado ?? nivelAtual)
          .clamp(1, nivelAtual)
          .toInt();
      final vistas = await _progressService.buscarQuestoesRecentes(nivel);
      final etapas = Map<String, dynamic>.from(
        progresso['teoriaEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final etapa = Map<String, dynamic>.from(
        etapas['$nivel'] as Map? ?? const <String, dynamic>{},
      );
      if (!mounted) return;
      _nivel = nivel;
      _nivelAtual = nivelAtual;
      _tentativasNoNivel = nivel == nivelAtual
          ? _numero(progresso['tentativasTeoriaNivel'])
          : _numero(etapa['tentativas']) % 10;
      _questoesVistas
        ..clear()
        ..addAll(vistas);
      setState(() {
        _questao = _sortearQuestao();
        _carregando = false;
      });
      _tempoQuestao.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erroInicializacao =
            'Não foi possível carregar seu nível. Confira sua conexão e tente novamente.';
        _carregando = false;
      });
    }
  }

  TheoryQuestion _sortearQuestao() {
    var disponiveis = theoryQuestionBank
        .where((questao) => questao.difficulty == _nivel)
        .where((questao) => !_questoesVistas.contains(questao.id))
        .toList();
    if (disponiveis.isEmpty) {
      _questoesVistas.clear();
      disponiveis = theoryQuestionBank
          .where((questao) => questao.difficulty == _nivel)
          .toList();
    }
    disponiveis.shuffle(_random);
    final questao = disponiveis.first;
    _questoesVistas.add(questao.id);
    if (_random.nextInt(3) == 0) {
      final verdadeira = _random.nextBool();
      final respostaProposta = verdadeira
          ? questao.answer
          : questao.options
                .where((opcao) => opcao != questao.answer)
                .elementAt(_random.nextInt(questao.options.length - 1));
      _modoQuestao = 'Verdadeiro ou falso';
      _perguntaExibida =
          'A resposta proposta está correta?\n${questao.prompt}\n\n$respostaProposta';
      _respostaCorretaExibida = verdadeira ? 'Verdadeiro' : 'Falso';
      _opcoes = ['Verdadeiro', 'Falso'];
    } else {
      _modoQuestao = 'Múltipla escolha';
      _perguntaExibida = questao.prompt;
      _respostaCorretaExibida = questao.answer;
      _opcoes = [...questao.options]..shuffle(_random);
    }
    return questao;
  }

  Future<void> _responder(String resposta) async {
    if (_respondendo || _carregando) return;
    final questaoRespondida = _questao;
    final correta = resposta == _respostaCorretaExibida;
    final perguntaRespondida = _perguntaExibida;
    final respostaCorreta = _respostaCorretaExibida;
    _tempoQuestao.stop();
    final duracao = _tempoQuestao.elapsed.inSeconds;
    setState(() {
      _respondendo = true;
      _respostaSelecionada = resposta;
      _acertou = correta;
    });

    try {
      await _progressService.registrarExercicio(
        acertou: correta,
        tipo: 'Teórico',
        pergunta: perguntaRespondida,
        resposta: resposta,
        respostaCorreta: respostaCorreta,
        dificuldade: _nivel,
        questaoId: questaoRespondida.id,
        categoria: questaoRespondida.category,
        duracaoSegundos: duracao,
      );
      final progresso = await _progressService.buscarProgresso();
      if (!mounted) return;
      final novoNivel = _numero(progresso['nivelTeoria']).clamp(1, 5).toInt();
      final estavaNaEtapaAtual = _nivel == _nivelAtual;
      if (estavaNaEtapaAtual && novoNivel != _nivel) {
        final vistas = await _progressService.buscarQuestoesRecentes(novoNivel);
        if (!mounted) return;
        _questoesVistas
          ..clear()
          ..addAll(vistas);
      } else if (estavaNaEtapaAtual) {
        _questoesVistas.add(questaoRespondida.id);
      }
      final etapas = Map<String, dynamic>.from(
        progresso['teoriaEtapas'] as Map? ?? const <String, dynamic>{},
      );
      final etapaSelecionada = Map<String, dynamic>.from(
        etapas['${estavaNaEtapaAtual ? novoNivel : _nivel}'] as Map? ??
            const <String, dynamic>{},
      );
      await Future<void>.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      setState(() {
        _nivel = estavaNaEtapaAtual ? novoNivel : _nivel;
        _nivelAtual = novoNivel;
        _tentativasNoNivel = _nivel == novoNivel
            ? _numero(progresso['tentativasTeoriaNivel'])
            : _numero(etapaSelecionada['tentativas']) % 10;
        _questao = _sortearQuestao();
        _respostaSelecionada = null;
        _acertou = null;
        _respondendo = false;
        _tempoQuestao
          ..reset()
          ..start();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _respondendo = false;
        _respostaSelecionada = null;
        _acertou = null;
        _tempoQuestao
          ..reset()
          ..start();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar sua resposta. Confira sua conexão e tente novamente.',
          ),
        ),
      );
    }
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
          'Exercício Teórico',
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  children: [
                    _buildProgresso(),
                    const SizedBox(height: 12),
                    _buildPergunta(),
                    const SizedBox(height: 12),
                    _buildOpcoes(),
                    const SizedBox(height: 10),
                    _buildFeedback(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgresso() {
    final progresso = _tentativasNoNivel / 10;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: _verde, size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Nível $_nivel — ${_nomesDificuldade[_nivel - 1]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '$_tentativasNoNivel/10',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_verde),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _nivel == 5
                ? 'Nível especialista alcançado. Continue praticando para manter sua precisão.'
                : 'Acerte pelo menos 7 das próximas 10 para avançar.',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPergunta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _verde.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _questao.category,
              style: const TextStyle(
                color: Color(0xFF0B756A),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _modoQuestao,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Icon(
            _nivel >= 4 ? Icons.psychology_alt : Icons.help_outline,
            color: _preto,
            size: 38,
          ),
          const SizedBox(height: 11),
          Text(
            _perguntaExibida,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _preto,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcoes() => Column(
    children: _opcoes.map((opcao) {
      final selecionada = _respostaSelecionada == opcao;
      final correta = _respostaCorretaExibida == opcao;
      final respondida = _respostaSelecionada != null;
      final fundo = !respondida
          ? Colors.white
          : correta
          ? Colors.green
          : selecionada
          ? Colors.red
          : Colors.white;
      final corTexto = respondida && (correta || selecionada)
          ? Colors.white
          : _preto;
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _respondendo ? null : () => _responder(opcao),
            style: ElevatedButton.styleFrom(
              backgroundColor: fundo,
              disabledBackgroundColor: fundo,
              foregroundColor: corTexto,
              disabledForegroundColor: corTexto,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    opcao,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (respondida && correta)
                  const Icon(Icons.check_circle, color: Colors.white),
                if (respondida && selecionada && !correta)
                  const Icon(Icons.cancel, color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildFeedback() {
    if (_acertou == null) return const SizedBox(height: 40);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _acertou! ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _acertou!
            ? 'Correto! +10 XP'
            : 'Resposta incorreta. A resposta correta está marcada acima.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int _numero(dynamic valor) => valor is num ? valor.toInt() : 0;
}
