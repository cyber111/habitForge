import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/habitforge_colors.dart';

/// "5/7 habits completed" with a smoothly animated fill bar.
class DailyProgressBar extends StatelessWidget {
  const DailyProgressBar({
    super.key,
    required this.completed,
    required this.total,
    required this.color,
    required this.label,
  });

  final int completed;
  final int total;
  final Color color;

  /// e.g. "Today" / "Sun, 7 Jun" — shown alongside the count.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : completed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              total == 0
                  ? 'No habits scheduled $label'
                  : '$completed/$total habits completed',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: HabitForgeColors.heatmap0.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
