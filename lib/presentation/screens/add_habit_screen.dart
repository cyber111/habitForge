import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/preset_habits.dart';
import '../../core/theme/habitforge_colors.dart';
import '../../data/models/habit.dart';
import '../../logic/blocs/habits/habits_bloc.dart';

/// Create or edit a habit. Pass [editing] to pre-fill the form for editing.
class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key, this.editing});

  final Habit? editing;

  bool get isEditing => editing != null;

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  late final TextEditingController _nameController;
  late String _emoji;
  late int _colorIndex;
  late Set<int> _activeDays;
  late bool _reminderEnabled;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _emoji = editing?.emoji ?? AppConstants.emojiChoices.first;
    _colorIndex = editing?.colorIndex ?? 0;
    _activeDays = (editing?.activeDays ?? AppConstants.allWeekdays).toSet();
    _reminderEnabled = editing?.hasReminder ?? false;
    _reminderTime = editing?.hasReminder == true
        ? TimeOfDay(hour: editing!.reminderHour!, minute: editing.reminderMinute!)
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isDaily => _activeDays.length == 7;

  List<Map<String, dynamic>> get _matchingPresets {
    final query = _nameController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return PresetHabits.suggestions
        .where((p) => (p['name'] as String).toLowerCase().contains(query))
        .take(4)
        .toList();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'] as String;
      _nameController.selection =
          TextSelection.collapsed(offset: _nameController.text.length);
      _emoji = preset['emoji'] as String;
      _colorIndex = preset['colorIndex'] as int;
    });
  }

  void _toggleDay(int weekday) {
    setState(() {
      if (_activeDays.contains(weekday)) {
        if (_activeDays.length > 1) _activeDays.remove(weekday);
      } else {
        _activeDays.add(weekday);
      }
    });
  }

  void _toggleDaily() {
    setState(() {
      if (_isDaily) {
        _activeDays = {DateTime.now().weekday};
      } else {
        _activeDays = AppConstants.allWeekdays.toSet();
      }
    });
  }

  Future<void> _pickEmoji() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EmojiPickerSheet(current: _emoji),
    );
    if (selected != null) setState(() => _emoji = selected);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your habit a name first.')),
      );
      return;
    }

    final activeDaysList = _activeDays.toList()..sort();
    final reminderHour = _reminderEnabled ? _reminderTime?.hour : null;
    final reminderMinute = _reminderEnabled ? _reminderTime?.minute : null;

    final bloc = context.read<HabitsBloc>();
    if (widget.isEditing) {
      bloc.add(HabitUpdated(
        habit: widget.editing!,
        name: name,
        emoji: _emoji,
        colorIndex: _colorIndex,
        activeDays: activeDaysList,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        clearReminder: !_reminderEnabled,
      ));
    } else {
      bloc.add(HabitAdded(
        name: name,
        emoji: _emoji,
        colorIndex: _colorIndex,
        activeDays: activeDaysList,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = HabitForgeColors.habitColors[_colorIndex % HabitForgeColors.habitColors.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Habit' : 'New Habit'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionLabel('Quick suggestions'),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PresetHabits.suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = PresetHabits.suggestions[index];
                return ActionChip(
                  avatar: Text(preset['emoji'] as String),
                  label: Text(preset['name'] as String),
                  onPressed: () => _applyPreset(preset),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmojiButton(emoji: _emoji, color: color, onTap: _pickEmoji),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Habit name',
                        hintText: 'e.g. Morning Run',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_matchingPresets.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _matchingPresets.map((p) {
                            return ActionChip(
                              avatar: Text(p['emoji'] as String),
                              label: Text(p['name'] as String),
                              onPressed: () => _applyPreset(p),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Color'),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: HabitForgeColors.habitColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = HabitForgeColors.habitColors[index];
                final selected = index == _colorIndex;
                return GestureDetector(
                  onTap: () => setState(() => _colorIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: selected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: c.withValues(alpha: 0.4),
                          blurRadius: selected ? 10 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Frequency'),
          Row(
            children: [
              Expanded(
                child: Text(
                  _isDaily ? 'Every day' : 'Custom days',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(value: _isDaily, onChanged: (_) => _toggleDaily()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final weekday = i + 1;
              final selected = _activeDays.contains(weekday);
              return GestureDetector(
                onTap: () => _toggleDay(weekday),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? color : color.withValues(alpha: 0.10),
                  ),
                  child: Text(
                    AppConstants.weekdayInitial[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : color,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Reminder'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _reminderEnabled,
                  title: const Text('Daily reminder'),
                  subtitle: Text(
                    _reminderEnabled && _reminderTime != null
                        ? 'Remind me at ${_reminderTime!.format(context)}'
                        : 'Get a nudge so you never miss a day',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _reminderEnabled = value;
                      if (value && _reminderTime == null) {
                        _reminderTime = const TimeOfDay(hour: 8, minute: 0);
                      }
                    });
                  },
                ),
                if (_reminderEnabled)
                  ListTile(
                    leading: const Icon(Icons.access_time_rounded),
                    title: const Text('Reminder time'),
                    trailing: Text(
                      _reminderTime?.format(context) ?? '8:00 AM',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                    ),
                    onTap: _pickReminderTime,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.isEditing ? 'Save changes' : 'Create habit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({required this.emoji, required this.color, required this.onTap});

  final String emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Choose an emoji', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: AppConstants.emojiChoices.map((emoji) {
              final selected = emoji == current;
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(emoji),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
