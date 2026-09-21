import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'keyboard_screen.dart';
import 'exercises_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> fazerLogout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<Map<String, dynamic>?> buscarDadosUsuario() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return null;
    }

    final documento = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .get();

    return documento.data();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1736),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1736),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Melody Hub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: fazerLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: buscarDadosUsuario(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF16D9C5),
              ),
            );
          }

          final dados = snapshot.data;

          final nome = dados?['nome'] ??
              usuario?.displayName ??
              'Aluno';

          final xp = dados?['xp'] ?? 0;
          final nivel = dados?['nivel'] ?? 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                // ==========================================
                // SAUDAÇÃO
                // ==========================================

                Text(
                  'Olá, $nome! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Vamos continuar sua jornada musical?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================================
                // CARD DE PROGRESSO
                // ==========================================

                Container(
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'Seu progresso',
                        style: TextStyle(
                          color: Color(0xFF0B1736),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [

                          Expanded(
                            child: _InfoCard(
                              icon: Icons.star,
                              titulo: 'XP',
                              valor: '$xp',
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _InfoCard(
                              icon: Icons.emoji_events,
                              titulo: 'Nível',
                              valor: '$nivel',
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // MÓDULO 2 — SIMULADOR DE TECLADO
                // ==========================================

                Container(
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: const Color(0xFF16D9C5),
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Icon(
                        Icons.piano,
                        color: Color(0xFF0B1736),
                        size: 40,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Simulador de teclado',
                        style: TextStyle(
                          color: Color(0xFF0B1736),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Pratique as notas musicais usando o teclado virtual.',
                        style: TextStyle(
                          color: Color(0xFF0B1736),
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        height: 48,

                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const KeyboardScreen(),
                              ),
                            );
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B1736),
                            foregroundColor: Colors.white,
                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          child: const Text(
                            'ABRIR TECLADO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // MÓDULO 3 — EXERCÍCIOS AUDITIVOS
                // ==========================================

                Container(
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Icon(
                        Icons.hearing,
                        color: Color(0xFF16D9C5),
                        size: 40,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Exercícios auditivos',
                        style: TextStyle(
                          color: Color(0xFF0B1736),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Treine sua percepção musical identificando notas pelo som.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        height: 48,

                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ExercisesScreen(),
                              ),
                            );
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B1736),
                            foregroundColor: Colors.white,
                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          child: const Text(
                            'INICIAR EXERCÍCIOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // AÇÕES
                // ==========================================

                Container(
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'Acesso rápido',
                        style: TextStyle(
                          color: Color(0xFF0B1736),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _MenuButton(
                        icon: Icons.history,
                        titulo: 'Histórico',

                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Histórico será implementado posteriormente.',
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _MenuButton(
                        icon: Icons.person_outline,
                        titulo: 'Meu perfil',

                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Perfil será implementado posteriormente.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ======================================================
// CARD DE INFORMAÇÃO
// ======================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;

  const _InfoCard({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color: const Color(0xFF16D9C5),
            size: 30,
          ),

          const SizedBox(height: 8),

          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF0B1736),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            titulo,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// BOTÃO DO MENU
// ======================================================

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.titulo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,

      child: OutlinedButton.icon(
        onPressed: onPressed,

        icon: Icon(
          icon,
          color: const Color(0xFF0B1736),
        ),

        label: Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF0B1736),
            fontWeight: FontWeight.bold,
          ),
        ),

        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFFE0E4EA),
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}