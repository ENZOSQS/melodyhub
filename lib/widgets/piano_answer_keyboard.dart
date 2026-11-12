import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/note_names.dart';

/// One-octave piano used as an actual answer surface in listening exercises.
class PianoAnswerKeyboard extends StatelessWidget {
  const PianoAnswerKeyboard({
    super.key,
    required this.onNotePressed,
    this.firstMidi = 48,
    this.noteCount = 13,
    this.selectedMidi = const <int>{},
    this.enabledMidis,
    this.feedbackColors = const <int, Color>{},
    this.enabled = true,
    this.showLabels = true,
    this.tipoNota = 'solfejo',
  });

  final ValueChanged<int> onNotePressed;
  final int firstMidi;
  final int noteCount;
  final Set<int> selectedMidi;
  final Set<int>? enabledMidis;
  final Map<int, Color> feedbackColors;
  final bool enabled;
  final bool showLabels;
  final String tipoNota;

  static const _whiteClasses = <int>{0, 2, 4, 5, 7, 9, 11};
  static const _blackAfterWhite = <int, int>{0: 1, 1: 3, 3: 6, 4: 8, 5: 10};

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final whiteMidis = List<int>.generate(
        noteCount,
        (i) => firstMidi + i,
      ).where((midi) => _whiteClasses.contains(midi % 12)).toList();
      final whiteWidth = constraints.maxWidth / whiteMidis.length;
      final blackWidth = whiteWidth * .58;
      final blackMidis = List<int>.generate(
        noteCount,
        (i) => firstMidi + i,
      ).where((midi) => _blackAfterWhite.values.contains(midi % 12)).toList();

      return SizedBox(
        height: 196,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final midi in whiteMidis) _buildWhiteKey(midi)],
            ),
            for (final midi in blackMidis)
              if (_whiteMidisBefore(midi) >= 0)
                _buildBlackKey(midi, blackWidth, whiteWidth),
          ],
        ),
      );
    },
  );

  Widget _buildWhiteKey(int midi) {
    final enabledKey = enabled && (enabledMidis?.contains(midi) ?? true);
    final feedbackColor = feedbackColors[midi];
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabledKey ? () => onNotePressed(midi) : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabledKey ? 1 : .3,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: feedbackColor,
              gradient: feedbackColor == null
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: selectedMidi.contains(midi)
                          ? const [Color(0xFFFFE3A8), Color(0xFFF2C574)]
                          : const [Color(0xFFE6DDD6), Color(0xFFFBF5F0)],
                    )
                  : null,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              border: Border.all(color: const Color(0xFFB7AA9B)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 3,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 14),
            child: showLabels
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      nomeNota(midi, tipoNota),
                      style: const TextStyle(
                        color: Color(0xFF231C1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBlackKey(int midi, double blackWidth, double whiteWidth) {
    final enabledKey = enabled && (enabledMidis?.contains(midi) ?? true);
    final feedbackColor = feedbackColors[midi];
    return Positioned(
      left: (_whiteMidisBefore(midi) + 1) * whiteWidth - blackWidth / 2,
      width: blackWidth,
      height: 120,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabledKey ? () => onNotePressed(midi) : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabledKey ? 1 : .3,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: feedbackColor,
              gradient: feedbackColor == null
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: selectedMidi.contains(midi)
                          ? const [Color(0xFFF2C574), AppColors.primary]
                          : const [Color(0xFF0F0C0D), Color(0xFF3A3135)],
                    )
                  : null,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              border: Border.all(color: const Color(0xFF120F11)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x77000000),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 6),
            child: showLabels
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      nomeNota(midi, tipoNota),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  int _whiteMidisBefore(int midi) {
    var count = 0;
    for (var current = firstMidi; current < midi; current++) {
      if (_whiteClasses.contains(current % 12)) count++;
    }
    return count - 1;
  }
}
