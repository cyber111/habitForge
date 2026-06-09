import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pratik_app_kit/pratik_app_kit.dart';

import 'core/theme/habitforge_colors.dart';
import 'data/repositories/habit_repository.dart';
import 'logic/blocs/habits/habits_bloc.dart';
import 'presentation/screens/root_shell.dart';

class HabitForgeApp extends StatelessWidget {
  const HabitForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()..loadSavedTheme()),
        BlocProvider(
          create: (_) => HabitsBloc(repository: HabitRepository())..add(const HabitsLoaded()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'HabitForge',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppThemeBuilder.buildLight(HabitForgeColors(), fontFamily: 'Nunito'),
            darkTheme: AppThemeBuilder.buildDark(HabitForgeDarkColors(), fontFamily: 'Nunito'),
            home: const RootShell(),
          );
        },
      ),
    );
  }
}
