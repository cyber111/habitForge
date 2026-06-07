import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/habitforge_colors.dart';
import '../../data/models/habit.dart';
import 'streak_badge.dart';

/// One row on the home screen:
/// emoji + name, active-day pills, streak badge and a check-in circle.
/// Swipe right → archive, swipe left → edit.
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.streak,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
  });

  final Habit habit;
  final bool isCompleted;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  Color get _color =>
      HabitForgeColors.habitColors[habit.colorIndex % HabitForgeColors.habitColors.length];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;

    return Dismissible(
      key: ValueKey('habit_tile_${habit.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onArchive();
        } else {
          onEdit();
        }
        return false;
      },
      background: _SwipeBackground(
        icon: Icons.archive_rounded,
        label: 'Archive',
        color: HabitForgeColors.frozenBlue,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBackground(
        icon: Icons.edit_rounded,
        label: 'Edit',
        color: HabitForgeColors.checkGreen,
        alignment: Alignment.centerRight,
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(habit.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              habit.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StreakBadge(streak: streak),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ActiveDaysRow(habit: habit, color: color),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _CompletionCheckbox(
                    isCompleted: isCompleted,
                    color: color,
                    onTap: onToggle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveDaysRow extends StatelessWidget {
  const _ActiveDaysRow({required this.habit, required this.color});

  final Habit habit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (habit.isDaily) {
      return Text(
        'Every day',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return Row(
      children: List.generate(7, (i) {
        final weekday = i + 1;
        final isActive = habit.isActiveOnDay(weekday);
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color.withValues(alpha: 0.16) : Colors.transparent,
            ),
            child: Text(
              AppConstants.weekdayInitial[i],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.28),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Circular check-in control: scale-bounce + checkmark draw + haptics.
class _CompletionCheckbox extends StatefulWidget {
  const _CompletionCheckbox({
    required this.isCompleted,
    required this.color,
    required this.onTap,
  });

  final bool isCompleted;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_CompletionCheckbox> createState() => _CompletionCheckboxState();
}

class _CompletionCheckboxState extends State<_CompletionCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _bounce = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.28).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.28, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  void _handleTap() {
    HapticFeedback.mediumImpact();
    if (!widget.isCompleted) {
      _controller.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (context, child) => Transform.scale(scale: _bounce.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isCompleted ? widget.color : widget.color.withValues(alpha: 0.10),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: widget.isCompleted
                ? const Icon(Icons.check_rounded, key: ValueKey('done'), color: Colors.white, size: 20)
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.icon,
    required this.label,
    required this.color,
    required this.alignment,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.nunito(color: color, fontWeight: FontWeight.w700)),
              ]
            : [
                Text(label, style: GoogleFonts.nunito(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Icon(icon, color: color),
              ],
      ),
    );
  }
}
