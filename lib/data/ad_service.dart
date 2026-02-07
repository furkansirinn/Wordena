import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'dart:io';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  // ========== BANNER ADS ==========
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // ========== REWARDED ADS ==========
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // ========== INTERSTITIAL ADS (YENİ) ==========
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // ========== APP IDs ==========
  static const String androidAppId = 'ca-app-pub-5055315012077821~1042467000';
  static const String iosAppId = 'ca-app-pub-5055315012077821~7775396310';

  // ========== BANNER AD UNIT IDs ==========
  static const String androidBannerId = 'ca-app-pub-5055315012077821/5855809980';
  static const String iosBannerId = 'ca-app-pub-5055315012077821/7224731979';

  // ========== REWARDED AD UNIT IDs (ÖDÜL: +5 SWIPE) ==========
  static const String androidRewardedId = 'ca-app-pub-5055315012077821/9850895312';
  static const String iosRewardedId = 'ca-app-pub-5055315012077821/3256856362';

  // ========== INTERSTITIAL AD UNIT IDs (YENİ - 30 SORUDA BİR) ==========
  static const String androidInterstitialId =
      'ca-app-pub-5055315012077821/3608476393';
  static const String iosInterstitialId =
      'ca-app-pub-5055315012077821/6543210987';

  // ========== AD UNIT ID GETTERS ==========
  static String get bannerAdUnitId =>
      Platform.isAndroid ? androidBannerId : iosBannerId;

  static String get rewardedAdUnitId =>
      Platform.isAndroid ? androidRewardedId : iosRewardedId;

  static String get interstitialAdUnitId =>
      Platform.isAndroid ? androidInterstitialId : iosInterstitialId;

  // ========== INITIALIZATION ==========
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ========== BANNER ADS ==========
  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner Ad Loaded');
          _isBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner Ad Failed: ${error.message}');
          ad.dispose();
          _isBannerAdReady = false;
        },
      ),
    );

    _bannerAd!.load();
  }

  BannerAd? get bannerAd => _isBannerAdReady ? _bannerAd : null;

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
  }

  // ========== REWARDED ADS (ÖDÜl: +5 SWIPE, 30 DAKİKA YOK) ==========
  // ⏰ 30 dakika limitini kontrol et
  bool _canShowRewardedAd() {
    try {
      final box = Hive.box('settingsBox');
      final lastTime = box.get('lastRewardedAdTime', defaultValue: 0) as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyMinutesMs = 30 * 60 * 1000;

      return (now - lastTime) >= thirtyMinutesMs;
    } catch (e) {
      print('⚠️ Error checking reward cooldown: $e');
      return true; // Hata varsa yükle
    }
  }

  // ⏰ Kalan zamanı getir (SettingsPage için)
  int getRewardedAdCooldownSeconds() {
    try {
      final box = Hive.box('settingsBox');
      final lastTime = box.get('lastRewardedAdTime', defaultValue: 0) as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyMinutesMs = 30 * 60 * 1000;
      final remaining = thirtyMinutesMs - (now - lastTime);

      return remaining > 0 ? (remaining / 1000).ceil() : 0;
    } catch (e) {
      return 0;
    }
  }

  void loadRewardedAd() {
    // 30 dakika kontrolü
    if (!_canShowRewardedAd()) {
      print('⏳ Rewarded Ad 30 dakikada bir izlenebilir. Lütfen bekle!');
      _isRewardedAdReady = false;
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Rewarded Ad Loaded - Reward: +5 Swipe');
          _rewardedAd = ad;
          _isRewardedAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('❌ Rewarded Ad Failed: ${error.message}');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  bool get isRewardedAdReady => _isRewardedAdReady;

  void showRewardedAd({
    required Function(int rewardAmount) onRewardEarned,
    required VoidCallback onAdClosed,
  }) {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      print('⚠️ Rewarded Ad not ready');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('📺 Rewarded Ad Shown');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('❌ Rewarded Ad Dismissed');
        ad.dispose();
        _isRewardedAdReady = false;
        onAdClosed();
        // Sonraki ad'ı yükle
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Rewarded Ad Failed to Show: ${error.message}');
        ad.dispose();
        _isRewardedAdReady = false;
        onAdClosed();
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // ⭐️ ÖDÜL: +5 SWIPE (Önceden 30 dakika, şimdi +5 swipe)
        print('🎁 User Earned Reward: +5 Swipe');
        onRewardEarned(5); // Sabit 5 swipe
      },
    );

    _rewardedAd = null;
  }

  // ========== INTERSTITIAL ADS (YENİ - 30 SORUDA BİR) ==========
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Interstitial Ad Loaded (30 soruda bir gösterilecek)');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('❌ Interstitial Ad Failed: ${error.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  bool get isInterstitialAdReady => _isInterstitialAdReady;

  /// 30 soruda bir çağrılacak
  void showInterstitialAd({
    required VoidCallback onAdClosed,
  }) {
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      print('⚠️ Interstitial Ad not ready');
      loadInterstitialAd(); // Sonraki için yükle
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('📺 Interstitial Ad Shown (30 soru doldu!)');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('❌ Interstitial Ad Dismissed');
        ad.dispose();
        _isInterstitialAdReady = false;
        onAdClosed();
        // Sonraki ad'ı yükle (30 soru sonra gösterilecek)
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Interstitial Ad Failed to Show: ${error.message}');
        ad.dispose();
        _isInterstitialAdReady = false;
        onAdClosed();
        loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ========== DISPOSE ==========
  void dispose() {
    disposeBannerAd();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }
}