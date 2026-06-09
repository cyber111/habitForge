import 'package:hive/hive.dart';

part 'habit_completion.g.dart';

@HiveType(typeId: 1)
class HabitCompletion extends HiveObject {
  @HiveField(0)
  final String habitId;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  bool completed;

  HabitCompletion({
    required this.habitId,
    required this.date,
    this.completed = false,
  });

  /// Storage key: "habitId_2024-06-15" — normalized to a date-only string.
  @override
  String get key => storageKey(habitId, date);

  static String storageKey(String habitId, DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${habitId}_${normalized.toIso8601String().substring(0, 10)}';
  }
}
