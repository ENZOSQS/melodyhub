/// Rules for showing a study streak without leaving stale counts on the profile.
abstract final class StudyStreak {
  static int currentCount({
    required int savedCount,
    required String? lastStudyDate,
    required DateTime now,
  }) {
    if (savedCount <= 0 || lastStudyDate == null || lastStudyDate.isEmpty) {
      return 0;
    }

    final today = dateKey(now);
    final yesterday = dateKey(DateTime(now.year, now.month, now.day - 1));
    return lastStudyDate == today || lastStudyDate == yesterday
        ? savedCount
        : 0;
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
