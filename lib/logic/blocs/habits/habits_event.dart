part of 'habits_bloc.dart';

abstract class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads all habits + completions from storage (shows a loading spinner).
class HabitsLoaded extends HabitsEvent {
  const HabitsLoaded();
}

/// Reloads from storage without transitioning to the loading state —
/// used by pull-to-refresh so the existing list stays visible.
class HabitsRefreshed extends HabitsEvent {
  const HabitsRefreshed();
}

class HabitAdded extends HabitsEvent {
  const HabitAdded({
    required this.name,
    required this.emoji,
    this.colorIndex = 0,
    this.activeDays = const [1, 2, 3, 4, 5, 6, 7],
    this.reminderHour,
    this.reminderMinute,
  });

  final String name;
  final String emoji;
  final int colorIndex;
  final List<int> activeDays;
  final int? reminderHour;
  final int? reminderMinute;

  @override
  List<Object?> get props =>
      [name, emoji, colorIndex, activeDays, reminderHour, reminderMinute];
}

class HabitUpdated extends HabitsEvent {
  const HabitUpdated({
    required this.habit,
    this.name,
    this.emoji,
    this.colorIndex,
    this.activeDays,
    this.reminderHour,
    this.reminderMinute,
    this.clearReminder = false,
  });

  final Habit habit;
  final String? name;
  final String? emoji;
  final int? colorIndex;
  final List<int>? activeDays;
  final int? reminderHour;
  final int? reminderMinute;
  final bool clearReminder;

  @override
  List<Object?> get props => [
        habit,
        name,
        emoji,
        colorIndex,
        activeDays,
        reminderHour,
        reminderMinute,
        clearReminder,
      ];
}

class HabitArchiveToggled extends HabitsEvent {
  const HabitArchiveToggled(this.habit);

  final Habit habit;

  @override
  List<Object?> get props => [habit];
}

class HabitDeleted extends HabitsEvent {
  const HabitDeleted(this.habit);

  final Habit habit;

  @override
  List<Object?> get props => [habit];
}

/// Toggles whether [habit] is marked complete on [date].
class HabitCompletionToggled extends HabitsEvent {
  const HabitCompletionToggled({required this.habit, required this.date});

  final Habit habit;
  final DateTime date;

  @override
  List<Object?> get props => [habit, date];
}

/// Moves the "selected day" shown on the home screen forward/backward.
class SelectedDateChanged extends HabitsEvent {
  const SelectedDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}
