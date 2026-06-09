import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme/habitforge_colors.dart';

/// GitHub-profile-style activity heatmap.
///
/// [data] maps a normalized (midnight) date to an intensity level 0-4.
/// Renders [weeks] columns of 7 day-cells (Monday → Sunday), scrollable
/// horizontally and pre-scrolled to the most recent week.
class HabitHeatmap extends StatelessWidget {
  const HabitHeatmap({
    super.key,
    required this.data,
    required this.baseColor,
    this.weeks = 52,
    this.onCellTap,
  });

  final Map<DateTime, int> data;
  final Color baseColor;
  final int weeks;
  final void Function(DateTime date, int intensity)? onCellTap;

  static const double cellSize = 14;
  static const double cellGap = 3;
  static const double columnWidth = cellSize + cellGap;

  static DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final today = _normalize(DateTime.now());
    // Pad the grid out to the end of the current calendar week (Sunday) so
    // every column is a full Mon-Sun week.
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));
    final start = endOfWeek.subtract(Duration(days: weeks * 7 - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: weeks <= 0 ? 0 : (cellSize * 7 + cellGap * 6) + 4,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weeks, (week) {
                final weekStart = start.add(Duration(days: week * 7));
                return Padding(
                  padding: const EdgeInsets.only(right: cellGap),
                  child: Column(
                    children: List.generate(7, (day) {
                      final date = weekStart.add(Duration(days: day));
                      final isFuture = date.isAfter(today);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: cellGap),
                        child: isFuture
                            ? const SizedBox(width: cellSize, height: cellSize)
                            : _HeatmapCell(
                                date: date,
                                intensity: data[date] ?? 0,
                                baseColor: baseColor,
                                onTap: onCellTap,
                              ),
                      );
                    }),
                  ),
                ).animate().fadeIn(duration: 260.ms, delay: (week * 12).ms);
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _MonthLabels(start: start, weeks: weeks),
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.date,
    required this.intensity,
    required this.baseColor,
    this.onTap,
  });

  final DateTime date;
  final int intensity;
  final Color baseColor;
  final void Function(DateTime date, int intensity)? onTap;

  Color get _color {
    switch (intensity) {
      case 4:
        return baseColor;
      case 3:
        return baseColor.withValues(alpha: 0.75);
      case 2:
        return baseColor.withValues(alpha: 0.5);
      case 1:
        return baseColor.withValues(alpha: 0.25);
      default:
        return HabitForgeColors.heatmap0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(date, intensity),
      child: Container(
        width: HabitHeatmap.cellSize,
        height: HabitHeatmap.cellSize,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(3.5),
        ),
      ),
    );
  }
}

class _MonthLabels extends StatelessWidget {
  const _MonthLabels({required this.start, required this.weeks});

  final DateTime start;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );

    int? lastMonth;
    final labels = <Widget>[];
    for (var week = 0; week < weeks; week++) {
      final weekStart = start.add(Duration(days: week * 7));
      String? label;
      if (lastMonth != weekStart.month) {
        label = DateFormat.MMM().format(weekStart);
        lastMonth = weekStart.month;
      }
      labels.add(SizedBox(
        width: HabitHeatmap.columnWidth,
        child: label == null ? null : Text(label, style: style),
      ));
    }

    return SizedBox(
      height: 16,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(children: labels),
      ),
    );
  }
}
