import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('o ditado rítmico mantém somente os três WAVs necessários', () async {
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
  });
}
