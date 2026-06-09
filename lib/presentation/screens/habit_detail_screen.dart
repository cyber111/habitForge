import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/habitforge_colors.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_completion.dart';
import '../../logic/blocs/habits/habits_bloc.dart';
import '../../logic/helpers/streak_calculator.dart';
import '../widgets/habit_heatmap.dart';
import 'add_habit_screen.dart';

/// Heatmap + stats for a single habit: hero header, 365-day GitHub-style
/// heatmap, weekly per-weekday bar chart and a 6-month completion trend.
class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitsBloc, HabitsState>(
      builder: (context, state) {
        final matches = [...state.habits, ...state.archivedHabits]
            .where((h) => h.id == habitId)
            .toList();
        final habit = matches.isEmpty ? null : matches.first;

        if (habit == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Habit not found')),
          );
        }

        final color = HabitForgeColors.habitColors[habit.colorIndex % HabitForgeColors.habitColors.length];
        final errorColor = Theme.of(context).colorScheme.error;
        final completions = state.completionsFor(habit.id);
        final current = state.currentStreakFor(habit);
        final best = state.bestStreakFor(habit);
        final rate = state.completionRateFor(habit);

        return Scaffold(
          appBar: AppBar(title: Text(habit.name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeroHeader(habit: habit, color: color, current: current, best: best, rate: rate),
              const SizedBox(height: 24),
              _SectionTitle(emoji: '📅', title: 'Activity (last 12 months)'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: HabitHeatmap(
                    data: StreakCalculator.heatmapData(completions, days: 365),
                    baseColor: color,
                    weeks: 52,
                    onCellTap: (date, intensity) => _showDayInfo(context, date, intensity),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(emoji: '📊', title: 'By day of week (last 4 weeks)'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                  child: SizedBox(
                    height: 180,
                    child: _WeekdayBarChart(habit: habit, completions: completions, color: color),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(emoji: '📈', title: 'Trend (last 6 months)'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                  child: SizedBox(
                    height: 180,
                    child: _MonthlyTrendChart(habit: habit, completions: completions, color: color),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<HabitsBloc>(),
                            child: AddHabitScreen(editing: habit),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareStats(habit, current, best, rate),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmArchive(context, habit),
                  icon: Icon(
                    habit.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                    color: errorColor,
                  ),
                  label: Text(
                    habit.isArchived ? 'Restore habit' : 'Archive habit',
                    style: TextStyle(color: errorColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDayInfo(BuildContext context, DateTime date, int intensity) {
    final formatted = DateFormat('EEEE, d MMMM yyyy').format(date);
    final status = intensity > 0 ? 'Completed ✅' : 'Missed ⬜';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$formatted — $status'), behavior: SnackBarBehavior.floating));
  }

  void _shareStats(Habit habit, int current, int best, double rate) {
    final text = '''
🔥 HabitForge Stats

${habit.emoji} ${habit.name}
📅 Current Streak: $current ${current == 1 ? 'day' : 'days'}
🏆 Best Streak: $best ${best == 1 ? 'day' : 'days'}
📊 Completion Rate: ${(rate * 100).round()}%

"Consistency is the mother of mastery"

— Track your habits with HabitForge''';
    Share.share(text);
  }

  void _confirmArchive(BuildContext context, Habit habit) {
    final bloc = context.read<HabitsBloc>();
    final isArchived = habit.isArchived;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isArchived ? 'Restore "${habit.name}"?' : 'Archive "${habit.name}"?'),
        content: Text(
          isArchived
              ? 'This habit will reappear in your daily list.'
              : 'Archived habits are hidden from your daily list but their history is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              bloc.add(HabitArchiveToggled(habit));
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: Text(isArchived ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.habit,
    required this.color,
    required this.current,
    required this.best,
    required this.rate,
  });

  final Habit habit;
  final Color color;
  final int current;
  final int best;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final activeDaysLabel = habit.isDaily
        ? 'Every day'
        : habit.activeDays.map((d) => AppConstants.weekdayShort[d - 1]).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(habit.emoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 10),
          Text(
            habit.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            activeDaysLabel,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(icon: '🔥', label: 'Current', value: '$current'),
              _StatColumn(icon: '🏆', label: 'Best', value: '$best'),
              _StatColumn(icon: '📊', label: 'Rate', value: '${(rate * 100).round()}%'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0);
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}

/// 7 bars (Mon-Sun): how many of the last 4 occurrences of that weekday were
/// completed. Today's weekday bar is highlighted.
class _WeekdayBarChart extends StatelessWidget {
  const _WeekdayBarChart({required this.habit, required this.completions, required this.color});

  final Habit habit;
  final List<HabitCompletion> completions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedDates = completions
        .where((c) => c.completed)
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet();
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final counts = List<int>.filled(7, 0);
    for (var weekday = 1; weekday <= 7; weekday++) {
      if (!habit.activeDays.contains(weekday)) continue;
      var count = 0;
      var day = today;
      // Walk back to the most recent occurrence of this weekday, then count
      // the previous 4 occurrences (inclusive of today if it matches).
      while (day.weekday != weekday) {
        day = day.subtract(const Duration(days: 1));
      }
      for (var i = 0; i < 4; i++) {
        if (completedDates.contains(day)) count++;
        day = day.subtract(const Duration(days: 7));
      }
      counts[weekday - 1] = count;
    }

    return BarChart(
      BarChartData(
        maxY: 4,
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > 6) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppConstants.weekdayShort[index].substring(0, 1),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(7, (i) {
          final isToday = (i + 1) == today.weekday;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[i].toDouble(),
                color: isToday ? color : color.withValues(alpha: 0.35),
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
      duration: const Duration(milliseconds: 400),
    );
  }
}

/// Line chart of completion rate per month for the last 6 months.
class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.habit, required this.completions, required this.color});

  final Habit habit;
  final List<HabitCompletion> completions;
  final Color color;

  static const _months = 6;

  List<_MonthPoint> _ratesByMonth() {
    final completedDates = completions
        .where((c) => c.completed)
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet();
    final now = DateTime.now();
    final points = <_MonthPoint>[];

    for (var i = _months - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEndExclusive = DateTime(monthStart.year, monthStart.month + 1, 1);
      final lastDay = monthEndExclusive.isAfter(now)
          ? DateTime(now.year, now.month, now.day)
          : monthEndExclusive.subtract(const Duration(days: 1));

      var active = 0;
      var done = 0;
      for (var d = monthStart; !d.isAfter(lastDay); d = d.add(const Duration(days: 1))) {
        if (habit.activeDays.contains(d.weekday)) {
          active++;
          if (completedDates.contains(d)) done++;
        }
      }
      points.add(_MonthPoint(month: monthStart, rate: active == 0 ? 0 : done / active));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = _ratesByMonth();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (_) => FlLine(color: theme.dividerColor.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 0.25,
              getTitlesWidget: (value, meta) => Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat.MMM().format(points[index].month),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].rate)],
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
    );
  }
}

class _MonthPoint {
  const _MonthPoint({required this.month, required this.rate});

  final DateTime month;
  final double rate;
}
