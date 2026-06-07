import 'package:flutter/material.dart';

import '../../core/constants/preset_habits.dart';

/// A subtle italic quote that changes once per day (stable across rebuilds).
class MotivationalQuote extends StatelessWidget {
  const MotivationalQuote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final seed = today.year * 1000 + today.month * 31 + today.day;
    final quote = PresetHabits.motivationalQuotes[
        seed % PresetHabits.motivationalQuotes.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Text(
        '“$quote”',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          height: 1.4,
        ),
      ),
    );
  }
}
