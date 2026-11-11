import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/guitar_sample_map.dart';
import '../utils/note_names.dart';

/// Braço de violão reutilizável para simuladores e exercícios.
class GuitarFretboard extends StatefulWidget {
  const GuitarFretboard({
    super.key,
    required this.onPositionPressed,
    this.showNoteNames = false,
    this.tipoNota = 'solfejo',
    this.activePosition,
  });

  final void Function(int corda, int casa, int midi) onPositionPressed;
  final bool showNoteNames;
  final String tipoNota;
  final (int, int)? activePosition;

  @override
  State<GuitarFretboard> createState() => _GuitarFretboardState();
}

class _GuitarFretboardState extends State<GuitarFretboard> {
  (int, int)? _lastInputPosition;

  void _handlePointer(Offset point, double width, double height) {
    final geometry = _FretboardGeometry(width, height);
    final fret = geometry.fretAt(point.dx);
    final string = geometry.stringAt(point.dy);
    if (fret == null ||
        string == null ||
        _lastInputPosition == (string, fret)) {
      return;
    }
    _lastInputPosition = (string, fret);
    widget.onPositionPressed(
      string,
      fret,
      GuitarSampleMap.openMidiNotes[string] + fret,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final boardWidth = math.max(constraints.maxWidth, 1040.0);
      final boardHeight = math.min(constraints.maxHeight, 390.0);
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
                onPointerDown: (event) => _handlePointer(
                  event.localPosition,
                  boardWidth,
                  boardHeight,
                ),
                onPointerMove: (event) => _handlePointer(
                  event.localPosition,
                  boardWidth,
                  boardHeight,
                ),
                onPointerUp: (_) => _lastInputPosition = null,
                onPointerCancel: (_) => _lastInputPosition = null,
                child: CustomPaint(
                  painter: _FretboardPainter(
                    showNoteNames: widget.showNoteNames,
                    active: widget.activePosition,
                    tuning: GuitarSampleMap.openMidiNotes,
                    noteNames: List.generate(12, (i) => _nome(i)),
                  ),
                  size: Size(boardWidth, boardHeight),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  String _nome(int classe) {
    return nomeNota(classe, widget.tipoNota).replaceAll('♯', '#');
  }
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

  // Paleta do braço: jacarandá escuro, trastes de níquel, pestana de osso e
  // cordas de aço (agudas) e bronze (graves, enroladas).
  static const _madeiraClara = Color(0xFF7A4A2E);
  static const _madeiraMedia = Color(0xFF5A3420);
  static const _madeiraEscura = Color(0xFF331C11);
  static const _filete = Color(0xFFE9DCC4);
  static const _osso = Color(0xFFF1E8D6);
  static const _aco = [Color(0xFF8E8A85), Color(0xFFFFFCF4), Color(0xFF77726C)];
  static const _bronze = [
    Color(0xFF8A6A3E),
    Color(0xFFF2D7A4),
    Color(0xFF7A5A30),
  ];

  double _centroCasa(_FretboardGeometry g, int fret) => fret == 0
      ? (g.left + g.fretX(1)) / 2
      : (g.fretX(fret) + g.fretX(fret + 1)) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final g = _FretboardGeometry(size.width, size.height);
    final topo = size.height * .14;
    final base = size.height * .86;
    final braco = Rect.fromLTRB(g.left, topo, g.fretX(13) + 26, base);

    _desenharCorpo(canvas, g, topo, base);

    // Sombra projetada do braço.
    canvas.drawRRect(
      RRect.fromRectAndRadius(braco.shift(const Offset(0, 9)), const Radius.circular(6)),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Escala de madeira com curvatura (mais clara no centro, escura nas bordas).
    canvas.drawRect(
      braco,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_madeiraEscura, _madeiraMedia, _madeiraClara, _madeiraMedia, _madeiraEscura],
          stops: [0, .18, .5, .82, 1],
        ).createShader(braco),
    );

    canvas.save();
    canvas.clipRect(braco);
    _desenharVeios(canvas, braco);
    canvas.restore();

    // Filetes claros nas bordas superior e inferior.
    final filete = Paint()
      ..color = _filete
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(braco.left, braco.top + 1), Offset(braco.right, braco.top + 1), filete);
    canvas.drawLine(Offset(braco.left, braco.bottom - 1), Offset(braco.right, braco.bottom - 1), filete);

    _desenharMarcacoes(canvas, g);
    _desenharTrastes(canvas, g, braco);
    _desenharPestana(canvas, g, braco);
    _desenharCordas(canvas, g, braco);
    _desenharRotulos(canvas, g, size, topo);
    if (showNoteNames) _desenharNomes(canvas, g);
    if (active != null) _desenharAtivo(canvas, g);
  }

