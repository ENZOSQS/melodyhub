import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/utils/guitar_sample_map.dart';

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

  test('há sample de violão para cada corda e casa do simulador', () async {
    final samples = GuitarSampleMap.fretboardAssets.toList();
    expect(samples, hasLength(78));
    expect(GuitarSampleMap.forPosition(5, 0), 'guitar/gtr_lowE_E2.ogg');
    expect(GuitarSampleMap.forPosition(0, 0), 'guitar/gtr_highE_E4.ogg');

    for (final sample in samples) {
      final data = await rootBundle.load('assets/sounds/$sample');
      expect(data.lengthInBytes, greaterThan(1000), reason: sample);
      expect(
        String.fromCharCodes(data.buffer.asUint8List(data.offsetInBytes, 4)),
        'OggS',
        reason: '$sample precisa ser OGG válido',
      );
    }
  });
}
