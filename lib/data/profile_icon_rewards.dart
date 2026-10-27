import 'package:flutter/material.dart';

/// Ícones atualmente disponíveis para compra na loja.
class ProfileIconReward {
  const ProfileIconReward({
    required this.id,
    required this.name,
    this.achievementId,
    required this.price,
    required this.fallbackIcon,
    this.assetPath,
    this.artist = 'Melody Hub',
    this.description = 'Ícone musical para personalizar seu perfil.',
    this.rarity = 'Comum',
    this.category = 'Acessório',
  });

  final String id;
  final String name;
  final String? achievementId;
  final int price;
  final IconData fallbackIcon;
  final String? assetPath;
  final String artist;
  final String description;
  final String rarity;
  final String category;
}

const profileIconRewards = <ProfileIconReward>[
  ProfileIconReward(
    id: 'slash_hat',
    name: 'Cartola do Slash',
    artist: 'Slash',
    description: 'Cartola preta com óculos escuros e detalhes metálicos.',
    assetPath: 'assets/icons/music/slash_hat.png',
    price: 150,
    rarity: 'Épico',
    category: 'Acessório',
    fallbackIcon: Icons.theater_comedy_rounded,
  ),
  ProfileIconReward(
    id: 'freddie_microphone',
    name: 'Microfone do Freddie Mercury',
    artist: 'Freddie Mercury',
    description: 'Microfone vintage prateado com uma pequena coroa dourada.',
    assetPath: 'assets/icons/music/freddie_microphone.png',
    price: 110,
    rarity: 'Raro',
    category: 'Microfone',
    fallbackIcon: Icons.mic_rounded,
  ),
  ProfileIconReward(
    id: 'ozzy_sunglasses',
    name: 'Óculos do Ozzy',
    artist: 'Ozzy Osbourne',
    description: 'Óculos redondos com lentes escuras e armação metálica.',
    assetPath: 'assets/icons/music/ozzy_sunglasses.png',
    price: 75,
    rarity: 'Incomum',
    category: 'Acessório',
    fallbackIcon: Icons.remove_red_eye_rounded,
  ),
  ProfileIconReward(
    id: 'elton_piano',
    name: 'Piano do Elton John',
    artist: 'Elton John',
    description: 'Piano de cauda colorido com detalhes artísticos vibrantes.',
    assetPath: 'assets/icons/music/elton_piano.png',
    price: 110,
    rarity: 'Raro',
    category: 'Instrumento',
    fallbackIcon: Icons.piano_rounded,
  ),
  ProfileIconReward(
    id: 'hendrix_guitar',
    name: 'Guitarra do Jimi Hendrix',
    artist: 'Jimi Hendrix',
    description: 'Guitarra elétrica vermelha com desenhos coloridos.',
    assetPath: 'assets/icons/music/hendrix_guitar.png',
    price: 110,
    rarity: 'Raro',
    category: 'Instrumento',
    fallbackIcon: Icons.music_note_rounded,
  ),
  ProfileIconReward(
    id: 'michael_glove',
    name: 'Luva do Michael Jackson',
    artist: 'Michael Jackson',
    description: 'Luva branca coberta por detalhes brilhantes.',
    assetPath: 'assets/icons/music/michael_glove.png',
    price: 150,
    rarity: 'Épico',
    category: 'Acessório',
    fallbackIcon: Icons.back_hand_rounded,
  ),
  ProfileIconReward(
    id: 'daft_punk_helmet',
    name: 'Capacete do Daft Punk',
    artist: 'Daft Punk',
    description: 'Capacete robótico futurista dourado e preto.',
    assetPath: 'assets/icons/music/daft_punk_helmet.png',
    price: 200,
    rarity: 'Lendário',
    category: 'Acessório',
    fallbackIcon: Icons.headphones_rounded,
  ),
  ProfileIconReward(
    id: 'tenacious_d_axe_guitar',
    name: 'Guitarra-Machado',
    artist: 'Tenacious D',
    description: 'Guitarra vermelha em formato de machado, item cosmético.',
    assetPath: 'assets/icons/music/tenacious_d_axe_guitar.png',
    price: 75,
    rarity: 'Incomum',
    category: 'Instrumento',
    fallbackIcon: Icons.music_note_rounded,
  ),
  ProfileIconReward(
    id: 'rita_lee_microphone',
    name: 'Microfone da Rita Lee',
    artist: 'Rita Lee',
    description: 'Microfone decorado com detalhes coloridos e pluma rosa.',
    assetPath: 'assets/icons/music/rita_lee_microphone.png',
    price: 75,
    rarity: 'Incomum',
    category: 'Microfone',
    fallbackIcon: Icons.mic_rounded,
  ),
  ProfileIconReward(
    id: 'renato_russo_guitar',
    name: 'Violão do Renato Russo',
    artist: 'Renato Russo',
    description: 'Violão de madeira com símbolo da paz.',
    assetPath: 'assets/icons/music/renato_russo_guitar.png',
    price: 50,
    rarity: 'Comum',
    category: 'Instrumento',
    fallbackIcon: Icons.music_note_rounded,
  ),
  ProfileIconReward(
    id: 'raul_seixas_hat',
    name: 'Chapéu do Raul Seixas',
    artist: 'Raul Seixas',
    description: 'Chapéu preto com faixa decorada, estrela e pingente da paz.',
    assetPath: 'assets/icons/music/raul_seixas_hat.png',
    price: 75,
    rarity: 'Incomum',
    category: 'Acessório',
    fallbackIcon: Icons.theater_comedy_rounded,
  ),
  ProfileIconReward(
    id: 'joao_gilberto_percussion',
    name: 'Ritmo da Bossa Nova',
    artist: 'Homenagem à bossa nova',
    description:
        'Pequeno instrumento de percussão em homenagem à música brasileira.',
    assetPath: 'assets/icons/music/joao_gilberto_percussion.png',
    price: 50,
    rarity: 'Comum',
    category: 'Instrumento',
    fallbackIcon: Icons.album_rounded,
  ),
  ProfileIconReward(
    id: 'tom_jobim_sheet_music',
    name: 'Partitura do Tom Jobim',
    artist: 'Tom Jobim',
    description:
        'Partitura ilustrada em homenagem à composição e à bossa nova.',
    assetPath: 'assets/icons/music/tom_jobim_sheet_music.png',
    price: 50,
    rarity: 'Comum',
    category: 'Partitura',
    fallbackIcon: Icons.library_music_rounded,
  ),
  ProfileIconReward(
    id: 'chorao_guitar',
    name: 'Guitarra do Chorão',
    artist: 'Chorão',
    description:
        'Guitarra escura com detalhes gráficos e acabamento desgastado.',
    assetPath: 'assets/icons/music/chorao_guitar.png',
    price: 110,
    rarity: 'Raro',
    category: 'Instrumento',
    fallbackIcon: Icons.music_note_rounded,
  ),
  ProfileIconReward(
    id: 'tim_maia_keyboard',
    name: 'Teclado do Tim Maia',
    artist: 'Tim Maia',
    description: 'Teclado musical de madeira com teclas pretas e brancas.',
    assetPath: 'assets/icons/music/tim_maia_keyboard.png',
    price: 110,
    rarity: 'Raro',
    category: 'Instrumento',
    fallbackIcon: Icons.piano_rounded,
  ),
];

/// Recompensas antigas mantidas para não invalidar desbloqueios já salvos.
const legacyProfileIconRewards = <ProfileIconReward>[
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

const allProfileIconRewards = <ProfileIconReward>[
  ...profileIconRewards,
  ...legacyProfileIconRewards,
];
