import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pratik_app_kit/pratik_app_kit.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/habitforge_colors.dart';
import '../../data/models/habit.dart';
import '../../data/services/notification_service.dart';
import '../../logic/blocs/habits/habits_bloc.dart';
import '../widgets/empty_state.dart';

/// Appearance, reminders, archived-habit management and about info.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loadingNotificationPref = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final enabled = await NotificationService.isEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _loadingNotificationPref = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final bloc = context.read<HabitsBloc>();
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Notification permission was denied — enable it from your device settings to get reminders."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
    setState(() => _notificationsEnabled = value);
    await NotificationService.setEnabled(value, bloc.state.habits);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Appearance'),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode_rounded),
                title: const Text('Dark theme'),
                subtitle: const Text('Switch between light and dark appearance'),
                value: mode == ThemeMode.dark,
                onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
              );
            },
          ),
          const Divider(height: 1),
          _SectionHeader('Reminders'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_rounded),
            title: const Text('Daily reminders'),
            subtitle: Text(
              _loadingNotificationPref
                  ? 'Loading…'
                  : _notificationsEnabled
                      ? 'You\'ll be nudged at each habit\'s reminder time'
                      : 'Reminders are turned off for every habit',
            ),
            value: _notificationsEnabled,
            onChanged: _loadingNotificationPref ? null : _toggleNotifications,
          ),
          const Divider(height: 1),
          _SectionHeader('Habits'),
          BlocBuilder<HabitsBloc, HabitsState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.archive_rounded),
                title: const Text('Archived habits'),
                subtitle: Text(
                  state.archivedHabits.isEmpty
                      ? 'No archived habits'
                      : '${state.archivedHabits.length} archived — history is kept safe',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<HabitsBloc>(),
                      child: const _ArchivedHabitsScreen(),
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Share HabitForge'),
            subtitle: const Text('Tell a friend about the app'),
            onTap: () => Share.share(
              'Building better habits one day at a time 🌱 — check out HabitForge!',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Version'),
            subtitle: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Text(info == null ? 'Loading…' : '${info.version} (build ${info.buildNumber})');
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${AppConstants.appName} — small steps, every day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ArchivedHabitsScreen extends StatelessWidget {
  const _ArchivedHabitsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived habits')),
      body: BlocBuilder<HabitsBloc, HabitsState>(
        builder: (context, state) {
          final archived = state.archivedHabits;
          if (archived.isEmpty) {
            return const EmptyState(
              emoji: '🗄️',
              title: 'Nothing archived',
              message: 'Habits you archive show up here. Their history stays safe and you can restore them anytime.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: archived.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final habit = archived[index];
              final color = HabitForgeColors.habitColors[habit.colorIndex % HabitForgeColors.habitColors.length];
              return ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(habit.emoji, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Archived ${_formatRelative(habit.archivedAt!)}'),
                trailing: PopupMenuButton<_ArchivedAction>(
                  onSelected: (action) => _handleAction(context, action, habit),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: _ArchivedAction.restore, child: Text('Restore')),
                    PopupMenuItem(value: _ArchivedAction.delete, child: Text('Delete permanently')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatRelative(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 30) return '$days days ago';
    final months = (days / 30).floor();
    return months == 1 ? '1 month ago' : '$months months ago';
  }

  void _handleAction(BuildContext context, _ArchivedAction action, Habit habit) {
    final bloc = context.read<HabitsBloc>();
    switch (action) {
      case _ArchivedAction.restore:
        bloc.add(HabitArchiveToggled(habit));
      case _ArchivedAction.delete:
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Delete "${habit.name}"?'),
            content: const Text('This permanently removes the habit and its entire history. This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
                onPressed: () {
                  bloc.add(HabitDeleted(habit));
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
    }
  }
}

enum _ArchivedAction { restore, delete }
