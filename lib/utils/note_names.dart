const List<String> _cifra = [
  'C',
  'C♯',
  'D',
  'D♯',
  'E',
  'F',
  'F♯',
  'G',
  'G♯',
  'A',
  'A♯',
  'B',
];

const List<String> _solfejo = [
  'Dó',
  'Dó♯',
  'Ré',
  'Ré♯',
  'Mi',
  'Fá',
  'Fá♯',
  'Sol',
  'Sol♯',
  'Lá',
  'Lá♯',
  'Si',
];

const List<String> _solfejoExtenso = [
  'Dó',
  'Dó sustenido',
  'Ré',
  'Ré sustenido',
  'Mi',
  'Fá',
  'Fá sustenido',
  'Sol',
  'Sol sustenido',
  'Lá',
  'Lá sustenido',
  'Si',
];

/// Retorna o nome da classe da nota, aceitando número MIDI ou classe 0–11.
String nomeNota(int midiOuClasse, String tipo) {
  final classe = ((midiOuClasse % 12) + 12) % 12;
  return (tipo == 'cifragem' ? _cifra : _solfejo)[classe];
}

/// Retorna o nome por extenso em português, útil em instruções e explicações.
String nomeNotaPorExtenso(int midiOuClasse) {
  final classe = ((midiOuClasse % 12) + 12) % 12;
  return _solfejoExtenso[classe];
}
