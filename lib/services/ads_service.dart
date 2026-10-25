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

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!supported) return;
    try {
      final config = jsonDecode(await rootBundle.loadString('assets/ads/config.json')) as Map<String, dynamic>;
      testMode = kDebugMode || config['testMode'] != false;
      bannerId = config['bannerId'] as String? ?? '';
      nativeId = config['nativeId'] as String? ?? '';
      if (testMode) {
        if (bannerId.isNotEmpty) bannerId = 'ca-app-pub-3940256099942544/9214589741';
        if (nativeId.isNotEmpty) nativeId = 'ca-app-pub-3940256099942544/2247696110';
      }
      if (bannerId.isEmpty && nativeId.isEmpty) return;
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
    } catch (_) {
      // Missing plugin (tests), offline consent, or unavailable ads: continue ad-free.
      ready.value = false;
    }
  }

  Future<void> showPrivacyOptions() async {
    ready.value = false;
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {});
      ready.value = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      ready.value = false;
    }
  }
}
