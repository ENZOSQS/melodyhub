enum AnswerDistance { exact, close, far }

enum NoteDirection { higher, lower, same }

abstract final class AnswerFeedbackRules {
  static AnswerDistance distance(int targetMidi, int guessMidi) {
    final difference = (targetMidi - guessMidi).abs();
    if (difference == 0) return AnswerDistance.exact;
    if (difference <= 2) return AnswerDistance.close;
    return AnswerDistance.far;
  }

  static NoteDirection direction(int targetMidi, int guessMidi) {
    if (targetMidi == guessMidi) return NoteDirection.same;
    return targetMidi > guessMidi ? NoteDirection.higher : NoteDirection.lower;
  }

  static int starsForAttempt(int attempts, {bool revealed = false}) {
    if (revealed || attempts <= 0) return 0;
    if (attempts == 1) return 3;
    if (attempts == 2) return 2;
    return 1;
  }

  static bool countsAsCorrect(int attempts, {bool revealed = false}) =>
      !revealed && attempts > 0 && attempts <= 2;
}
