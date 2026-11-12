import 'dart:math' as math;

/// Mapeamento central de notas MIDI para samples instrumentais do app.
typedef MappedSample = ({String file, double pitchRatio, int sourceMidi});

abstract final class SampleMap {
  static const int pianoFirstMidi = 36; // Dó 2
  static const int pianoLastMidi = 84; // Dó 6
  static const int guitarFirstMidi = 40; // Mi 2
  static const int guitarLastMidi = 76; // Mi 5

  static const _pianoSampleMidis = <int>[
    36,
    39,
    42,
    45,
    48,
    51,
    54,
    57,
    60,
    63,
    66,
    69,
    72,
    75,
    78,
    81,
    84,
  ];
  static const _guitarAcousticSampleMidis = <int>[
    40,
    41,
    42,
    43,
    44,
    45,
    46,
    47,
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    65,
    66,
    67,
    68,
  ];
  static const _guitarNylonSampleMidis = <int>[69, 71, 73, 74, 76];

  static const _pitchClassNames = <String>[
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

  static MappedSample piano(int midi) {
    RangeError.checkValueInInterval(
      midi,
      pianoFirstMidi,
      pianoLastMidi,
      'midi',
    );
    return _nearestSample(
      midi,
      _pianoSampleMidis,
      (sourceMidi) => 'piano/${_noteName(sourceMidi)}.ogg',
    );
  }

  static MappedSample guitar(int midi) {
    RangeError.checkValueInInterval(
      midi,
      guitarFirstMidi,
      guitarLastMidi,
      'midi',
    );
    final acoustic = _guitarAcousticSampleMidis
        .where((source) => (source - midi).abs() <= 1)
        .toList();
    final nylon = _guitarNylonSampleMidis
        .where((source) => (source - midi).abs() <= 1)
        .toList();
    final candidates = [...acoustic, ...nylon];
    if (candidates.isEmpty) {
      throw StateError('Não há sample de violão próximo à nota MIDI $midi.');
    }
    candidates.sort((a, b) {
      final distance = (a - midi).abs().compareTo((b - midi).abs());
      if (distance != 0) return distance;
      // Em caso de empate, manter o timbre acústico enquanto ele existir.
      final aNylon = _guitarNylonSampleMidis.contains(a);
      final bNylon = _guitarNylonSampleMidis.contains(b);
      return aNylon == bNylon ? a.compareTo(b) : (aNylon ? 1 : -1);
    });
    final sourceMidi = candidates.first;
    final instrument = _guitarNylonSampleMidis.contains(sourceMidi)
        ? 'gtr_nylon'
        : 'gtr_acoustic';
    return _mapped(
      midi,
      sourceMidi,
      (source) => 'guitar/${instrument}_${_noteName(source)}.ogg',
    );
  }

  static Iterable<String> get pianoAssets sync* {
    for (final midi in _pianoSampleMidis) {
      yield piano(midi).file;
    }
  }

  static Iterable<String> get guitarAssets sync* {
    for (final midi in {
      ..._guitarAcousticSampleMidis,
      ..._guitarNylonSampleMidis,
    }) {
      yield guitar(midi).file;
    }
  }

  static MappedSample _nearestSample(
    int midi,
    List<int> sources,
    String Function(int sourceMidi) assetFor,
  ) {
    final candidates =
        sources.where((source) => (source - midi).abs() <= 1).toList()
          ..sort((a, b) {
            final distance = (a - midi).abs().compareTo((b - midi).abs());
            return distance != 0 ? distance : a.compareTo(b);
          });
    if (candidates.isEmpty) {
      throw StateError('Não há sample próximo à nota MIDI $midi.');
    }
    final sourceMidi = candidates.first;
    return _mapped(midi, sourceMidi, assetFor);
  }

  static MappedSample _mapped(
    int midi,
    int sourceMidi,
    String Function(int sourceMidi) assetFor,
  ) => (
    file: assetFor(sourceMidi),
    sourceMidi: sourceMidi,
    pitchRatio: pitchRatio(midi, sourceMidi),
  );

  static double pitchRatio(int midi, int sourceMidi) {
    if ((midi - sourceMidi).abs() > 1) {
      throw RangeError('O sample não pode ser deslocado mais de um semitom.');
    }
    return math.pow(2, (midi - sourceMidi) / 12).toDouble();
  }

  static String _noteName(int midi) {
    final octave = midi ~/ 12 - 1;
    return '${_pitchClassNames[midi % 12]}$octave';
  }
}
