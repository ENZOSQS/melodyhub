import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/widgets/guitar_fretboard.dart';

void main() {
  testWidgets('o braço ocupa a altura oferecida em paisagem 800×360', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 360,
            child: GuitarFretboard(onPositionPressed: (_, _, _) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paintedBoard = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter != null,
    );
    final boardHeight = tester.getSize(paintedBoard.last).height;
    expect(boardHeight, greaterThanOrEqualTo(360 * .85));
  });

  testWidgets('toque na quinta corda, casa três, informa MIDI 48', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tocadas = <(int, int, int)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 1040,
              height: 390,
              child: GuitarFretboard(
                onPositionPressed: (corda, casa, midi) {
                  tocadas.add((corda, casa, midi));
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listener = find.descendant(
      of: find.byType(GuitarFretboard),
      matching: find.byWidgetPredicate(
        (widget) => widget is Listener && widget.onPointerMove != null,
      ),
    );
    final bounds = tester.getRect(listener);
    final left = bounds.width * .075;
    final right = bounds.width * .94;
    double fretX(int fret) =>
        left +
        (right - left) *
            (1 - math.pow(2, -fret / 12).toDouble()) /
            (1 - math.pow(2, -13 / 12).toDouble());
    final x = (fretX(3) + fretX(4)) / 2;
    final y = bounds.height * .19 + (bounds.height * .62) * 4 / 5;

    await tester.tapAt(Offset(bounds.left + x, bounds.top + y));
    await tester.pump();

    expect(tocadas, [(4, 3, 48)]);
  });
}
