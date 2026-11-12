import 'sample_map.dart';

/// Maps the standard-tuned guitar fretboard to nearby recorded samples.
abstract final class GuitarSampleMap {
  static const openMidiNotes = [64, 59, 55, 50, 45, 40];

  static MappedSample forPosition(int stringIndex, int fret) {
    RangeError.checkValueInInterval(stringIndex, 0, 5, 'stringIndex');
    RangeError.checkValueInInterval(fret, 0, 12, 'fret');
    final midi = openMidiNotes[stringIndex] + fret;
    return SampleMap.guitar(midi);
  }

  static Iterable<MappedSample> get fretboardSamples sync* {
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

  static Iterable<String> get fretboardAssets =>
      fretboardSamples.map((sample) => sample.file).toSet();
}
