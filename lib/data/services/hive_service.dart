import 'package:hive_flutter/hive_flutter.dart';

import '../models/habit.dart';
import '../models/habit_completion.dart';

class HiveService {
  HiveService._();

  static const String habitsBox = 'habits';
  static const String completionsBox = 'completions';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCompletionAdapter());
    await Hive.openBox<Habit>(habitsBox);
    await Hive.openBox<HabitCompletion>(completionsBox);
  }

  static Box<Habit> get habits => Hive.box<Habit>(habitsBox);

  static Box<HabitCompletion> get completions =>
      Hive.box<HabitCompletion>(completionsBox);
}
