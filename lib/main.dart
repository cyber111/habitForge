import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'data/services/hive_service.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.init();
  unawaited(adMobService.initialize());
  runApp(const HabitForgeApp());
}
