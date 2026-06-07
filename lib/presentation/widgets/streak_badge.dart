import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/habitforge_colors.dart';

/// "🔥 15" pill — pulses gently once the streak passes a week.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak, this.fontSize = 13});

  final int streak;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: HabitForgeColors.streakFireBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: fontSize)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: GoogleFonts.spaceGrotesk(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: HabitForgeColors.streakFire,
            ),
          ),
        ],
      ),
    );

    if (streak > 7) {
      return badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.08, duration: 900.ms, curve: Curves.easeInOut);
    }
    return badge;
  }
}
