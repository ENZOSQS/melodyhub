import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/profile_icon_rewards.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const List<Map<String, dynamic>> _conquistas = [
    {
      'id': 'primeiro_exercicio',
      'titulo': 'Primeiro passo',
      'descricao': 'Responda seu primeiro exercício.',
      'icone': Icons.play_arrow_rounded,
    },
    {
      'id': 'dez_acertos',
      'titulo': 'Ouvido afiado',
      'descricao': 'Alcance 10 acertos.',
      'icone': Icons.hearing_rounded,
    },
    {
      'id': 'cinquenta_acertos',
      'titulo': 'Mestre da percepção',
      'descricao': 'Alcance 50 acertos.',
      'icone': Icons.music_note_rounded,
    },
    {
      'id': 'sequencia_cinco',
      'titulo': 'Em sequência',
      'descricao': 'Acerte 5 exercícios seguidos.',
      'icone': Icons.local_fire_department,
    },
    {
      'id': 'cinco_dias_estudados',
      'titulo': 'Hábito musical',
      'descricao': 'Estude em 5 dias diferentes seguidos.',
      'icone': Icons.calendar_month_rounded,
    },
    {
      'id': 'vinte_exercicios',
      'titulo': 'Prática constante',
      'descricao': 'Responda 20 exercícios.',
      'icone': Icons.library_music_rounded,
    },
    {
      'id': 'cem_exercicios',
      'titulo': 'Cem passos musicais',
      'descricao': 'Responda 100 exercícios.',
      'icone': Icons.stairs_rounded,
    },
    {
      'id': 'vinte_dias_estudados',
      'titulo': 'Música faz parte',
      'descricao': 'Estude em 20 dias diferentes seguidos.',
      'icone': Icons.event_available_rounded,
    },
    {
      'id': 'precisao_noventa',
      'titulo': 'Ouvido de precisão',
      'descricao': 'Mantenha pelo menos 90% de acerto em 20 questões teóricas.',
      'icone': Icons.gps_fixed_rounded,
    },
    {
      'id': 'teoria_intermediaria',
      'titulo': 'Teoria em movimento',
      'descricao': 'Avance para o nível intermediário de teoria.',
      'icone': Icons.menu_book_rounded,
    },
    {
      'id': 'teoria_avancada',
      'titulo': 'Mente harmônica',
      'descricao': 'Avance para o nível avançado de teoria.',
      'icone': Icons.auto_stories_rounded,
    },
    {
      'id': 'memoria_musical',
      'titulo': 'Memória musical',
      'descricao': 'Alcance o nível 3 nas sequências práticas.',
      'icone': Icons.hearing_rounded,
    },
    {
      'id': 'memoria_musical_mestre',
      'titulo': 'Mestre das sequências',
      'descricao': 'Alcance o nível máximo nas sequências práticas.',
      'icone': Icons.queue_music_rounded,
    },
    {
      'id': 'cem_exercicios_praticos',
      'titulo': 'Cem desafios práticos',
      'descricao': 'Complete 100 sequências práticas.',
      'icone': Icons.piano_rounded,
    },
    {
      'id': 'intervalista',
      'titulo': 'Caçador de intervalos',
      'descricao': 'Responda 10 desafios de percepção intervalar.',
      'icone': Icons.graphic_eq_rounded,
    },
    {
      'id': 'mestre_intervalos',
      'titulo': 'Mestre dos intervalos',
      'descricao': 'Complete 50 desafios de intervalos auditivos.',
      'icone': Icons.hearing_rounded,
    },
    {
      'id': 'ouvido_harmonico',
      'titulo': 'Ouvido harmônico',
      'descricao': 'Alcance o nível especialista em intervalos.',
      'icone': Icons.spatial_audio_rounded,
    },
    {
      'id': 'teoria_mestre',
      'titulo': 'Teórico especialista',
      'descricao': 'Avance até o último nível de teoria musical.',
      'icone': Icons.school_rounded,
    },
    {
      'id': 'primeiros_pontos',
      'titulo': 'Carteira musical',
      'descricao': 'Acumule 100 pontos na loja.',
      'icone': Icons.stars_rounded,
    },
    {
      'id': 'primeira_compra',
      'titulo': 'Primeira aquisição',
      'descricao': 'Compre seu primeiro ícone de perfil.',
      'icone': Icons.shopping_bag_rounded,
    },
    {
      'id': 'colecionador_icones',
      'titulo': 'Colecionador',
      'descricao': 'Compre todos os ícones disponíveis na loja.',
      'icone': Icons.collections_bookmark_rounded,
    },
    {
      'id': 'cem_xp',
      'titulo': 'Primeiros 100 XP',
      'descricao': 'Alcance 100 XP.',
      'icone': Icons.star_rounded,
    },
    {
      'id': 'quinhentos_xp',
      'titulo': 'Dedicação',
      'descricao': 'Alcance 500 XP.',
      'icone': Icons.workspace_premium,
    },
    {
      'id': 'nivel_cinco',
      'titulo': 'Nível máximo',
      'descricao': 'Alcance o nível 5.',
      'icone': Icons.emoji_events_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1020),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A1020),
          title: const Text('Conquistas'),
        ),
        body: const Center(
          child: Text(
            'Usuário não autenticado.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1020),
        elevation: 0,
        title: const Text(
          'Conquistas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final dados = snapshot.data?.data() ?? {};

          final conquistas = List<String>.from(dados['conquistas'] ?? []);

          final desbloqueadas = conquistas.length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121B2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Suas conquistas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$desbloqueadas de ${_conquistas.length} desbloqueadas',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ..._conquistas.map((conquista) {
                final id = conquista['id'] as String;
                final recompensas = allProfileIconRewards
                    .where((recompensa) => recompensa.achievementId == id)
                    .toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AchievementCard(
                    titulo: conquista['titulo'] as String,
                    descricao: conquista['descricao'] as String,
                    icone: conquista['icone'] as IconData,
                    desbloqueada: conquistas.contains(id),
                    recompensaPerfil: recompensas.isEmpty
                        ? null
                        : recompensas.first.name,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
