import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String emoji;
  @HiveField(3)
  int colorIndex;
  @HiveField(4)
  List<int> activeDays;
  @HiveField(5)
  int? reminderHour;
  @HiveField(6)
  int? reminderMinute;
  @HiveField(7)
  DateTime createdAt;
  @HiveField(8)
  DateTime? archivedAt;
  @HiveField(9)
  int streakFreezeCount;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    this.colorIndex = 0,
    this.activeDays = const [1, 2, 3, 4, 5, 6, 7],
    this.reminderHour,
    this.reminderMinute,
    required this.createdAt,
    this.archivedAt,
    this.streakFreezeCount = 1,
  });

  bool get isArchived => archivedAt != null;

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  bool isActiveOnDay(int weekday) => activeDays.contains(weekday);

  bool get isDaily => activeDays.length == 7;
}
