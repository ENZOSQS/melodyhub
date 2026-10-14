// lib/screens/home_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'achievements_screen.dart';
import 'exercises_screen.dart';
import 'history_screen.dart';
import 'keyboard_screen.dart';
import 'profile_screen.dart';
import 'performance_screen.dart';
import 'theory_exercises_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color verde = Color(0xFF16D9C5);
  static const Color verdeEscuro = Color(0xFF0B756A);
  static const Color preto = Color(0xFF0B1736);

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        backgroundColor: preto,
        body: Center(
          child: Text(
            'Usuário não autenticado.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: preto,
      appBar: AppBar(
        backgroundColor: preto,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Melody Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Não foi possível carregar seu progresso.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: verde));
          }
          final dados = snapshot.data?.data() ?? {};

          final nome = dados['nome'] ?? usuario.displayName ?? 'Aluno';

          final xp = _numero(dados['xp']);
          final nivel = _numero(dados['nivel']);
          final exercicios = _numero(dados['exerciciosRespondidos']);
          final acertos = _numero(dados['acertos']);
          final erros = _numero(dados['erros']);
          final sequenciaDiasAtual = _numero(dados['sequenciaDiasAtual']);
          final precisao = exercicios == 0
              ? 0
              : (acertos * 100 / exercicios).round();

          final conquistas = List<String>.from(dados['conquistas'] ?? []);

          final progresso = _calcularProgresso(xp);
          final xpProximo = _xpProximoNivel(xp);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSaudacao(nome.toString(), nivel),
                  const SizedBox(height: 16),
                  _buildCardXP(
                    xp: xp,
                    nivel: nivel,
                    progresso: progresso,
                    xpProximo: xpProximo,
                  ),
                  const SizedBox(height: 14),
                  _buildEstatisticas(
                    exercicios: exercicios,
                    acertos: acertos,
                    erros: erros,
                    sequenciaDiasAtual: sequenciaDiasAtual,
                    precisao: precisao,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Aprender',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildOpcaoPrincipal(
                    context,
                    icone: Icons.piano,
                    titulo: 'Exercício Prático',
                    descricao:
                        'Identifique as notas usando o teclado de piano.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExercisesScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildOpcaoPrincipal(
                    context,
                    icone: Icons.menu_book,
                    titulo: 'Exercício Teórico',
                    descricao: 'Teste seus conhecimentos de teoria musical.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TheoryExercisesScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildOpcaoPrincipal(
                    context,
                    icone: Icons.piano_outlined,
                    titulo: 'Simulador de Instrumento',
                    descricao: 'Pratique livremente no instrumento virtual.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KeyboardScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Meu progresso',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildAtalho(
                          context,
                          icone: Icons.history,
                          titulo: 'Histórico',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAtalho(
                          context,
                          icone: Icons.insights_outlined,
                          titulo: 'Desempenho',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PerformanceScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAtalho(
                          context,
                          icone: Icons.emoji_events,
                          titulo: 'Conquistas (${conquistas.length})',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AchievementsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _buildOpcaoSecundaria(
                    context,
                    icone: Icons.person_outline,
                    titulo: 'Meu Perfil',
                    descricao: 'Visualize e edite suas informações.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaudacao(String nome, int nivel) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Olá,',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: verde.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: verde.withValues(alpha: 0.4)),
          ),
          child: Text(
            'Nível $nivel',
            style: const TextStyle(color: verde, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCardXP({
    required int xp,
    required int nivel,
    required double progresso,
    required int xpProximo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.star, color: preto, size: 23),
                  SizedBox(width: 8),
                  Text(
                    'Seu progresso',
                    style: TextStyle(
                      color: preto,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '$xp XP',
                style: const TextStyle(
                  color: preto,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 9,
              backgroundColor: const Color(0xFFE6EAF0),
              valueColor: const AlwaysStoppedAnimation<Color>(verde),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nível $nivel',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                xpProximo > 0 ? 'Faltam $xpProximo XP' : 'Nível máximo',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticas({
    required int exercicios,
    required int acertos,
    required int erros,
    required int sequenciaDiasAtual,
    required int precisao,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do desempenho',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _estatistica(
                  Icons.quiz_outlined,
                  'Exercícios',
                  '$exercicios',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _estatistica(
                  Icons.check_circle_outline,
                  'Acertos',
                  '$acertos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _estatistica(Icons.cancel_outlined, 'Erros', '$erros'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _estatistica(
                  Icons.local_fire_department,
                  'Sequência atual (dias)',
                  '$sequenciaDiasAtual',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _estatistica(Icons.track_changes, 'Precisão geral', '$precisao%'),
        ],
      ),
    );
  }

  Widget _estatistica(IconData icone, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icone, color: verde, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcaoPrincipal(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: preto,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icone, color: verde, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: preto,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcaoSecundaria(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return _buildOpcaoPrincipal(
      context,
      icone: icone,
      titulo: titulo,
      descricao: descricao,
      onTap: onTap,
    );
  }

  Widget _buildAtalho(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              Icon(icone, color: preto, size: 27),
              const SizedBox(height: 7),
              Text(
                titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: preto,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
