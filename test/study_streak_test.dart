import 'package:flutter_test/flutter_test.dart';
import 'package:melodyhub/utils/study_streak.dart';

void main() {
  group('StudyStreak.currentCount', () {
    final now = DateTime(2026, 11, 10, 12);

    test('mantém a sequência no mesmo dia do último estudo', () {
      expect(
        StudyStreak.currentCount(
          savedCount: 4,
          lastStudyDate: StudyStreak.dateKey(now),
          now: now,
        ),
        4,
      );
    });

    test('mantém a sequência enquanto o dia seguinte ainda está em curso', () {
      expect(
        StudyStreak.currentCount(
          savedCount: 4,
          lastStudyDate: StudyStreak.dateKey(DateTime(2026, 11, 9)),
          now: now,
        ),
        4,
      );
    });

    test('zera após um dia completo sem atividade', () {
      expect(
        StudyStreak.currentCount(
          savedCount: 4,
          lastStudyDate: StudyStreak.dateKey(DateTime(2026, 11, 8)),
          now: now,
        ),
        0,
      );
    });

    test('calcula ontem corretamente na virada do mês', () {
      expect(
        StudyStreak.currentCount(
          savedCount: 2,
          lastStudyDate: '2026-02-28',
          now: DateTime(2026, 3, 1, 12),
        ),
        2,
      );
    });

    test('não mostra sequência sem data ou com saldo zero', () {
      expect(
        StudyStreak.currentCount(savedCount: 3, lastStudyDate: null, now: now),
        0,
      );
      expect(
        StudyStreak.currentCount(
          savedCount: 0,
          lastStudyDate: StudyStreak.dateKey(now),
          now: now,
        ),
        0,
      );
    });
  });
}
