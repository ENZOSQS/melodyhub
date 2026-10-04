import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/achievement_card.dart';

class AchievementsScreen
    extends StatelessWidget {
  const AchievementsScreen({
    super.key,
  });

  static const List<Map<String, dynamic>>
      _conquistas = [
    {
      'id': 'primeiro_exercicio',
      'titulo': 'Primeiro passo',
      'descricao':
          'Responda seu primeiro exercício.',
      'icone': Icons.play_arrow_rounded,
    },
    {
      'id': 'dez_acertos',
      'titulo': 'Ouvido afiado',
      'descricao':
          'Alcance 10 acertos.',
      'icone': Icons.hearing_rounded,
    },
    {
      'id': 'cinquenta_acertos',
      'titulo': 'Mestre da percepção',
      'descricao':
          'Alcance 50 acertos.',
      'icone': Icons.music_note_rounded,
    },
    {
      'id': 'sequencia_cinco',
      'titulo': 'Em sequência',
      'descricao':
          'Acerte 5 exercícios seguidos.',
      'icone': Icons.local_fire_department,
    },
    {
      'id': 'cem_xp',
      'titulo': 'Primeiros 100 XP',
      'descricao':
          'Alcance 100 XP.',
      'icone': Icons.star_rounded,
    },
    {
      'id': 'quinhentos_xp',
      'titulo': 'Dedicação',
      'descricao':
          'Alcance 500 XP.',
      'icone': Icons.workspace_premium,
    },
    {
      'id': 'nivel_cinco',
      'titulo': 'Nível máximo',
      'descricao':
          'Alcance o nível 5.',
      'icone': Icons.emoji_events_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final usuario =
        FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return Scaffold(
        backgroundColor:
            const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor:
              const Color(0xFF0D0D0D),
          title:
              const Text('Conquistas'),
        ),
        body: const Center(
          child: Text(
            'Usuário não autenticado.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text(
          'Conquistas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
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

          final conquistas =
              List<String>.from(
            dados['conquistas'] ?? [],
          );

          final desbloqueadas =
              conquistas.length;

          return ListView(
            padding:
                const EdgeInsets.all(20),
            children: [
              Container(
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF151515),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFF35A85B),
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons.emoji_events,
                        color:
                            Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Suas conquistas',
                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            '$desbloqueadas de ${_conquistas.length} desbloqueadas',
                            style:
                                const TextStyle(
                              color: Colors
                                  .white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              ..._conquistas.map(
                (conquista) {
                  final id =
                      conquista['id']
                          as String;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child:
                        AchievementCard(
                      titulo:
                          conquista['titulo']
                              as String,
                      descricao:
                          conquista[
                              'descricao'] as String,
                      icone:
                          conquista['icone']
                              as IconData,
                      desbloqueada:
                          conquistas
                              .contains(id),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}