import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Android ads only. Consent errors never prevent access to scores.
class AdsService {
  static final instance = AdsService();
  final ready = ValueNotifier(false);
  final privacyRequired = ValueNotifier(false);
  Future<void>? _initialization;
  bool testMode = true;
  String bannerId = '';
  String nativeId = '';
  String interstitialId = '';
  String rewardedId = '';
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!supported) return;
    try {
      final config = jsonDecode(await rootBundle.loadString('assets/ads/config.json')) as Map<String, dynamic>;
      testMode = kDebugMode || config['testMode'] != false;
      bannerId = config['bannerId'] as String? ?? '';
      nativeId = config['nativeId'] as String? ?? '';
      interstitialId = config['interstitialId'] as String? ?? '';
      rewardedId = config['rewardedId'] as String? ?? '';
      if (testMode) {
        if (bannerId.isNotEmpty) bannerId = 'ca-app-pub-3940256099942544/9214589741';
        if (nativeId.isNotEmpty) nativeId = 'ca-app-pub-3940256099942544/2247696110';
        if (interstitialId.isNotEmpty) interstitialId = 'ca-app-pub-3940256099942544/1033173712';
        if (rewardedId.isNotEmpty) rewardedId = 'ca-app-pub-3940256099942544/5224354917';
      }
      if ([bannerId, nativeId, interstitialId, rewardedId].every((id) => id.isEmpty)) return;
      // Preflight the platform channel so widget tests/unsupported hosts fail safely.
      await ConsentInformation.instance.getConsentStatus();
      final consent = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((error) {});
          } catch (_) {
            // The consent gate below remains authoritative on form errors.
          }
          if (!consent.isCompleted) consent.complete();
        },
        (error) { if (!consent.isCompleted) consent.complete(); },
      );
      await consent.future;
      privacyRequired.value = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(maxAdContentRating: MaxAdContentRating.g));
      await MobileAds.instance.initialize();
      ready.value = true;
      loadInterstitial();
      loadRewarded();
    } catch (_) {
      // Missing plugin (tests), offline consent, or unavailable ads: continue ad-free.
      ready.value = false;
    }
  }

  void loadInterstitial() {
    if (!ready.value || interstitialId.isEmpty || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial?.dispose();
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          _interstitial = null;
        },
      ),
    );
  }

  /// Shows only when explicitly called at a natural transition by the UI.
  Future<void> showInterstitial({VoidCallback? onDismissed}) async {
    final ad = _interstitial;
    if (ad == null || !ready.value) {
      loadInterstitial();
      onDismissed?.call();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        loadInterstitial();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        shownAd.dispose();
        loadInterstitial();
        onDismissed?.call();
      },
    );
    await ad.show();
  }

  void loadRewarded() {
    if (!ready.value || rewardedId.isEmpty || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded?.dispose();
          _rewarded = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          _rewarded = null;
        },
      ),
    );
  }

  /// Reward is granted only from Google's earned-reward callback.
  Future<void> showRewarded({required void Function(RewardItem reward) onEarnedReward}) async {
    final ad = _rewarded;
    if (ad == null || !ready.value) {
      loadRewarded();
      return;
    }
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        shownAd.dispose();
        loadRewarded();
      },
    );
    await ad.show(onUserEarnedReward: (shownAd, reward) => onEarnedReward(reward));
  }

  Future<void> showPrivacyOptions() async {
    ready.value = false;
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {});
      ready.value = await ConsentInformation.instance.canRequestAds();
      if (ready.value) {
        loadInterstitial();
        loadRewarded();
      }
    } catch (_) {
      ready.value = false;
    }
  }

  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
    _rewarded?.dispose();
    _rewarded = null;
  }
}
