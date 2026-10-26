import 'package:flutter/material.dart';

/// Ícones temáticos; os arquivos de imagem podem ser adicionados depois.
class ProfileIconReward {
  const ProfileIconReward({
    required this.id,
    required this.name,
    required this.achievementId,
    required this.price,
    required this.fallbackIcon,
    this.assetPath,
  });

  final String id;
  final String name;
  final String achievementId;
  final int price;
  final IconData fallbackIcon;
  final String? assetPath;
}

const profileIconRewards = <ProfileIconReward>[
  ProfileIconReward(
    id: 'cartola_slash',
    name: 'Cartola do Slash',
    achievementId: 'memoria_musical',
    price: 120,
    fallbackIcon: Icons.theater_comedy_rounded,
  ),
  ProfileIconReward(
    id: 'microfone_freddie',
    name: 'Microfone de Freddie Mercury',
    achievementId: 'cinquenta_acertos',
    price: 180,
    fallbackIcon: Icons.mic_rounded,
  ),
  ProfileIconReward(
    id: 'oculos_elton',
    name: 'Óculos de Elton John',
    achievementId: 'teoria_intermediaria',
    price: 220,
    fallbackIcon: Icons.remove_red_eye_rounded,
  ),
  ProfileIconReward(
    id: 'bandana_hendrix',
    name: 'Bandana de Jimi Hendrix',
    achievementId: 'sequencia_cinco',
    price: 260,
    fallbackIcon: Icons.music_note_rounded,
  ),
  ProfileIconReward(
    id: 'luva_michael',
    name: 'Luva de Michael Jackson',
    achievementId: 'nivel_cinco',
    price: 320,
    fallbackIcon: Icons.back_hand_rounded,
  ),
  ProfileIconReward(
    id: 'guitarra_prince',
    name: 'Guitarra de Prince',
    achievementId: 'teoria_avancada',
    price: 380,
    fallbackIcon: Icons.electric_bolt_rounded,
  ),
  ProfileIconReward(
    id: 'baquetas_ringo',
    name: 'Baquetas de Ringo Starr',
    achievementId: 'cem_exercicios_praticos',
    price: 450,
    fallbackIcon: Icons.sports_baseball_rounded,
  ),
  ProfileIconReward(
    id: 'chapeu_pharrell',
    name: 'Chapéu de Pharrell Williams',
    achievementId: 'cem_xp',
    price: 520,
    fallbackIcon: Icons.face_rounded,
  ),
  ProfileIconReward(
    id: 'violao_bob',
    name: 'Violão de Bob Dylan',
    achievementId: 'intervalista',
    price: 650,
    fallbackIcon: Icons.queue_music_rounded,
  ),
  ProfileIconReward(
    id: 'capacete_daftpunk',
    name: 'Capacete de Daft Punk',
    achievementId: 'ouvido_harmonico',
    price: 800,
    fallbackIcon: Icons.headphones_rounded,
  ),
];
