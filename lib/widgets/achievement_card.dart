import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AchievementCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final bool desbloqueada;
  final String? recompensaPerfil;

  const AchievementCard({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.desbloqueada,
    this.recompensaPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: desbloqueada ? AppColors.surfaceRaised : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: desbloqueada ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: desbloqueada
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              desbloqueada ? icone : Icons.lock_outline,
              color: desbloqueada ? AppColors.primary : AppColors.muted,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: desbloqueada ? AppColors.text : AppColors.muted,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  descricao,
                  style: TextStyle(
                    color: desbloqueada ? Colors.white70 : Colors.white38,
                    fontSize: 13,
                  ),
                ),
                if (recompensaPerfil != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 15,
                        color: desbloqueada
                            ? const Color(0xFF16D9C5)
                            : Colors.white38,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Ícone de perfil: $recompensaPerfil',
                          style: TextStyle(
                            color: desbloqueada
                                ? AppColors.primary
                                : AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (desbloqueada)
            const Icon(Icons.check_circle, color: AppColors.primary),
        ],
      ),
    );
  }
}
