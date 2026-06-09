import 'package:pratik_app_kit/pratik_app_kit.dart';

import 'habitforge_ad_config.dart';

/// Single shared [AdMobService] instance — initialized once at startup in
/// `main.dart` and used to show a celebratory interstitial after a
/// fully-completed day (see [HabitsState.completedTodayCount]).
final adMobService = AdMobService(config: HabitForgeAdConfig());
