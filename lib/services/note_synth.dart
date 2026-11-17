import 'dart:math' as math;
import 'dart:typed_data';

/// Timbre usado pela síntese. O piano tem mais harmônicos e decaimento mais
/// longo; o violão é mais seco.
enum SynthTimbre { piano, guitar }

/// Gera notas inteiras em memória como WAV PCM 16 bits mono a 44,1 kHz.
///
/// Cada nota já nasce na frequência exata, com soma de harmônicos, ataque,
/// decaimento e release dentro do próprio buffer. Por isso o som sai como uma
/// única voz: não desliza de outra altura, não estala e os parciais não
/// dessincronizam. Código puro (sem Flutter), para poder ser testado.
abstract final class NoteSynth {
  static const int sampleRate = 44100;
  static const int attackMs = 6;
  static const int releaseMs = 300;
  static const double peakGain = 0.55;

  static double frequencyOf(int midi) =>
      440 * math.pow(2, (midi - 69) / 12).toDouble();

  /// Duração total do buffer: a parte sustentada mais o release.
  static int totalMs(int durationMs) => durationMs + releaseMs;

  /// Uma nota isolada.
  static Uint8List renderNote(
    int midi, {
    required int durationMs,
    SynthTimbre timbre = SynthTimbre.piano,
  }) => renderChord([midi], durationMs: durationMs, timbre: timbre);

  /// Várias notas somadas no mesmo buffer (acorde), já normalizadas.
  static Uint8List renderChord(
    List<int> midis, {
    required int durationMs,
    SynthTimbre timbre = SynthTimbre.piano,
  }) {
    if (midis.isEmpty) throw ArgumentError.value(midis, 'midis', 'vazio');
    for (final midi in midis) {
      if (midi < 0 || midi > 127) throw RangeError.range(midi, 0, 127, 'midi');
    }
    if (durationMs <= 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'deve ser positivo');
    }
    final samples = pcmFor(midis, durationMs: durationMs, timbre: timbre);
    return wrapWav(samples);
  }

  /// Amostras PCM 16 bits (sem cabeçalho).
  static Int16List pcmFor(
    List<int> midis, {
    required int durationMs,
    SynthTimbre timbre = SynthTimbre.piano,
  }) {
    final total = sampleRate * totalMs(durationMs) ~/ 1000;
    final sustainEnd = sampleRate * durationMs ~/ 1000;
    final attack = sampleRate * attackMs ~/ 1000;
    final release = total - sustainEnd;
    final partials = _partials(timbre);
    final weight = partials.fold<double>(0, (sum, p) => sum + p.$2);
    final gain = peakGain / (weight * midis.length);
    final baseDecay = timbre == SynthTimbre.piano ? 0.9 : 0.45;
    final out = Int16List(total);
    final mix = Float64List(total);

    for (final midi in midis) {
      final f0 = frequencyOf(midi);
      for (final (harmonic, amplitude) in partials) {
        final freq = f0 * harmonic;
        // Harmônicos acima de Nyquist geram ruído; são descartados.
        if (freq >= sampleRate / 2) continue;
        final step = 2 * math.pi * freq / sampleRate;
        // Harmônicos agudos somem mais depressa, como numa corda real.
        final tau = baseDecay / math.pow(harmonic, 0.6);
        final decayPerSample = math.exp(-1 / (tau * sampleRate));
        var envelope = amplitude;
        for (var i = 0; i < total; i++) {
          mix[i] += envelope * math.sin(step * i);
          envelope *= decayPerSample;
        }
      }
    }

    for (var i = 0; i < total; i++) {
      var shape = 1.0;
      if (i < attack) shape = i / attack;
      if (i >= sustainEnd) {
        // Release em cosseno: chega exatamente a zero, sem estalo.
        final t = (i - sustainEnd) / release;
        shape *= 0.5 * (1 + math.cos(math.pi * t));
      }
      final value = (mix[i] * gain * shape).clamp(-1.0, 1.0);
      out[i] = (value * 32767).round();
    }
    out[total - 1] = 0;
    return out;
  }

  static List<(int, double)> _partials(SynthTimbre timbre) =>
      timbre == SynthTimbre.piano
      ? const [(1, 1.0), (2, 0.50), (3, 0.22), (4, 0.12), (5, 0.06), (6, 0.03)]
      : const [(1, 1.0), (2, 0.45), (3, 0.25), (4, 0.10)];

  /// Cabeçalho RIFF/WAVE padrão de 44 bytes + dados.
  static Uint8List wrapWav(Int16List samples) {
    final dataBytes = samples.length * 2;
    final bytes = ByteData(44 + dataBytes);
    void ascii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        bytes.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataBytes, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // tamanho do bloco fmt
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits por amostra
    ascii(36, 'data');
    bytes.setUint32(40, dataBytes, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      bytes.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}
