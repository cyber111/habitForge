part of 'habits_bloc.dart';

enum HabitsStatus { initial, loading, loaded }

class HabitsState extends Equatable {
  const HabitsState({
    this.status = HabitsStatus.initial,
    this.habits = const [],
    this.archivedHabits = const [],
    this.completions = const [],
    this.selectedDate,
  });

  final HabitsStatus status;
  final List<Habit> habits;
  final List<Habit> archivedHabits;
  final List<HabitCompletion> completions;

  /// The day currently shown on the home screen (defaults to today).
  final DateTime? selectedDate;

  DateTime get effectiveSelectedDate {
    final d = selectedDate ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  bool get isToday {
    final today = DateTime.now();
    final s = effectiveSelectedDate;
    return s.year == today.year && s.month == today.month && s.day == today.day;
  }

  HabitsState copyWith({
    HabitsStatus? status,
    List<Habit>? habits,
    List<Habit>? archivedHabits,
    List<HabitCompletion>? completions,
    DateTime? selectedDate,
  }) {
    return HabitsState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
      archivedHabits: archivedHabits ?? this.archivedHabits,
      completions: completions ?? this.completions,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  // ── Derived helpers ───────────────────────────────────────────────────

  /// Habits that are active (scheduled) on the given [date]'s weekday.
  List<Habit> habitsForDate(DateTime date) =>
      habits.where((h) => h.isActiveOnDay(date.weekday)).toList();

  List<HabitCompletion> completionsFor(String habitId) =>
      completions.where((c) => c.habitId == habitId).toList();

  bool isCompletedOn(String habitId, DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return completions.any(
      (c) =>
          c.habitId == habitId &&
          c.completed &&
          c.date.year == normalized.year &&
          c.date.month == normalized.month &&
          c.date.day == normalized.day,
    );
  }

  int currentStreakFor(Habit habit) => StreakCalculator.currentStreak(
        completionsFor(habit.id),
        habit.activeDays,
        freezeCount: habit.streakFreezeCount,
      );

  int bestStreakFor(Habit habit) => StreakCalculator.bestStreak(
        completionsFor(habit.id),
        habit.activeDays,
        freezeCount: habit.streakFreezeCount,
      );

  double completionRateFor(Habit habit, {int days = 30}) =>
      StreakCalculator.completionRate(
        completionsFor(habit.id),
        habit.activeDays,
        days: days,
      );

  /// Sum of current streaks across every active habit — shown as the
  /// "overall streak" summary on the home screen.
  int get overallStreak =>
      habits.fold<int>(0, (sum, h) => sum + currentStreakFor(h));

  /// Number of habits scheduled today that have been completed.
  int get completedTodayCount {
    final todaysHabits = habitsForDate(effectiveSelectedDate);
    return todaysHabits
        .where((h) => isCompletedOn(h.id, effectiveSelectedDate))
        .length;
  }

  int get scheduledTodayCount => habitsForDate(effectiveSelectedDate).length;

  @override
  List<Object?> get props =>
      [status, habits, archivedHabits, completions, selectedDate];
}
