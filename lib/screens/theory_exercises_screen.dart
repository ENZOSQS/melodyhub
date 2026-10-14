// lib/screens/theory_exercises_screen.dart

import 'package:flutter/material.dart';

import '../services/progress_service.dart';

class TheoryExercisesScreen extends StatefulWidget {
  const TheoryExercisesScreen({super.key});

  @override
  State<TheoryExercisesScreen> createState() => _TheoryExercisesScreenState();
}

class _TheoryExercisesScreenState extends State<TheoryExercisesScreen>
    with WidgetsBindingObserver {
  static const Color verde = Color(0xFF16D9C5);

  static const Color preto = Color(0xFF0B1736);

  final ProgressService _progressService = ProgressService();

  int _questaoAtual = 0;

  final Stopwatch _tempoQuestao = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_respondendo) _tempoQuestao.start();
    } else {
      _tempoQuestao.stop();
    }
  }

  bool _respondendo = false;

  String? _respostaSelecionada;

  final List<Map<String, dynamic>> _questoes = [
    {
      'categoria': 'Notas musicais',
      'pergunta': 'Quantas notas naturais existem na música ocidental?',
      'opcoes': ['5', '6', '7', '8'],
      'resposta': '7',
    },
    {
      'categoria': 'Notas musicais',
      'pergunta': 'Qual é a sequência correta das notas naturais?',
      'opcoes': [
        'Dó, Ré, Mi, Fá, Sol, Lá, Si',
        'Dó, Mi, Ré, Fá, Sol, Lá, Si',
        'Ré, Mi, Fá, Sol, Lá, Si, Dó',
        'Dó, Ré, Fá, Mi, Sol, Lá, Si',
      ],
      'resposta': 'Dó, Ré, Mi, Fá, Sol, Lá, Si',
    },
    {
      'categoria': 'Notas musicais',
      'pergunta': 'Qual nota vem depois de Mi?',
      'opcoes': ['Ré', 'Fá', 'Sol', 'Lá'],
      'resposta': 'Fá',
    },
    {
      'categoria': 'Notas musicais',
      'pergunta': 'Qual nota vem antes de Sol?',
      'opcoes': ['Mi', 'Fá', 'Lá', 'Si'],
      'resposta': 'Fá',
    },
    {
      'categoria': 'Intervalos',
      'pergunta': 'O que é um intervalo musical?',
      'opcoes': [
        'A distância entre duas notas',
        'A velocidade da música',
        'O volume de uma música',
        'O timbre de um instrumento',
      ],
      'resposta': 'A distância entre duas notas',
    },
    {
      'categoria': 'Ritmo',
      'pergunta':
          'Qual elemento musical está relacionado à duração dos sons e silêncios?',
      'opcoes': ['Timbre', 'Ritmo', 'Altura', 'Melodia'],
      'resposta': 'Ritmo',
    },
    {
      'categoria': 'Altura',
      'pergunta': 'O que diferencia um som grave de um som agudo?',
      'opcoes': ['A altura', 'O ritmo', 'O volume', 'A duração'],
      'resposta': 'A altura',
    },
    {
      'categoria': 'Timbre',
      'pergunta': 'O que é timbre?',
      'opcoes': [
        'A característica que diferencia sons de fontes diferentes',
        'A velocidade de uma música',
        'A distância entre duas notas',
        'A duração de uma nota',
      ],
      'resposta': 'A característica que diferencia sons de fontes diferentes',
    },
    {
      'categoria': 'Escalas',
      'pergunta': 'Qual é a primeira nota da escala de Dó maior?',
      'opcoes': ['Dó', 'Ré', 'Mi', 'Sol'],
      'resposta': 'Dó',
    },
    {
      'categoria': 'Teoria musical',
      'pergunta':
          'Qual destes elementos está relacionado à organização dos sons no tempo?',
      'opcoes': ['Ritmo', 'Timbre', 'Altura', 'Intensidade'],
      'resposta': 'Ritmo',
    },
  ];

  Map<String, dynamic> get _questao => _questoes[_questaoAtual];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: preto,
      appBar: AppBar(
        backgroundColor: preto,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Exercício Teórico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            children: [
              _buildProgresso(),
              const SizedBox(height: 12),
              _buildPergunta(),
              const SizedBox(height: 12),
              _buildOpcoes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgresso() {
    final progresso = (_questaoAtual + 1) / _questoes.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.menu_book, color: verde, size: 21),
                  SizedBox(width: 8),
                  Text(
                    'Teoria Musical',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                '${_questaoAtual + 1}/${_questoes.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(verde),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPergunta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: verde.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _questao['categoria'] as String,
              style: const TextStyle(
                color: Color(0xFF0B756A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Icon(Icons.help_outline, color: preto, size: 38),
          const SizedBox(height: 10),
          Text(
            _questao['pergunta'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: preto,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcoes() {
    final opcoes = List<String>.from(_questao['opcoes']);

    final respostaCorreta = _questao['resposta'] as String;

    return Column(
      children: opcoes.map((opcao) {
        final selecionada = _respostaSelecionada == opcao;

        final correta = opcao == respostaCorreta;

        Color fundo = Colors.white;

        Color texto = preto;

        if (_respostaSelecionada != null) {
          if (correta) {
            fundo = Colors.green;
            texto = Colors.white;
          } else if (selecionada) {
            fundo = Colors.red;
            texto = Colors.white;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _respondendo
                  ? null
                  : () {
                      _responder(opcao);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: fundo,
                foregroundColor: texto,
                disabledBackgroundColor: fundo,
                disabledForegroundColor: texto,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                  if (_respostaSelecionada != null && correta)
                    const Icon(Icons.check_circle, color: Colors.white),
                  if (_respostaSelecionada != null && selecionada && !correta)
                    const Icon(Icons.cancel, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _responder(String resposta) async {
    if (_respondendo) {
      return;
    }

    final respostaCorreta = _questao['resposta'] as String;

    final acertou = resposta == respostaCorreta;
    _tempoQuestao.stop();
    final duracaoSegundos = _tempoQuestao.elapsed.inSeconds;

    setState(() {
      _respondendo = true;
      _respostaSelecionada = resposta;
    });

    try {
      await _progressService.registrarExercicio(
        acertou: acertou,
        tipo: 'Teórico',
        pergunta: _questao['pergunta'] as String,
        resposta: resposta,
        respostaCorreta: respostaCorreta,
        duracaoSegundos: duracaoSegundos,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _respondendo = false;
        _respostaSelecionada = null;
      });
      _tempoQuestao
        ..reset()
        ..start();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar seu exercício. Confira sua conexão e tente novamente.',
          ),
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) {
      return;
    }

    setState(() {
      if (_questaoAtual < _questoes.length - 1) {
        _questaoAtual++;
      } else {
        _questaoAtual = 0;
      }

      _respondendo = false;
      _respostaSelecionada = null;
      _tempoQuestao
        ..reset()
        ..start();
    });
  }
}
