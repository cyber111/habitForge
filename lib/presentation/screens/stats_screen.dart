import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/habitforge_colors.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_completion.dart';
import '../../logic/blocs/habits/habits_bloc.dart';
import '../../logic/helpers/streak_calculator.dart';
import '../widgets/empty_state.dart';
import '../widgets/habit_heatmap.dart';

/// Overall stats + charts across every habit: combined heatmap, per-habit
/// comparison, best/worst weekday analysis and milestones.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: BlocBuilder<HabitsBloc, HabitsState>(
        builder: (context, state) {
          final habits = state.habits;
          if (habits.isEmpty) {
            return const EmptyState(
              emoji: '📊',
              title: 'Nothing to show yet',
              message: 'Create a few habits and check in daily — your stats will appear here.',
            );
          }

          final allCompletions = habits.expand((h) => state.completionsFor(h.id)).toList();
          final totalCheckIns = allCompletions.where((c) => c.completed).length;
          final longestStreak = habits.fold<int>(
            0,
            (best, h) => h.isArchived ? best : (state.bestStreakFor(h) > best ? state.bestStreakFor(h) : best),
          );
          final avgRate = habits.isEmpty
              ? 0.0
              : habits.map((h) => state.completionRateFor(h)).reduce((a, b) => a + b) / habits.length;
          final weekdayRates = _weekdayRates(habits, allCompletions);
          final milestones = _buildMilestones(
            habitCount: habits.length,
            totalCheckIns: totalCheckIns,
            longestStreak: longestStreak,
            bestRate: habits.isEmpty
                ? 0.0
                : habits.map((h) => state.completionRateFor(h)).reduce((a, b) => a > b ? a : b),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SummaryGrid(
                habitCount: habits.length,
                totalCheckIns: totalCheckIns,
                longestStreak: longestStreak,
                avgRate: avgRate,
              ),
              const SizedBox(height: 24),
              _SectionTitle(emoji: '🗓️', title: 'Combined activity (last 12 months)'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: HabitHeatmap(
                    data: StreakCalculator.heatmapData(allCompletions, days: 365, totalCount: habits.length),
                    baseColor: HabitForgeColors.checkGreen,
                    weeks: 52,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(emoji: '📊', title: 'Habit comparison (last 30 days)'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                  child: SizedBox(
                    height: 200,
                    child: _ComparisonBarChart(
                      habits: habits,
                      rates: {for (final h in habits) h.id: state.completionRateFor(h)},
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(emoji: '📅', title: 'Best & worst days'),
              const SizedBox(height: 12),
              _BestWorstRow(weekdayRates: weekdayRates),
              const SizedBox(height: 24),
              _SectionTitle(emoji: '🏅', title: 'Milestones'),
              const SizedBox(height: 12),
              ...List.generate(milestones.length, (i) {
                final m = milestones[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MilestoneTile(milestone: m)
                      .animate()
                      .fadeIn(duration: 320.ms, delay: (i * 50).ms)
                      .slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareOverview(
                    habitCount: habits.length,
                    totalCheckIns: totalCheckIns,
                    longestStreak: longestStreak,
                    avgRate: avgRate,
                    achievedCount: milestones.where((m) => m.achieved).length,
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share my progress'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Aggregate completion rate per weekday (1 = Mon ... 7 = Sun) across every
  /// active habit over the last [days] days.
  static Map<int, double> _weekdayRates(
    List<Habit> habits,
    List<HabitCompletion> completions, {
    int days = 90,
  }) {
    final completedByHabit = <String, Set<DateTime>>{};
    for (final c in completions) {
      if (!c.completed) continue;
      completedByHabit.putIfAbsent(c.habitId, () => {}).add(StreakCalculator.normalizeDate(c.date));
    }

    final today = StreakCalculator.normalizeDate(DateTime.now());
    final scheduled = List<int>.filled(8, 0);
    final done = List<int>.filled(8, 0);
    for (var i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      final weekday = day.weekday;
      for (final habit in habits) {
        if (habit.isArchived || !habit.activeDays.contains(weekday)) continue;
        scheduled[weekday]++;
        if (completedByHabit[habit.id]?.contains(day) ?? false) done[weekday]++;
      }
    }

    return {
      for (var weekday = 1; weekday <= 7; weekday++)
        weekday: scheduled[weekday] == 0 ? 0.0 : done[weekday] / scheduled[weekday],
    };
  }

  static List<_Milestone> _buildMilestones({
    required int habitCount,
    required int totalCheckIns,
    required int longestStreak,
    required double bestRate,
  }) {
    return [
      _Milestone(
        emoji: '🌱',
        title: 'First steps',
        description: 'Create your first habit',
        achieved: habitCount >= 1,
      ),
      _Milestone(
        emoji: '🧩',
        title: 'Habit collector',
        description: 'Track 5 habits at once',
        achieved: habitCount >= 5,
      ),
      _Milestone(
        emoji: '🔥',
        title: 'Week warrior',
        description: 'Reach a 7-day streak',
        achieved: longestStreak >= 7,
      ),
      _Milestone(
        emoji: '🏆',
        title: 'Month master',
        description: 'Reach a 30-day streak',
        achieved: longestStreak >= 30,
      ),
      _Milestone(
        emoji: '💎',
        title: 'Centurion',
        description: 'Reach a 100-day streak',
        achieved: longestStreak >= 100,
      ),
      _Milestone(
        emoji: '✅',
        title: 'Century club',
        description: 'Log 100 total check-ins',
        achieved: totalCheckIns >= 100,
      ),
      _Milestone(
        emoji: '⭐',
        title: 'Consistency king',
        description: 'Hit a 75% completion rate on a habit',
        achieved: bestRate >= 0.75,
      ),
    ];
  }

  void _shareOverview({
    required int habitCount,
    required int totalCheckIns,
    required int longestStreak,
    required double avgRate,
    required int achievedCount,
  }) {
    final text = '''
🔥 My HabitForge Progress

🌱 Active habits: $habitCount
✅ Total check-ins: $totalCheckIns
🏆 Longest streak: $longestStreak ${longestStreak == 1 ? 'day' : 'days'}
📊 Average completion rate: ${(avgRate * 100).round()}%
🏅 Milestones unlocked: $achievedCount

— Track your habits with HabitForge''';
    Share.share(text);
  }
}

class _Milestone {
  const _Milestone({
    required this.emoji,
    required this.title,
    required this.description,
    required this.achieved,
  });

  final String emoji;
  final String title;
  final String description;
  final bool achieved;
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.habitCount,
    required this.totalCheckIns,
    required this.longestStreak,
    required this.avgRate,
  });

  final int habitCount;
  final int totalCheckIns;
  final int longestStreak;
  final double avgRate;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard(
        emoji: '🌱',
        value: '$habitCount',
        label: habitCount == 1 ? 'Active habit' : 'Active habits',
        colors: const [Color(0xFF10B981), Color(0xFF34D399)],
      ),
      _SummaryCard(
        emoji: '✅',
        value: '$totalCheckIns',
        label: 'Total check-ins',
        colors: const [Color(0xFF6366F1), Color(0xFF818CF8)],
      ),
      _SummaryCard(
        emoji: '🏆',
        value: '$longestStreak',
        label: longestStreak == 1 ? 'Best streak (day)' : 'Best streak (days)',
        colors: const [HabitForgeColors.streakFire, Color(0xFFF97316)],
      ),
      _SummaryCard(
        emoji: '📊',
        value: '${(avgRate * 100).round()}%',
        label: 'Avg. completion',
        colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        for (var i = 0; i < cards.length; i++)
          cards[i].animate().fadeIn(duration: 320.ms, delay: (i * 60).ms).scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.colors,
  });

  final String emoji;
  final String value;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.first.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Vertical bar per habit showing its 30-day completion rate, colored with
/// the habit's own accent color and labeled with its emoji.
class _ComparisonBarChart extends StatelessWidget {
  const _ComparisonBarChart({required this.habits, required this.rates});

  final List<Habit> habits;
  final Map<String, double> rates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BarChart(
      BarChartData(
        maxY: 1,
        minY: 0,
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
              reservedSize: 40,
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
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= habits.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(habits[index].emoji, style: const TextStyle(fontSize: 16)),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(habits.length, (i) {
          final habit = habits[i];
          final color = HabitForgeColors.habitColors[habit.colorIndex % HabitForgeColors.habitColors.length];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: rates[habit.id] ?? 0,
                color: color,
                width: 22,
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

class _BestWorstRow extends StatelessWidget {
  const _BestWorstRow({required this.weekdayRates});

  final Map<int, double> weekdayRates;

  @override
  Widget build(BuildContext context) {
    final scored = weekdayRates.entries.where((e) => e.value > 0).toList();
    if (scored.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Check in for a few days and we\'ll show you your strongest and toughest days of the week.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    final best = scored.first;
    final worst = scored.last;

    return Row(
      children: [
        Expanded(
          child: _DayCard(
            emoji: '🌟',
            label: 'Best day',
            day: AppConstants.weekdayShort[best.key - 1],
            rate: best.value,
            colors: const [Color(0xFF10B981), Color(0xFF34D399)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DayCard(
            emoji: '💤',
            label: 'Toughest day',
            day: AppConstants.weekdayShort[worst.key - 1],
            rate: worst.value,
            colors: const [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.emoji,
    required this.label,
    required this.day,
    required this.rate,
    required this.colors,
  });

  final String emoji;
  final String label;
  final String day;
  final double rate;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.first.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            day,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            '${(rate * 100).round()}% completion',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone});

  final _Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achieved = milestone.achieved;

    return Card(
      color: achieved ? null : theme.colorScheme.surface.withValues(alpha: 0.5),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (achieved ? HabitForgeColors.checkGreen : theme.colorScheme.onSurface).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            milestone.emoji,
            style: TextStyle(fontSize: 22, color: achieved ? null : theme.colorScheme.onSurface.withValues(alpha: 0.35)),
          ),
        ),
        title: Text(
          milestone.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: achieved ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        subtitle: Text(
          milestone.description,
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: achieved ? 0.6 : 0.35)),
        ),
        trailing: Icon(
          achieved ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          color: achieved ? HabitForgeColors.checkGreen : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
