import 'package:flutter/material.dart';

import '../data/theory_explanations.dart';
import '../theme/app_theme.dart';

Future<void> showTheoryExplanationSheet(
  BuildContext context, {
  required TheoryExplanation explanation,
  required String theory,
  Future<void> Function()? onPlayExample,
  String? exampleLabel,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Entenda a teoria',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const Text('O que você está aprendendo', style: _heading),
          const SizedBox(height: 5),
          Text(explanation.objective, style: _body),
          const SizedBox(height: 16),
          const Text('Teoria', style: _heading),
          const SizedBox(height: 5),
          Text(theory, style: _body),
          if (explanation.song != null) ...[
            const SizedBox(height: 16),
            const Text('Dica para lembrar', style: _heading),
            const SizedBox(height: 5),
            Text(explanation.song!, style: _body),
          ],
          if (onPlayExample != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPlayExample,
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(exampleLabel ?? 'Ouvir exemplo'),
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);

const _heading = TextStyle(
  color: AppColors.primary,
  fontWeight: FontWeight.w800,
  fontSize: 15,
);

const _body = TextStyle(color: AppColors.text, height: 1.5);
