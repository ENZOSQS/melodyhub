// lib/screens/home_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'achievements_screen.dart';
import 'history_screen.dart';
import 'icon_shop_screen.dart';
import 'learning_path_screen.dart';
import 'profile_screen.dart';
import 'guitar_note_exercise_screen.dart';
import 'music_concepts_screen.dart';
import 'rhythm_exercise_screen.dart';
import '../domain/continue_rules.dart';
import '../theme/app_theme.dart';
import '../services/progress_service.dart';
import '../widgets/mh_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color preto = AppColors.background;

  final ProgressService _progressService = ProgressService();
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_reconciliarSequencia());
    _agendarViradaDoDia();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _reconciliarSequencia() async {
    try {
      await _progressService.reconciliarSequenciaDias();
    } catch (erro) {
      debugPrint('Não foi possível atualizar a sequência diária: $erro');
    }
  }

  void _agendarViradaDoDia() {
    final agora = DateTime.now();
    final proximaVirada = DateTime(agora.year, agora.month, agora.day + 1);
    _midnightTimer = Timer(proximaVirada.difference(agora), () {
      if (!mounted) return;
      setState(() {});
      unawaited(_reconciliarSequencia());
      _agendarViradaDoDia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        backgroundColor: preto,
        body: Center(
          child: Text(
            'Usuário não autenticado.',
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(usuario.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Não foi possível carregar seu progresso.',
                  style: TextStyle(color: AppColors.text),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final dados = snapshot.data?.data() ?? {};
            final nome = (dados['nome'] ?? usuario.displayName ?? 'Aluno')
                .toString();
            final primeiroNome = nome.trim().split(RegExp(r'\s+')).first;
            final xp = _numero(dados['xp']);
            final nivel = _numero(dados['nivel']);
            final pontos = _numero(dados['pontos']);
            final sequenciaDiasAtual = _progressService
                .calcularSequenciaDiasAtual(dados);
            final conquistas = List<String>.from(dados['conquistas'] ?? []);

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                MelodyHeader(onNotificacoes: () => _abrir(const ProfileScreen())),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${primeiroNome.isEmpty ? 'Aluno' : primeiroNome}!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _cartaoNivel(
                        nivel: nivel,
                        xp: xp,
                        sequenciaDias: sequenciaDiasAtual,
                      ),
                      const SizedBox(height: 16),
                      _cartaoContinuar(),
                      const SizedBox(height: 16),
                      _atalhos(),
                      const MhSectionTitle('Mais opções'),
                      _opcao(
                        icone: Icons.piano_outlined,
                        titulo: 'Identificar a nota',
                        descricao: 'Notas e memória auditiva em etapas.',
                        destino: const LearningPathScreen(
                          track: LearningTrack.pratica,
                        ),
                      ),
                      _opcao(
                        icone: Icons.storefront_outlined,
                        titulo: 'Loja de ícones · $pontos pontos',
                        descricao:
                            'Acumule pontos nos exercícios e personalize seu perfil.',
                        destino: const IconShopScreen(),
                      ),
                      _opcao(
                        icone: Icons.emoji_events_outlined,
                        titulo: 'Conquistas (${conquistas.length})',
                        descricao: 'Veja as medalhas que você já desbloqueou.',
                        destino: const AchievementsScreen(),
                      ),
                      _opcao(
                        icone: Icons.history_rounded,
                        titulo: 'Histórico',
                        descricao: 'Revise suas respostas e a duração de cada uma.',
                        destino: const HistoryScreen(),
                      ),
                      _opcao(
                        icone: Icons.person_outline_rounded,
                        titulo: 'Meu Perfil',
                        descricao: 'Nome, preferências e lembretes de estudo.',
                        destino: const ProfileScreen(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _abrir(Widget destino) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
  }

  Widget _cartaoNivel({
    required int nivel,
    required int xp,
    required int sequenciaDias,
  }) {
    final progresso = _calcularProgresso(xp);
    final maximo = _xpProximoNivel(xp) == 0;
    return MhCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 92,
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: AppColors.primary,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),
              const MhDividerVertical(altura: 76),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nível $nivel',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maximo
                          ? '$xp XP · nível máximo'
                          : '$xp / ${_proximoNivelPorXP(xp)} XP',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progresso),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            LinearProgressIndicator(
                              value: value,
                              minHeight: 14,
                              backgroundColor: AppColors.surfaceHighlight,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.primary,
                size: 30,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sequência: ',
                style: TextStyle(color: AppColors.text, fontSize: 18),
              ),
              Text(
                '$sequenciaDias ${sequenciaDias == 1 ? 'dia' : 'dias'}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Cartão "Continue de onde parou", calculado a partir do último evento do
  /// histórico. Sem histórico, sugere começar pela teoria.
  Widget _cartaoContinuar() =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ultimoEvento,
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final sugestao =
              sugestaoContinuar(docs.isEmpty ? null : docs.first.data()) ??
              const SugestaoContinuar(
                atividade: AtividadeContinuar.teoria,
                rotulo: 'Teoria – Etapa 1',
                etapa: 1,
              );
          final semHistorico = docs.isEmpty;
          return MhCard(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  semHistorico ? 'Comece por aqui' : 'Continue de onde parou',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    MhIconTile(
                      icone: _iconeAtividade(sugestao.atividade),
                      cor: AppColors.secondary,
                      tamanho: 64,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _abrir(_destino(sugestao.atividade)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    sugestao.rotulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.primary,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ultimoEvento =
      _progressService.ouvirHistorico(limite: 1);

  Widget _atalhos() {
    final itens = <(IconData, String, AtividadeContinuar)>[
      (Icons.menu_book_outlined, 'Teoria', AtividadeContinuar.teoria),
      (Icons.graphic_eq_rounded, 'Intervalos', AtividadeContinuar.intervalos),
      (Icons.timer_outlined, 'Ritmo', AtividadeContinuar.ritmo),
      (Icons.music_note_outlined, 'Violão', AtividadeContinuar.violao),
    ];
    return Row(
      children: [
        for (var i = 0; i < itens.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: MhCard(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
              onTap: () => _abrir(_destino(itens[i].$3)),
              child: Column(
                children: [
                  Icon(itens[i].$1, color: AppColors.primary, size: 34),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      itens[i].$2,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _iconeAtividade(AtividadeContinuar atividade) => switch (atividade) {
    AtividadeContinuar.teoria => Icons.menu_book_outlined,
    AtividadeContinuar.pratica => Icons.piano_outlined,
    AtividadeContinuar.intervalos => Icons.graphic_eq_rounded,
    AtividadeContinuar.ritmo => Icons.timer_outlined,
    AtividadeContinuar.escalas => Icons.show_chart_rounded,
    AtividadeContinuar.violao => Icons.music_note_outlined,
  };

  Widget _destino(AtividadeContinuar atividade) => switch (atividade) {
    AtividadeContinuar.teoria => const LearningPathScreen(
      track: LearningTrack.teoria,
    ),
    AtividadeContinuar.pratica => const LearningPathScreen(
      track: LearningTrack.pratica,
    ),
    AtividadeContinuar.intervalos => const LearningPathScreen(
      track: LearningTrack.intervalos,
    ),
    AtividadeContinuar.ritmo => const RhythmExerciseScreen(),
    AtividadeContinuar.escalas => const MusicConceptsScreen(
      exercise: ConceptExercise.scale,
    ),
    AtividadeContinuar.violao => const GuitarNoteExerciseScreen(),
  };

  Widget _opcao({
    required IconData icone,
    required String titulo,
    required String descricao,
    required Widget destino,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: MhCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _abrir(destino),
      child: Row(
        children: [
          MhIconTile(icone: icone, tamanho: 50),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
    ),
  );

  double _calcularProgresso(int xp) {
    if (xp >= 1000) {
      return 1.0;
    }

    final anterior = _xpNivelAnterior(xp);
    final proximo = _proximoNivelPorXP(xp);

    if (proximo <= anterior) {
      return 1.0;
    }

    return ((xp - anterior) / (proximo - anterior)).clamp(0.0, 1.0);
  }

  int _xpProximoNivel(int xp) {
    if (xp < 100) {
      return 100 - xp;
    }

    if (xp < 250) {
      return 250 - xp;
    }

    if (xp < 500) {
      return 500 - xp;
    }

    if (xp < 1000) {
      return 1000 - xp;
    }

    return 0;
  }

  int _xpNivelAnterior(int xp) {
    if (xp < 100) {
      return 0;
    }

    if (xp < 250) {
      return 100;
    }

    if (xp < 500) {
      return 250;
    }

    if (xp < 1000) {
      return 500;
    }

    return 1000;
  }

  int _proximoNivelPorXP(int xp) {
    if (xp < 100) {
      return 100;
    }

    if (xp < 250) {
      return 250;
    }

    if (xp < 500) {
      return 500;
    }

    if (xp < 1000) {
      return 1000;
    }

    return 1000;
  }

  int _numero(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return 0;
  }
}
