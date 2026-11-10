import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/utils/note_names.dart';

void main() {
  test('nomeNota aceita classes e MIDI nas duas nomenclaturas', () {
    expect(nomeNota(0, 'cifragem'), 'C');
    expect(nomeNota(61, 'cifragem'), 'C♯');
    expect(nomeNota(61, 'solfejo'), 'Dó♯');
    expect(nomeNota(71, 'solfejo'), 'Si');
    expect(nomeNota(12, 'cifragem'), 'C');
    expect(nomeNotaPorExtenso(1), 'Dó sustenido');
  });
}
