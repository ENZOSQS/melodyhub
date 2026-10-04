import 'package:flutter/material.dart';

class AchievementCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final bool desbloqueada;

  const AchievementCard({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.desbloqueada,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 250,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: desbloqueada
            ? const Color(0xFF17251C)
            : const Color(0xFF171717),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: desbloqueada
              ? const Color(0xFF35A85B)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: desbloqueada
                  ? const Color(0xFF35A85B)
                  : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              desbloqueada
                  ? icone
                  : Icons.lock_outline,
              color: desbloqueada
                  ? Colors.white
                  : Colors.white38,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: desbloqueada
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  descricao,
                  style: TextStyle(
                    color: desbloqueada
                        ? Colors.white70
                        : Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (desbloqueada)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF35A85B),
            ),
        ],
      ),
    );
  }
}