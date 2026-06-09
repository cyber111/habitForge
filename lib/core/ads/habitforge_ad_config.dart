import 'package:pratik_app_kit/pratik_app_kit.dart';

/// Ad placement configuration for HabitForge.
///
/// Uses Google's official sample ad unit ids so the app can be built and run
/// without a real AdMob account. Swap these for production ids before release.
class HabitForgeAdConfig extends AdmobConfigBase {
  @override
  bool get adsEnabled => false;

  @override
  bool get bannerAdsEnabled => false;

  @override
  bool get interstitialAdsEnabled => true;

  @override
  String get bannerAdUnitId => 'ca-app-pub-3940256099942544/6300978111';

  @override
  String get interstitialAdUnitId => 'ca-app-pub-3940256099942544/1033173712';
}
