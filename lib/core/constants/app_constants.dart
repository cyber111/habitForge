class AppConstants {
  AppConstants._();

  static const String appName = 'HabitForge';

  /// Default emoji choices shown in the emoji picker grid.
  static const List<String> emojiChoices = [
    '💧', '🏃', '📚', '🧘', '🥗', '😴', '📝', '👟',
    '📵', '💻', '🗣️', '🙏', '🚫', '⏰', '🦷', '🎯',
    '🎨', '🎵', '💪', '🚴', '🧹', '🌱', '☕', '🍎',
    '✍️', '🧠', '❤️', '🌞', '🌙', '🔥', '⭐', '✅',
  ];

  /// Day labels, indexed by DateTime.weekday (1 = Monday ... 7 = Sunday).
  static const List<String> weekdayShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static const List<String> weekdayInitial = [
    'M', 'T', 'W', 'T', 'F', 'S', 'S',
  ];

  static const List<int> allWeekdays = [1, 2, 3, 4, 5, 6, 7];
}
