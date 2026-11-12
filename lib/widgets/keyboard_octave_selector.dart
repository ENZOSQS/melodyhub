import 'package:flutter/material.dart';

/// Seletor da extensão do teclado, limitado a uma até quatro oitavas.
class KeyboardOctaveSelector extends StatelessWidget {
  const KeyboardOctaveSelector({
    super.key,
    required this.octaveCount,
    required this.onChanged,
    this.compact = false,
  });

  final int octaveCount;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disabledColor = Colors.white24;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '−',
          onPressed: octaveCount <= 1 ? null : () => onChanged(octaveCount - 1),
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints.tightFor(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
          ),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFFE9B96E),
            backgroundColor: const Color(0xFF211C20),
            disabledForegroundColor: disabledColor,
          ),
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
          child: Semantics(
            container: true,
            label:
                '$octaveCount ${octaveCount == 1 ? 'oitava' : 'oitavas'} · ${octaveCount * 7} teclas brancas',
            child: ExcludeSemantics(
              child: Text(
                '$octaveCount ${octaveCount == 1 ? 'oitava' : 'oitavas'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: '+',
          onPressed: octaveCount >= 4 ? null : () => onChanged(octaveCount + 1),
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints.tightFor(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
          ),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFFE9B96E),
            backgroundColor: const Color(0xFF211C20),
            disabledForegroundColor: disabledColor,
          ),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
