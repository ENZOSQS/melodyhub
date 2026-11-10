import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/data/theory_question_bank.dart';

void main() {
  group('Banco de questões teóricas', () {
    test(
      'cada questão tem resposta única entre as alternativas e nível válido',
      () {
        final ids = <String>{};
        for (final question in theoryQuestionBank) {
          expect(
            ids.add(question.id),
            isTrue,
            reason: 'ID repetido: ${question.id}',
          );
          expect(
            question.options.length,
            greaterThanOrEqualTo(3),
            reason: question.id,
          );
          expect(
            question.options.toSet().length,
            question.options.length,
            reason: 'Alternativa repetida: ${question.id}',
          );
          expect(
            question.options,
            contains(question.answer),
            reason: question.id,
          );
          expect(
            question.difficulty,
            inInclusiveRange(1, 5),
            reason: question.id,
          );
        }
      },
    );

    test('todas as questões incluem dica e explicação específicas', () {
      expect(theoryLearningNotes.length, theoryQuestionBank.length);
      for (final question in theoryQuestionBank) {
        expect(
          question.hint,
          isNot(contains('relacioná-lo ao enunciado')),
          reason: question.id,
        );
        expect(
          question.explanation,
          isNot(contains('Revise o conceito de')),
          reason: question.id,
        );
        expect(
          question.explanation.trim().length,
          greaterThan(30),
          reason: question.id,
        );
      }
    });

    test('banco cobre todos os cinco níveis e mais de um conceito', () {
      expect(theoryQuestionBank.map((q) => q.difficulty).toSet(), {
        1,
        2,
        3,
        4,
        5,
      });
      expect(
        theoryQuestionBank.map((q) => q.category).toSet().length,
        greaterThan(5),
      );
    });
  });
}