  /// Borda do tampo e a boca do violão, à esquerda da pestana, como no mockup.
  void _desenharCorpo(Canvas canvas, _FretboardGeometry g, double topo, double base) {
    final centro = Offset(g.left - 6, (topo + base) / 2);
    final raio = (base - topo) * .95;
    final tampo = Rect.fromCircle(center: centro.translate(-raio * .55, 0), radius: raio);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, topo - 30, g.left + 2, base + 30));
    canvas.drawOval(
      tampo,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFD8A25E), Color(0xFFB57A3C), Color(0xFF7E4E24)],
          stops: [.2, .7, 1],
        ).createShader(tampo),
    );
    canvas.drawOval(
      tampo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xFF3D2414),
    );
    // Boca (furo) com roseta.
    final boca = Offset(tampo.center.dx + raio * .38, tampo.center.dy);
    canvas.drawCircle(boca, raio * .3, Paint()..color = const Color(0xFF120B07));
    canvas.drawCircle(
      boca,
      raio * .34,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF6B4122),
    );
    canvas.restore();
  }

  /// Veios da madeira gerados de forma determinística (mesmo desenho sempre).
  void _desenharVeios(Canvas canvas, Rect braco) {
    final aleatorio = math.Random(11);
    final veio = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 70; i++) {
      final y = braco.top + aleatorio.nextDouble() * braco.height;
      final amplitude = 1 + aleatorio.nextDouble() * 3;
      final fase = aleatorio.nextDouble() * math.pi * 2;
      final ondas = 2 + aleatorio.nextDouble() * 4;
      final caminho = Path()..moveTo(braco.left, y);
      for (var x = braco.left; x <= braco.right; x += 12) {
        final t = (x - braco.left) / braco.width;
        caminho.lineTo(x, y + math.sin(t * math.pi * ondas + fase) * amplitude);
      }
      final escuro = aleatorio.nextBool();
      veio
        ..strokeWidth = .6 + aleatorio.nextDouble() * 1.4
        ..color = escuro
            ? Color.fromRGBO(20, 9, 4, .18 + aleatorio.nextDouble() * .25)
            : Color.fromRGBO(196, 130, 82, .06 + aleatorio.nextDouble() * .12);
      canvas.drawPath(caminho, veio);
    }
    // Poros da madeira.
    final poro = Paint()..color = const Color(0x55120804);
    for (var i = 0; i < 260; i++) {
      final x = braco.left + aleatorio.nextDouble() * braco.width;
      final y = braco.top + aleatorio.nextDouble() * braco.height;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 2.6, height: .9),
        poro,
      );
    }
    // Brilho de verniz no meio da escala.
    canvas.drawRect(
      Rect.fromLTRB(braco.left, braco.center.dy - braco.height * .22, braco.right, braco.center.dy + braco.height * .22),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .05),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(braco),
    );
  }

  /// Marcações de madrepérola nas casas 3, 5, 7, 9 e 12 (dupla).
  void _desenharMarcacoes(Canvas canvas, _FretboardGeometry g) {
    final meio = (g.stringY(2) + g.stringY(3)) / 2;
    final distanciaDupla = (g.stringY(1) - g.stringY(0)) * .95;
    for (final fret in const [3, 5, 7, 9, 12]) {
      final x = _centroCasa(g, fret);
      final ys = fret == 12 ? [meio - distanciaDupla, meio + distanciaDupla] : [meio];
      for (final y in ys) {
        final centro = Offset(x, y);
        canvas.drawCircle(centro.translate(0, 1.5), 9, Paint()..color = const Color(0x66000000));
        canvas.drawCircle(
          centro,
          8.5,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.35, -.4),
              colors: [Color(0xFFFFFFFF), Color(0xFFEDE6F2), Color(0xFFD5E4EA), Color(0xFFBFB5A6)],
              stops: [0, .45, .75, 1],
            ).createShader(Rect.fromCircle(center: centro, radius: 8.5)),
        );
      }
    }
  }

  /// Trastes de níquel com volume (escuro–claro–escuro) e sombra à direita.
  void _desenharTrastes(Canvas canvas, _FretboardGeometry g, Rect braco) {
    for (var fret = 1; fret <= 13; fret++) {
      final x = g.fretX(fret);
      canvas.drawRect(
        Rect.fromLTRB(x + 1, braco.top, x + 5, braco.bottom),
        Paint()..color = const Color(0x66000000),
      );
      final traste = Rect.fromLTRB(x - 2.2, braco.top, x + 2.2, braco.bottom);
      canvas.drawRect(
        traste,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF6E6A66), Color(0xFFF5F2EC), Color(0xFFB9B4AD), Color(0xFF5D5955)],
            stops: [0, .35, .65, 1],
          ).createShader(traste),
      );
    }
  }

  /// Pestana de osso no início do braço.
  void _desenharPestana(Canvas canvas, _FretboardGeometry g, Rect braco) {
    final pestana = Rect.fromLTRB(g.left - 9, braco.top - 2, g.left + 3, braco.bottom + 2);
    canvas.drawRect(pestana.shift(const Offset(3, 0)), Paint()..color = const Color(0x77000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(pestana, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFCFC3AC), _osso, Color(0xFFD9CDB7)],
        ).createShader(pestana),
    );
  }

  /// Cordas: as três agudas lisas de aço e as três graves enroladas de bronze.
  void _desenharCordas(Canvas canvas, _FretboardGeometry g, Rect braco) {
    const espessuras = [1.3, 1.7, 2.2, 2.9, 3.6, 4.3];
    final inicio = g.left - 40;
    final fim = braco.right;
    for (var corda = 0; corda < 6; corda++) {
      final y = g.stringY(corda);
      final e = espessuras[corda];
      final enrolada = corda >= 3;
      // Sombra da corda sobre a madeira.
      canvas.drawLine(
        Offset(g.left, y + e + 2.5),
        Offset(fim, y + e + 2.5),
        Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = e
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
      final faixa = Rect.fromLTRB(inicio, y - e / 2, fim, y + e / 2);
      canvas.drawRect(
        faixa,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enrolada ? _bronze : _aco,
          ).createShader(faixa),
      );
      if (enrolada) {
        final espira = Paint()
          ..color = const Color(0x664A3418)
          ..strokeWidth = .9;
        for (var x = inicio; x < fim; x += e * .9) {
          canvas.drawLine(
            Offset(x, y - e / 2),
            Offset(x + e * .6, y + e / 2),
            espira,
          );
        }
      }
    }
  }

  /// Números das casas no topo e nomes das cordas soltas à esquerda.
  void _desenharRotulos(Canvas canvas, _FretboardGeometry g, Size size, double topo) {
    for (var fret = 0; fret <= 12; fret++) {
      final destaque = const [0, 3, 5, 7, 9, 12].contains(fret);
      _drawText(
        canvas,
        '$fret',
        Offset(_centroCasa(g, fret), topo * .45),
        TextStyle(
          color: destaque ? AppColors.text : AppColors.muted,
          fontSize: 14,
          fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
        ),
      );
    }
    for (var corda = 0; corda < 6; corda++) {
      final centro = Offset(g.left - 34, g.stringY(corda));
      final rotulo = noteNames[tuning[corda] % 12];
      final caixa = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centro, width: 40, height: 24),
        const Radius.circular(12),
      );
      canvas.drawRRect(caixa, Paint()..color = const Color(0xF0211C20));
      canvas.drawRRect(
        caixa,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFFBFB5A6),
      );
      _drawText(
        canvas,
        rotulo,
        centro,
        const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w700),
      );
    }
  }

  /// Nome de cada nota sobre a posição correspondente.
  void _desenharNomes(Canvas canvas, _FretboardGeometry g) {
    for (var corda = 0; corda < 6; corda++) {
      for (var fret = 1; fret <= 12; fret++) {
        final midi = tuning[corda] + fret;
        final centro = Offset(_centroCasa(g, fret), g.stringY(corda) - 11);
        final texto = noteNames[midi % 12];
        final largura = 10.0 + texto.length * 6.2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: centro, width: largura, height: 14),
            const Radius.circular(7),
          ),
          Paint()..color = const Color(0x99170F0B),
        );
        _drawText(
          canvas,
          texto,
          centro,
          const TextStyle(color: Color(0xFFFFE6BF), fontSize: 9.5, fontWeight: FontWeight.w700),
        );
      }
    }
  }

  /// Posição selecionada: esfera dourada com brilho, como no mockup.
  void _desenharAtivo(Canvas canvas, _FretboardGeometry g) {
    final centro = Offset(_centroCasa(g, active!.$2), g.stringY(active!.$1));
    canvas.drawCircle(
      centro,
      24,
      Paint()
        ..color = AppColors.primary.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      centro,
      14,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.35),
          colors: [Color(0xFFFFF3CF), AppColors.primary, Color(0xFFB07A2E)],
          stops: [0, .55, 1],
        ).createShader(Rect.fromCircle(center: centro, radius: 14)),
    );
    canvas.drawCircle(
      centro,
      14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFF5DF),
    );
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
      oldDelegate.tuning != tuning ||
      !_mesmaLista(oldDelegate.noteNames, noteNames);

  static bool _mesmaLista(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
