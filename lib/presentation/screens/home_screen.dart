import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/ads/ad_service.dart';
import '../../core/theme/habitforge_colors.dart';
import '../../data/models/habit.dart';
import '../../logic/blocs/habits/habits_bloc.dart';
import '../widgets/daily_progress_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/habit_tile.dart';
import '../widgets/motivational_quote.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HabitForge')),
      body: BlocBuilder<HabitsBloc, HabitsState>(
        builder: (context, state) {
          if (state.status == HabitsStatus.loading ||
              state.status == HabitsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final selectedDate = state.effectiveSelectedDate;
          final scheduledHabits = state.habitsForDate(selectedDate);
          final completed = scheduledHabits
              .where((h) => state.isCompletedOn(h.id, selectedDate))
              .length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateHeader(
                        selectedDate: selectedDate,
                        isToday: state.isToday,
                        onPrevious: () => context.read<HabitsBloc>().add(
                              SelectedDateChanged(
                                  selectedDate.subtract(const Duration(days: 1))),
                            ),
                        onNext: state.isToday
                            ? null
                            : () => context.read<HabitsBloc>().add(
                                  SelectedDateChanged(
                                      selectedDate.add(const Duration(days: 1))),
                                ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: DailyProgressBar(
                            completed: completed,
                            total: scheduledHabits.length,
                            color: HabitForgeColors.checkGreen,
                            label: state.isToday ? 'today' : 'on this day',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _OverallStreakCard(streak: state.overallStreak),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              if (state.habits.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    emoji: '🌱',
                    title: 'No habits yet',
                    message:
                        'Tap the + button below to plant your first habit and start building your streak.',
                    action: FilledButton.icon(
                      onPressed: () => _openAddHabit(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add your first habit'),
                    ),
                  ),
                )
              else if (scheduledHabits.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyState(
                      emoji: '🛌',
                      title: 'Nothing scheduled',
                      message: state.isToday
                          ? "You don't have any habits scheduled for today. Enjoy the rest!"
                          : "No habits were scheduled on this day.",
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: scheduledHabits.length,
                  itemBuilder: (context, index) {
                    final habit = scheduledHabits[index];
                    final isCompleted = state.isCompletedOn(habit.id, selectedDate);
                    final streak = state.currentStreakFor(habit);
                    return HabitTile(
                      habit: habit,
                      isCompleted: isCompleted,
                      streak: streak,
                      onToggle: () => _toggleCompletion(
                        context,
                        state: state,
                        habit: habit,
                        scheduledHabits: scheduledHabits,
                        selectedDate: selectedDate,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id)),
                      ),
                      onEdit: () => _openAddHabit(context, editing: habit),
                      onArchive: () => _confirmArchive(context, habit),
                    )
                        .animate()
                        .fadeIn(
                          duration: 360.ms,
                          delay: (60 * index).ms,
                        )
                        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
                  },
                ),
              const SliverToBoxAdapter(child: MotivationalQuote()),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddHabit(context),
        tooltip: 'Add habit',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  /// Toggles the habit's completion and, if that was the last habit scheduled
  /// for today, celebrates with an interstitial ad (a natural, non-naggy spot
  /// to show one — only fires once per fully-completed day).
  void _toggleCompletion(
    BuildContext context, {
    required HabitsState state,
    required Habit habit,
    required List<Habit> scheduledHabits,
    required DateTime selectedDate,
  }) {
    final wasCompleted = state.isCompletedOn(habit.id, selectedDate);
    context.read<HabitsBloc>().add(HabitCompletionToggled(habit: habit, date: selectedDate));

    if (!wasCompleted && state.isToday && scheduledHabits.isNotEmpty) {
      final completedBefore =
          scheduledHabits.where((h) => state.isCompletedOn(h.id, selectedDate)).length;
      if (completedBefore + 1 == scheduledHabits.length) {
        adMobService.showInterstitialIfReady();
      }
    }
  }

  void _openAddHabit(BuildContext context, {Habit? editing}) {
    final bloc = context.read<HabitsBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: AddHabitScreen(editing: editing),
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, Habit habit) {
    final bloc = context.read<HabitsBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Archive "${habit.name}"?'),
        content: const Text(
          'Archived habits are hidden from your daily list but their history is kept. You can restore them anytime from Settings.',
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
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.selectedDate,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = DateFormat('EEE, d MMM').format(selectedDate);
    final label = isToday ? 'Today, $formatted' : formatted;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: onPrevious,
          tooltip: 'Previous day',
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: onNext,
          tooltip: 'Next day',
        ),
      ],
    );
  }
}

class _OverallStreakCard extends StatelessWidget {
  const _OverallStreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HabitForgeColors.streakFire, Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HabitForgeColors.streakFire.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall streak',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak == 1 ? '1 day' : '$streak days',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
