/// Maps the standard-tuned guitar fretboard to real, string-specific samples.
abstract final class GuitarSampleMap {
  static const openMidiNotes = [64, 59, 55, 50, 45, 40];
  static const _stringAssets = ['highE', 'B', 'G', 'D', 'A', 'lowE'];
  static const _noteAssets = [
    'C',
    'Cs',
    'D',
    'Ds',
    'E',
    'F',
    'Fs',
    'G',
    'Gs',
    'A',
    'As',
    'B',
  ];

  static String forPosition(int stringIndex, int fret) {
    RangeError.checkValueInInterval(stringIndex, 0, 5, 'stringIndex');
    RangeError.checkValueInInterval(fret, 0, 12, 'fret');
    final midi = openMidiNotes[stringIndex] + fret;
    return 'guitar/gtr_${_stringAssets[stringIndex]}_'
        '${_noteAssets[midi % 12]}${midi ~/ 12 - 1}.ogg';
  }

  static Iterable<String> get fretboardAssets sync* {
    for (
      var stringIndex = 0;
      stringIndex < openMidiNotes.length;
      stringIndex++
    ) {
      for (var fret = 0; fret <= 12; fret++) {
        yield forPosition(stringIndex, fret);
      }
    }
  }
}
