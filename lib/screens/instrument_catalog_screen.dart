import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'guitar_fretboard_screen.dart';
import 'keyboard_screen.dart';

class InstrumentCatalogScreen extends StatelessWidget {
  const InstrumentCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      title: const Text('Simuladores de instrumentos'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF382B31), Color(0xFF211C20)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33200F16),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
                SizedBox(height: 14),
                Text(
                  'Seu espaço para tocar',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Escolha um instrumento e explore as notas no seu ritmo.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'INSTRUMENTOS',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 12),
          _InstrumentCard(
            icon: Icons.piano_rounded,
            title: 'Teclado musical',
            detail: 'Piano virtual para tocar melodias e acordes.',
            tag: 'TECLADO',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KeyboardScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _InstrumentCard(
            icon: Icons.music_note_rounded,
            title: 'Braço de violão',
            detail:
                'Encontre notas nas seis cordas com som de violão de nylon.',
            tag: 'VIOLÃO',
            secondary: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuitarFretboardScreen()),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tag,
    required this.onTap,
    this.secondary = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String tag;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(23),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: secondary
                ? const [Color(0xFF30242A), AppColors.surface]
                : const [Color(0xFF302A24), AppColors.surface],
          ),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: (secondary ? AppColors.secondary : AppColors.primary)
                    .withValues(alpha: .13),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: secondary ? AppColors.secondary : AppColors.primary,
                size: 29,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      color: secondary
                          ? AppColors.secondary
                          : AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
