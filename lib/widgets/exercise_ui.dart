import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Peças visuais comuns dos exercícios auditivos: poucas informações na tela,
/// uma ação principal no centro e as respostas ao alcance do polegar.

const exerciseGreen = Color(0xFF3E9A5C);
const exerciseRed = Color(0xFF8E3A45);

/// Linha fina com a rodada (10 pontos), o nível, as estrelas e o combo.
class ExerciseStatusBar extends StatelessWidget {
  const ExerciseStatusBar({
    super.key,
    required this.level,
    required this.roundDone,
    required this.stars,
    this.combo = 0,
  });

  final int level;
  final int roundDone;
  final int stars;
  final int combo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
    child: Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(10, (index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: index < roundDone
                        ? AppColors.primary
                        : AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Nível $level',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(width: 10),
        Text('★ $stars', style: const TextStyle(color: AppColors.primary)),
        if (combo > 1) ...[
          const SizedBox(width: 8),
          Text(
            '🔥 $combo',
            style: const TextStyle(color: AppColors.secondary),
          ),
        ],
      ],
    ),
  );
}

/// Pergunta curta, numa linha só.
class ExerciseQuestion extends StatelessWidget {
  const ExerciseQuestion(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ],
    ],
  );
}

/// Botão grande e redondo de ouvir/repetir, no centro da tela.
class ExercisePlayButton extends StatelessWidget {
  const ExercisePlayButton({
    super.key,
    required this.playing,
    required this.onTap,
    this.onLongPress,
    this.label = 'Repetir',
    this.icon = Icons.replay_rounded,
    this.size = 132,
  });

  final bool playing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String label;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: playing ? AppColors.secondary : AppColors.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: playing ? 0.22 : 0.08),
              blurRadius: 26,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              playing ? Icons.graphic_eq_rounded : icon,
              color: AppColors.primary,
              size: size * 0.3,
            ),
            const SizedBox(height: 5),
            Text(
              playing ? 'Ouvindo' : label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

enum AnswerState { normal, wrong, correct }

/// Botão de resposta em formato de pílula. Treme quando [shakeToken] muda.
class AnswerPill extends StatelessWidget {
  const AnswerPill({
    super.key,
    required this.label,
    required this.state,
    required this.enabled,
    required this.onTap,
    this.onLongPress,
    this.shakeToken = 0,
    this.shaking = false,
    this.minWidth = 136,
    this.height = 56,
    this.icon,
  });

  final String label;
  final AnswerState state;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int shakeToken;
  final bool shaking;
  final double minWidth;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      AnswerState.correct => exerciseGreen,
      AnswerState.wrong => exerciseRed,
      AnswerState.normal => AppColors.surfaceRaised,
    };
    return TweenAnimationBuilder<double>(
      key: ValueKey('shake-$label-$shakeToken'),
      tween: Tween(begin: 0, end: shaking ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(math.sin(value * math.pi * 6) * 6 * (1 - value), 0),
        child: child,
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: state == AnswerState.correct ? 1.06 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: state == AnswerState.wrong ? 0.45 : 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
            child: Material(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(height / 2),
                onTap: enabled && state != AnswerState.wrong ? onTap : null,
                onLongPress: enabled ? onLongPress : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    height: height,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: AppColors.text),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha de retorno curta (acerto, erro ou dica de comparação).
class ExerciseFeedbackLine extends StatelessWidget {
  const ExerciseFeedbackLine(this.text, {super.key, this.positive});

  final String? text;
  final bool? positive;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: text == null
        ? const SizedBox(height: 24)
        : Padding(
            key: ValueKey(text),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              text!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: positive == null
                    ? AppColors.muted
                    : positive!
                    ? const Color(0xFF8FD99A)
                    : const Color(0xFFFF9AA9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
  );
}

/// Resumo ao fim de uma rodada de 10 questões.
Future<bool?> showRoundSummary(
  BuildContext context, {
  required int stars,
  required int correct,
  required int total,
}) => showModalBottomSheet<bool>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: AppColors.surface,
  builder: (context) {
    final ratio = total == 0 ? 0.0 : correct / total;
    final message = ratio >= 0.9
        ? 'Excelente! Seu ouvido está afiado.'
        : ratio >= 0.7
        ? 'Muito bem! Continue assim.'
        : 'Bom treino! Repetir é o que treina o ouvido.';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '★ $stars',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 40,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$correct de $total acertos',
              style: const TextStyle(color: AppColors.text, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Próxima rodada'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
