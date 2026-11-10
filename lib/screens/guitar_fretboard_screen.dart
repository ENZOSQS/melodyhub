import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/music_audio_service.dart';
import '../services/app_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/guitar_sample_map.dart';
import '../utils/note_names.dart';

class GuitarFretboardScreen extends StatefulWidget {
  const GuitarFretboardScreen({super.key});
  @override
  State<GuitarFretboardScreen> createState() => _GuitarFretboardScreenState();
}

class _GuitarFretboardScreenState extends State<GuitarFretboardScreen> {
  static const _tuning = GuitarSampleMap.openMidiNotes;
  static const _strings = ['Mi aguda', 'Si', 'Sol', 'Ré', 'Lá', 'Mi grave'];

  final _audio = MusicAudioService.instance;
  int? _lastMidi;
  (int, int)? _lastPosition;
  (int, int)? _lastInputPosition;
  bool _loading = true;
  bool _showNoteNames = false;
  String _tipoNota = 'solfejo';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _tipoNota = await AppPreferences.noteType();
    } catch (_) {
      _tipoNota = 'solfejo';
    }
    try {
      await _audio.preload([...GuitarSampleMap.fretboardAssets]);
    } catch (error) {
      debugPrint('Não foi possível carregar os samples de violão: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar o áudio do violão.'),
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _play(int string, int fret) async {
    final midi = _tuning[string] + fret;
    if (_lastInputPosition == (string, fret)) return;
    setState(() {
      _lastMidi = midi;
      _lastPosition = (string, fret);
      _lastInputPosition = (string, fret);
    });
    try {
      await _audio.playFor(
        GuitarSampleMap.forPosition(string, fret),
        const Duration(milliseconds: 1900),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível reproduzir essa nota.'),
          ),
        );
      }
    }
  }

  void _handleBoardPointer(Offset point, double width, double height) {
    final geometry = _FretboardGeometry(width, height);
    final fret = geometry.fretAt(point.dx);
    final string = geometry.stringAt(point.dy);
    if (fret != null && string != null) unawaited(_play(string, fret));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      title: const Text('Braço de violão'),
      actions: [
        TextButton.icon(
          onPressed: () => setState(() => _showNoteNames = !_showNoteNames),
          icon: Icon(_showNoteNames ? Icons.visibility_off : Icons.visibility),
          label: Text(_showNoteNames ? 'Ocultar notas' : 'Ver notas'),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34251F), Color(0xFF211A19)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toque uma corda entre os trastes ou arraste para passear pelo braço.',
                          style: TextStyle(color: AppColors.text, height: 1.4),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Afinação padrão · E A D G B E${_showNoteNames ? ' · Nomes das notas ativados' : ''}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        if (_lastMidi != null) ...[
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            child: Text(
                              key: ValueKey(_lastMidi),
                              '${nomeNota(_lastMidi!, _tipoNota)} · ${_lastMidi! ~/ 12 - 1}ª oitava  ·  ${_strings[_lastPosition!.$1]} / casa ${_lastPosition!.$2}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 5),
                  child: Text(
                    '6 CORDAS  ·  CASAS 0–12',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardWidth = math.max(constraints.maxWidth, 1040.0);
                      final boardHeight = math.min(
                        constraints.maxHeight,
                        390.0,
                      );
                      return Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: boardWidth,
                            height: boardHeight,
                            child: Semantics(
                              label:
                                  'Braço de violão tocável, seis cordas e casas de zero a doze',
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (event) => _handleBoardPointer(
                                  event.localPosition,
                                  boardWidth,
                                  boardHeight,
                                ),
                                onPointerMove: (event) => _handleBoardPointer(
                                  event.localPosition,
                                  boardWidth,
                                  boardHeight,
                                ),
                                onPointerUp: (_) => _lastInputPosition = null,
                                onPointerCancel: (_) =>
                                    _lastInputPosition = null,
                                child: CustomPaint(
                                  painter: _FretboardPainter(
                                    showNoteNames: _showNoteNames,
                                    active: _lastPosition,
                                    tuning: _tuning,
                                    noteNames: List.generate(
                                      12,
                                      (index) => nomeNota(index, _tipoNota),
                                    ),
                                  ),
                                  size: Size(boardWidth, boardHeight),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 7, 16, 13),
                  child: Text(
                    'Arraste horizontalmente para alcançar as demais casas. Cada casa reduz o comprimento vibrante da corda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}

class _FretboardGeometry {
  _FretboardGeometry(this.width, this.height);
  final double width;
  final double height;

  double get left => width * .075;
  double get right => width * .94;
  double fretX(int fret) =>
      left +
      (right - left) *
          (1 - math.pow(2, -fret / 12).toDouble()) /
          (1 - math.pow(2, -13 / 12).toDouble());
  double stringY(int string) => height * .19 + (height * .62) * string / 5;

  int? fretAt(double x) {
    if (x < left || x > fretX(13)) return null;
    for (var fret = 0; fret <= 12; fret++) {
      if (x >= fretX(fret) && x < fretX(fret + 1)) return fret;
    }
    return null;
  }

  int? stringAt(double y) {
    if (y < stringY(0) - 16 || y > stringY(5) + 16) return null;
    return ((y - stringY(0)) / (stringY(5) - stringY(0)) * 5).round().clamp(
      0,
      5,
    );
  }
}

class _FretboardPainter extends CustomPainter {
  const _FretboardPainter({
    required this.showNoteNames,
    required this.active,
    required this.tuning,
    required this.noteNames,
  });

  final bool showNoteNames;
  final (int, int)? active;
  final List<int> tuning;
  final List<String> noteNames;

  @override
  void paint(Canvas canvas, Size size) {
    final g = _FretboardGeometry(size.width, size.height);
    final board = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        g.left - 30,
        size.height * .105,
        g.right + 18,
        size.height * .90,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      board.shift(const Offset(0, 10)),
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      board,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF915936), Color(0xFF593720), Color(0xFF322219)],
        ).createShader(board.outerRect),
    );
    canvas.save();
    canvas.clipRRect(board);
    final grain = Paint()..strokeWidth = 1;
    for (var i = 0; i < 32; i++) {
      final y = size.height * (.12 + i * .024);
      grain.color = (i.isEven
          ? const Color(0x22F4C08A)
          : const Color(0x1C180D0A));
      canvas.drawLine(
        Offset(g.left - 25, y),
        Offset(g.right + 16, y + 2),
        grain,
      );
    }

    // Fret positions use the equal-tempered spacing law, not square key cells.
    for (var fret = 0; fret <= 13; fret++) {
      final x = g.fretX(fret);
      canvas.drawLine(
        Offset(x + 2, size.height * .16),
        Offset(x + 2, size.height * .84),
        Paint()
          ..color = const Color(0x880E0A08)
          ..strokeWidth = fret == 0 ? 8 : 5,
      );
      canvas.drawLine(
        Offset(x, size.height * .16),
        Offset(x, size.height * .84),
        Paint()
          ..color = fret == 0
              ? const Color(0xFFE0D8C8)
              : const Color(0xFFC3BBAF)
          ..strokeWidth = fret == 0 ? 7 : 3.5,
      );
      canvas.drawLine(
        Offset(x - 1.2, size.height * .16),
        Offset(x - 1.2, size.height * .84),
        Paint()
          ..color = const Color(0x99FFFFFF)
          ..strokeWidth = 0.8,
      );
    }

    // Mother-of-pearl position markers between strings 2 and 5.
    final middle = (g.stringY(2) + g.stringY(3)) / 2;
    for (final fret in [3, 5, 7, 9, 12]) {
      final x = (g.fretX(fret) + g.fretX(fret + 1)) / 2;
      final positions = fret == 12 ? [middle - 13, middle + 13] : [middle];
      for (final y in positions) {
        canvas.drawCircle(
          Offset(x, y),
          8,
          Paint()..color = const Color(0x6634161A),
        );
        canvas.drawCircle(
          Offset(x, y),
          6,
          Paint()
            ..shader = const RadialGradient(
              colors: [Color(0xFFF8E5C0), Color(0xFFB7A17A)],
            ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 6)),
        );
      }
    }

    // Six real-looking metal strings of progressively different gauges.
    for (var string = 0; string < 6; string++) {
      final y = g.stringY(string);
      final thickness = const [1.0, 1.2, 1.45, 1.8, 2.25, 2.8][string];
      canvas.drawLine(
        Offset(g.left - 22, y + 2),
        Offset(g.right + 14, y + 2),
        Paint()
          ..color = const Color(0x770E0B09)
          ..strokeWidth = thickness + 1.4,
      );
      canvas.drawLine(
        Offset(g.left - 22, y),
        Offset(g.right + 14, y),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF77706A), Color(0xFFFFF8E9), Color(0xFF827B73)],
          ).createShader(Rect.fromLTRB(g.left, y, g.right, y + 1))
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round,
      );
    }

    // Nut, open-position fret labels, and unobtrusive string names.
    for (var fret = 0; fret <= 12; fret++) {
      final x = fret == 0
          ? (g.left + g.fretX(1)) / 2
          : (g.fretX(fret) + g.fretX(fret + 1)) / 2;
      _drawText(
        canvas,
        fret == 0 ? '0' : '$fret',
        Offset(x, size.height * .115),
        const TextStyle(
          color: Color(0xFFD9C8AE),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    const stringLabels = ['e', 'B', 'G', 'D', 'A', 'E'];
    for (var string = 0; string < 6; string++) {
      _drawText(
        canvas,
        stringLabels[string],
        Offset(g.left - 22, g.stringY(string)),
        const TextStyle(
          color: Color(0xFFFFE4C5),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    if (showNoteNames) {
      for (var string = 0; string < 6; string++) {
        for (var fret = 0; fret <= 12; fret++) {
          final midi = tuning[string] + fret;
          final x = fret == 0
              ? (g.left + g.fretX(1)) / 2
              : (g.fretX(fret) + g.fretX(fret + 1)) / 2;
          final y = g.stringY(string);
          final label = noteNames[midi % 12].replaceAll('♯', '#');
          _drawText(
            canvas,
            label,
            Offset(x, y - 13),
            const TextStyle(
              color: Color(0xFFFFE6BF),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          );
        }
      }
    }

    if (active != null) {
      final string = active!.$1;
      final fret = active!.$2;
      final x = fret == 0
          ? (g.left + g.fretX(1)) / 2
          : (g.fretX(fret) + g.fretX(fret + 1)) / 2;
      final y = g.stringY(string);
      canvas.drawCircle(
        Offset(x, y),
        17,
        Paint()..color = const Color(0x66F0B86F),
      );
      canvas.drawCircle(
        Offset(x, y),
        10,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        10,
        Paint()
          ..color = const Color(0xFFFFF5DF)
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FretboardPainter oldDelegate) =>
      oldDelegate.showNoteNames != showNoteNames ||
      oldDelegate.active != active ||
      oldDelegate.tuning != tuning;
}
