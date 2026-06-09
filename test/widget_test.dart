import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habitforge/app.dart';
import 'package:habitforge/data/models/habit.dart';
import 'package:habitforge/data/models/habit_completion.dart';
import 'package:habitforge/data/services/hive_service.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('habitforge_test');
    Hive.init(dir.path);
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCompletionAdapter());
    await Hive.openBox<Habit>(HiveService.habitsBox);
    await Hive.openBox<HabitCompletion>(HiveService.completionsBox);
  });

  testWidgets('Home screen renders with empty state when there are no habits',
      (tester) async {
    await tester.pumpWidget(const HabitForgeApp());
    await tester.pumpAndSettle();

    expect(find.text('HabitForge'), findsOneWidget);
    expect(find.text('No habits yet'), findsOneWidget);
  });
}
