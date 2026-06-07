import '../../data/models/habit_completion.dart';

/// Pure-Dart streak/heatmap math — no Flutter or Hive dependency so it can be
/// unit tested in isolation and reused across the home, detail and stats screens.
class StreakCalculator {
  StreakCalculator._();

  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static Set<DateTime> _completedDateSet(List<HabitCompletion> completions) {
    return completions
        .where((c) => c.completed)
        .map((c) => normalizeDate(c.date))
        .toSet();
  }

  /// Current streak counted backwards from today.
  ///
  /// Only days that are "active" for the habit count towards the streak.
  /// Today is given grace: if it hasn't been completed yet, that alone won't
  /// break the streak (the day isn't over). Up to [freezeCount] missed active
  /// days are tolerated without breaking the chain.
  static int currentStreak(
    List<HabitCompletion> completions,
    List<int> activeDays, {
    int freezeCount = 1,
  }) {
    if (activeDays.isEmpty) return 0;
    final completedDates = _completedDateSet(completions);
    if (completedDates.isEmpty) return 0;

    final today = normalizeDate(DateTime.now());
    var day = today;
    var streak = 0;
    var freezesLeft = freezeCount;

    for (var i = 0; i < 3650; i++) {
      if (activeDays.contains(day.weekday)) {
        final completed = completedDates.contains(day);
        if (completed) {
          streak++;
        } else if (day == today) {
          // Today isn't finished yet — don't break the streak just because
          // the user hasn't checked in (so far).
        } else if (freezesLeft > 0) {
          freezesLeft--;
        } else {
          break;
        }
      }
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest streak ever achieved, scanning the full completion history.
  static int bestStreak(
    List<HabitCompletion> completions,
    List<int> activeDays, {
    int freezeCount = 1,
  }) {
    if (activeDays.isEmpty) return 0;
    final completedDates = _completedDateSet(completions);
    if (completedDates.isEmpty) return 0;

    final sorted = completedDates.toList()..sort();
    final end = normalizeDate(DateTime.now());

    var best = 0;
    var streak = 0;
    var freezesLeft = freezeCount;

    for (var day = sorted.first;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))) {
      if (!activeDays.contains(day.weekday)) continue;

      if (completedDates.contains(day)) {
        streak++;
        if (streak > best) best = streak;
      } else if (freezesLeft > 0) {
        freezesLeft--;
      } else {
        streak = 0;
        freezesLeft = freezeCount;
      }
    }
    return best;
  }

  /// Fraction (0.0–1.0) of active days completed in the last [days] days
  /// (today included).
  static double completionRate(
    List<HabitCompletion> completions,
    List<int> activeDays, {
    int days = 30,
  }) {
    if (activeDays.isEmpty) return 0;
    final completedDates = _completedDateSet(completions);
    final today = normalizeDate(DateTime.now());

    var activeDaysInPeriod = 0;
    var completedInPeriod = 0;
    for (var i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      if (activeDays.contains(day.weekday)) {
        activeDaysInPeriod++;
        if (completedDates.contains(day)) completedInPeriod++;
      }
    }
    if (activeDaysInPeriod == 0) return 0;
    return completedInPeriod / activeDaysInPeriod;
  }

  /// Heatmap intensity (0-4) for each of the last [days] days.
  ///
  /// [totalCount] is the number of habits represented in [completions] —
  /// pass `1` (the default) for a single-habit heatmap, or the number of
  /// active habits for a combined "overall" heatmap. Intensity buckets the
  /// fraction of habits completed that day: 0 = none, 1 = 1-25%, 2 = 26-50%,
  /// 3 = 51-75%, 4 = 76-100%.
  static Map<DateTime, int> heatmapData(
    List<HabitCompletion> completions, {
    int days = 365,
    int totalCount = 1,
  }) {
    final completedCountByDate = <DateTime, int>{};
    for (final c in completions) {
      if (!c.completed) continue;
      final d = normalizeDate(c.date);
      completedCountByDate[d] = (completedCountByDate[d] ?? 0) + 1;
    }

    final today = normalizeDate(DateTime.now());
    final result = <DateTime, int>{};
    for (var i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final completedCount = completedCountByDate[day] ?? 0;
      result[day] = _intensityFor(completedCount, totalCount);
    }
    return result;
  }

  static int _intensityFor(int completed, int total) {
    if (completed <= 0 || total <= 0) return 0;
    final ratio = completed / total;
    if (ratio >= 0.76) return 4;
    if (ratio >= 0.51) return 3;
    if (ratio >= 0.26) return 2;
    return 1;
  }
}
