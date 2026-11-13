import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/utils/guitar_sample_map.dart';
import 'package:melodyhub/utils/sample_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'o ditado rítmico possui os três cliques de áudio empacotados',
    () async {
      for (final file in [
        'metronome_downbeat.wav',
        'metronome_beat.wav',
        'rhythm_note.wav',
      ]) {
        final data = await rootBundle.load('assets/sounds/$file');
        expect(data.lengthInBytes, greaterThan(44), reason: file);
        expect(
          String.fromCharCodes(data.buffer.asUint8List(data.offsetInBytes, 4)),
          'RIFF',
          reason: '$file precisa ser WAV válido',
        );
      }
    },
  );

  test(
    'o mapa de piano cobre toda a faixa usada e os arquivos existem',
    () async {
      for (
        var midi = SampleMap.pianoFirstMidi;
        midi <= SampleMap.pianoLastMidi;
        midi++
      ) {
        final sample = SampleMap.piano(midi);
        expect((midi - sample.sourceMidi).abs(), lessThanOrEqualTo(1));
        expect(
          sample.pitchRatio,
          closeTo(SampleMap.pitchRatio(midi, sample.sourceMidi), 1e-12),
        );
        final data = await rootBundle.load('assets/sounds/${sample.file}');
        expect(data.lengthInBytes, greaterThan(1000), reason: sample.file);
        expect(
          String.fromCharCodes(data.buffer.asUint8List(data.offsetInBytes, 4)),
          'OggS',
          reason: '${sample.file} precisa ser OGG válido',
        );
      }
    },
  );

  test(
    'há sample de violão mapeado para cada corda e casa até a 12ª',
    () async {
      for (var stringIndex = 0; stringIndex < 6; stringIndex++) {
        for (var fret = 0; fret <= 12; fret++) {
          final sample = GuitarSampleMap.forPosition(stringIndex, fret);
          final midi = GuitarSampleMap.openMidiNotes[stringIndex] + fret;
          expect((midi - sample.sourceMidi).abs(), lessThanOrEqualTo(1));
          final data = await rootBundle.load('assets/sounds/${sample.file}');
          expect(data.lengthInBytes, greaterThan(1000), reason: sample.file);
          expect(
            String.fromCharCodes(
              data.buffer.asUint8List(data.offsetInBytes, 4),
            ),
            'OggS',
            reason: '${sample.file} precisa ser OGG válido',
          );
        }
      }
    },
  );

  test('pitchRatio representa semitons e rejeita deslocamentos maiores', () {
    expect(SampleMap.pitchRatio(61, 60), closeTo(1.059463, 1e-6));
    expect(SampleMap.pitchRatio(59, 60), closeTo(0.943874, 1e-6));
    expect(() => SampleMap.pitchRatio(62, 60), throwsRangeError);
  });
}
