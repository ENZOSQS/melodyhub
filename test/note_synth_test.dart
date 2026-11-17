import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/services/note_synth.dart';

void main() {
  test('gera WAV PCM 16 bits mono a 44,1 kHz', () {
    final wav = NoteSynth.renderNote(60, durationMs: 400);
    final header = ByteData.sublistView(wav, 0, 44);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(header.getUint16(20, Endian.little), 1);
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint32(24, Endian.little), 44100);
    expect(header.getUint16(34, Endian.little), 16);
    final samples = NoteSynth.sampleRate * NoteSynth.totalMs(400) ~/ 1000;
    expect(header.getUint32(40, Endian.little), samples * 2);
    expect(wav.length, 44 + samples * 2);
  });

  test('começa e termina em silêncio (sem estalo)', () {
    final pcm = NoteSynth.pcmFor([67], durationMs: 300);
    expect(pcm.first, 0);
    expect(pcm.last, 0);
    // Últimos 2 ms do release já estão praticamente zerados.
    final tail = pcm.sublist(pcm.length - 88);
    expect(tail.every((value) => value.abs() < 60), isTrue);
  });

  test('soa na frequência exata desde o início, sem deslizar', () {
    for (final midi in [48, 60, 64, 71]) {
      final pcm = NoteSynth.pcmFor([midi], durationMs: 600);
      final expected = NoteSynth.frequencyOf(midi);
      // Mede no começo (logo após o ataque) e no meio da nota.
      for (final startMs in [10, 300]) {
        final start = NoteSynth.sampleRate * startMs ~/ 1000;
        final period = _autocorrelationPeriod(pcm, start, expected);
        final measured = NoteSynth.sampleRate / period;
        expect(
          (measured - expected).abs() / expected,
          lessThan(0.01),
          reason: 'MIDI $midi em $startMs ms',
        );
      }
    }
  });

  test('acorde não estoura o limite de 16 bits', () {
    final pcm = NoteSynth.pcmFor([60, 64, 67, 72], durationMs: 300);
    expect(pcm.every((v) => v.abs() < 32767), isTrue);
  });
}

/// Período (em amostras) com maior autocorrelação perto do esperado.
double _autocorrelationPeriod(Int16List pcm, int start, double freq) {
  final expected = NoteSynth.sampleRate / freq;
  const window = 2048;
  var bestLag = 0;
  var best = double.negativeInfinity;
  for (var lag = (expected * 0.8).floor(); lag <= expected * 1.2; lag++) {
    var sum = 0.0;
    for (var i = 0; i < window; i++) {
      sum += pcm[start + i] * pcm[start + i + lag].toDouble();
    }
    if (sum > best) {
      best = sum;
      bestLag = lag;
    }
  }
  // Refina com interpolação parabólica entre os vizinhos.
  double corr(int lag) {
    var sum = 0.0;
    for (var i = 0; i < window; i++) {
      sum += pcm[start + i] * pcm[start + i + lag].toDouble();
    }
    return sum;
  }

  final a = corr(bestLag - 1), b = best, c = corr(bestLag + 1);
  final shift = 0.5 * (a - c) / (a - 2 * b + c);
  return bestLag + shift;
}
