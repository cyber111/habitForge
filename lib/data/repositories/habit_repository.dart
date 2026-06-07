import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../services/hive_service.dart';

/// Encapsulates all CRUD + query operations against the Hive boxes so the
/// rest of the app never talks to Hive directly.
class HabitRepository {
  HabitRepository({Box<Habit>? habitsBox, Box<HabitCompletion>? completionsBox})
      : _habits = habitsBox ?? HiveService.habits,
        _completions = completionsBox ?? HiveService.completions;

  final Box<Habit> _habits;
  final Box<HabitCompletion> _completions;
  static const _uuid = Uuid();

  // ── Habits ────────────────────────────────────────────────────────────

  List<Habit> getAllHabits() => _habits.values.toList();

  List<Habit> getActiveHabits() =>
      _habits.values.where((h) => !h.isArchived).toList();

  List<Habit> getArchivedHabits() =>
      _habits.values.where((h) => h.isArchived).toList();

  Habit? getHabit(String id) {
    try {
      return _habits.values.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Habit> addHabit({
    required String name,
    required String emoji,
    int colorIndex = 0,
    List<int> activeDays = const [1, 2, 3, 4, 5, 6, 7],
    int? reminderHour,
    int? reminderMinute,
    int streakFreezeCount = 1,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      colorIndex: colorIndex,
      activeDays: activeDays,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      createdAt: DateTime.now(),
      streakFreezeCount: streakFreezeCount,
    );
    await _habits.put(habit.id, habit);
    return habit;
  }

  Future<void> updateHabit(
    Habit habit, {
    String? name,
    String? emoji,
    int? colorIndex,
    List<int>? activeDays,
    int? reminderHour,
    int? reminderMinute,
    bool clearReminder = false,
    int? streakFreezeCount,
  }) async {
    if (name != null) habit.name = name;
    if (emoji != null) habit.emoji = emoji;
    if (colorIndex != null) habit.colorIndex = colorIndex;
    if (activeDays != null) habit.activeDays = activeDays;
    if (clearReminder) {
      habit.reminderHour = null;
      habit.reminderMinute = null;
    } else {
      if (reminderHour != null) habit.reminderHour = reminderHour;
      if (reminderMinute != null) habit.reminderMinute = reminderMinute;
    }
    if (streakFreezeCount != null) habit.streakFreezeCount = streakFreezeCount;
    await habit.save();
  }

  Future<void> archiveHabit(Habit habit) async {
    habit.archivedAt = DateTime.now();
    await habit.save();
  }

  Future<void> unarchiveHabit(Habit habit) async {
    habit.archivedAt = null;
    await habit.save();
  }

  Future<void> deleteHabit(Habit habit) async {
    final keysToDelete = _completions.values
        .where((c) => c.habitId == habit.id)
        .map((c) => c.key)
        .toList();
    await _completions.deleteAll(keysToDelete);
    await habit.delete();
  }

  // ── Completions ───────────────────────────────────────────────────────

  List<HabitCompletion> getCompletionsForHabit(String habitId) =>
      _completions.values.where((c) => c.habitId == habitId).toList();

  List<HabitCompletion> getAllCompletions() => _completions.values.toList();

  /// All completions recorded on or after [since] (date-only comparison) —
  /// used for the overall combined heatmap on the Stats screen.
  List<HabitCompletion> getCompletionsSince(DateTime since) {
    final from = DateTime(since.year, since.month, since.day);
    return _completions.values.where((c) => !c.date.isBefore(from)).toList();
  }

  bool isCompleted(String habitId, DateTime date) {
    final key = HabitCompletion.storageKey(habitId, date);
    return _completions.get(key)?.completed ?? false;
  }

  Future<void> toggleCompletion(String habitId, DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final key = HabitCompletion.storageKey(habitId, normalized);
    final existing = _completions.get(key);
    if (existing != null) {
      existing.completed = !existing.completed;
      await existing.save();
    } else {
      final completion = HabitCompletion(
        habitId: habitId,
        date: normalized,
        completed: true,
      );
      await _completions.put(key, completion);
    }
  }

  Future<void> setCompletion(String habitId, DateTime date, bool completed) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final key = HabitCompletion.storageKey(habitId, normalized);
    final existing = _completions.get(key);
    if (existing != null) {
      existing.completed = completed;
      await existing.save();
    } else {
      await _completions.put(
        key,
        HabitCompletion(habitId: habitId, date: normalized, completed: completed),
      );
    }
  }
}
