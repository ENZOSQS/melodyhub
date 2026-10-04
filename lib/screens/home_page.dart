import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'keyboard_screen.dart';
import 'exercises_screen.dart';
import 'achievements_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  double calcularProgresso(
    int xp,
  ) {
    if (xp >= 1000) {
      return 1.0;
    }

    int inicio;

    int fim;

    if (xp < 100) {
      inicio = 0;
      fim = 100;
    } else if (xp < 250) {
      inicio = 100;
      fim = 250;
    } else if (xp < 500) {
      inicio = 250;
      fim = 500;
    } else {
      inicio = 500;
      fim = 1000;
    }

    return ((xp - inicio) /
            (fim - inicio))
        .clamp(0.0, 1.0);
  }

  int xpProximoNivel(
    int xp,
  ) {
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

  int xpNivelAnterior(
    int xp,
  ) {
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final usuario =
        FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return Scaffold(
        backgroundColor:
            const Color(0xFF0D0D0D),
        body: const Center(
          child: Text(
            'Usuário não autenticado.',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFF0D0D0D),
      body: SafeArea(
        child: StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(usuario.uid)
              .snapshots(),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(
                  color: Color(0xFF35A85B),
                ),
              );
            }

            final dados =
                snapshot.data?.data() ?? {};

            final nome =
                dados['nome'] ??
                    usuario.displayName ??
                    'Usuário';

            final xp =
                (dados['xp'] ?? 0) as num;

            final nivel =
                (dados['nivel'] ?? 1) as num;

            final exercicios =
                (dados[
                            'exerciciosRespondidos'] ??
                        0)
                    as num;

            final acertos =
                (dados['acertos'] ?? 0)
                    as num;

            final erros =
                (dados['erros'] ?? 0)
                    as num;

            final conquistas =
                List<String>.from(
              dados['conquistas'] ?? [],
            );

            final xpAtual =
                xp.toInt();

            final nivelAtual =
                nivel.toInt();

            final progresso =
                calcularProgresso(
              xpAtual,
            );

            final faltam =
                xpProximoNivel(
              xpAtual,
            );

            final anterior =
                xpNivelAnterior(
              xpAtual,
            );

            final proximo =
                nivelAtual >= 5
                    ? 1000
                    : anterior +
                        (nivelAtual == 1
                            ? 100
                            : nivelAtual == 2
                                ? 150
                                : nivelAtual == 3
                                    ? 250
                                    : 500);

            return RefreshIndicator(
              color:
                  const Color(0xFF35A85B),
              backgroundColor:
                  const Color(0xFF181818),
              onRefresh: () async {},
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  30,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Olá! 👋',
                              style: TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              nome.toString(),
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 25,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF17251C,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          border: Border.all(
                            color:
                                const Color(
                              0xFF35A85B,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .workspace_premium,
                              color:
                                  Color(
                                0xFF35A85B,
                              ),
                              size: 19,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Nível $nivelAtual',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF151515,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),
                      border: Border.all(
                        color:
                            Colors.white10,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .auto_awesome,
                              color:
                                  Color(
                                0xFF35A85B,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            const Expanded(
                              child: Text(
                                'Seu progresso',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '$xpAtual XP',
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFF35A85B,
                                ),
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          child:
                              LinearProgressIndicator(
                            value:
                                progresso,
                            minHeight: 10,
                            backgroundColor:
                                Colors.white12,
                            valueColor:
                                const AlwaysStoppedAnimation<
                                    Color>(
                              Color(
                                0xFF35A85B,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Text(
                              nivelAtual >=
                                      5
                                  ? 'Nível máximo!'
                                  : '$anterior XP',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              nivelAtual >=
                                      5
                                  ? 'Parabéns!'
                                  : '$proximo XP',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        if (nivelAtual <
                            5) ...[
                          const SizedBox(
                            height: 14,
                          ),
                          Text(
                            'Faltam $faltam XP para o próximo nível',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildEstatistica(
                          icone:
                              Icons.quiz_outlined,
                          valor:
                              exercicios.toInt(),
                          titulo:
                              'Exercícios',
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            _buildEstatistica(
                          icone:
                              Icons.check_circle_outline,
                          valor:
                              acertos.toInt(),
                          titulo:
                              'Acertos',
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            _buildEstatistica(
                          icone:
                              Icons.close_rounded,
                          valor:
                              erros.toInt(),
                          titulo:
                              'Erros',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AchievementsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF151515,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color:
                              Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration:
                                const BoxDecoration(
                              color:
                                  Color(
                                0xFF35A85B,
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                            child:
                                const Icon(
                              Icons
                                  .emoji_events,
                              color:
                                  Colors.white,
                            ),
                          ),
                          const SizedBox(
                            width: 14,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Conquistas',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '$conquistas de 7 desbloqueadas',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons
                                .arrow_forward_ios,
                            color:
                                Colors.white38,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 26,
                  ),

                  const Text(
                    'Aprender',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildModuloCard(
                    context: context,
                    icone:
                        Icons.piano,
                    titulo:
                        'Simulador de instrumento',
                    descricao:
                        'Pratique notas no teclado virtual.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const KeyboardScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _buildModuloCard(
                    context: context,
                    icone:
                        Icons.hearing,
                    titulo:
                        'Exercícios auditivos',
                    descricao:
                        'Identifique as notas pelo som.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ExercisesScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Acesso rápido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildAtalho(
                          icone:
                              Icons.history,
                          titulo:
                              'Histórico',
                          onTap: () {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Histórico será implementado posteriormente.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child:
                            _buildAtalho(
                          icone:
                              Icons.person_outline,
                          titulo:
                              'Perfil',
                          onTap: () {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Perfil será implementado posteriormente.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEstatistica({
    required IconData icone,
    required int valor,
    required String titulo,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFF151515),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            color:
                const Color(0xFF35A85B),
            size: 22,
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            '$valor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuloCard({
    required BuildContext context,
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              const Color(0xFF151515),
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFF17251C),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                color:
                    const Color(
                  0xFF35A85B,
                ),
                size: 27,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    titulo,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    descricao,
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color:
                  Colors.white38,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtalho({
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              const Color(0xFF151515),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color:
                  const Color(0xFF35A85B),
              size: 27,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}