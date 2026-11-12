import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/domain/answer_feedback_rules.dart';

void main() {
  test('feedback classifica a distância e a direção da nota', () {
    expect(AnswerFeedbackRules.distance(60, 60), AnswerDistance.exact);
    expect(AnswerFeedbackRules.distance(61, 60), AnswerDistance.close);
    expect(AnswerFeedbackRules.distance(62, 60), AnswerDistance.close);
    expect(AnswerFeedbackRules.distance(63, 60), AnswerDistance.far);
    expect(AnswerFeedbackRules.direction(62, 60), NoteDirection.higher);
    expect(AnswerFeedbackRules.direction(58, 60), NoteDirection.lower);
  });

  test('estrelas e progresso contam até a segunda tentativa', () {
    expect(AnswerFeedbackRules.starsForAttempt(1), 3);
    expect(AnswerFeedbackRules.starsForAttempt(2), 2);
    expect(AnswerFeedbackRules.starsForAttempt(3), 1);
    expect(AnswerFeedbackRules.starsForAttempt(4, revealed: true), 0);
    expect(AnswerFeedbackRules.countsAsCorrect(1), isTrue);
    expect(AnswerFeedbackRules.countsAsCorrect(2), isTrue);
    expect(AnswerFeedbackRules.countsAsCorrect(3), isFalse);
    expect(AnswerFeedbackRules.countsAsCorrect(1, revealed: true), isFalse);
  });
}
