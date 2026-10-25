import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

enum ScoreXAdFormat { banner, native }

/// A dedicated, labelled layout slot; never overlays scores or navigation.
class ScoreXAdSlot extends StatefulWidget {
  const ScoreXAdSlot({super.key, this.format = ScoreXAdFormat.banner});
  final ScoreXAdFormat format;
  @override
  State<ScoreXAdSlot> createState() => _ScoreXAdSlotState();
}

class _ScoreXAdSlotState extends State<ScoreXAdSlot> {
  final _service = AdsService.instance;
  AdWithView? _ad;
  bool _loaded = false;
  bool _attempted = false;
  int _width = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _service.ready.addListener(_consentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_service.initialize());
    });
  }

  void _consentChanged() {
    _reset();
    if (mounted) setState(() {});
  }

  void _reset() {
    _generation++;
    _attempted = false;
    final previous = _ad;
    _ad = null;
    _loaded = false;
    // Remove the platform view before disposing its ad.
    WidgetsBinding.instance.addPostFrameCallback((_) { previous?.dispose(); });
  }

  Future<void> _load(int width, int generation) async {
    if (!mounted || !_service.ready.value || generation != _generation) return;
    AdWithView? candidate;
    void loaded(Ad ad) {
      if (!mounted || generation != _generation || !_service.ready.value) {
        ad.dispose();
        return;
      }
      setState(() { _ad = ad as AdWithView; _loaded = true; });
    }
    void failed(Ad ad, LoadAdError error) {
      ad.dispose();
      if (mounted && generation == _generation) {
        setState(() { _ad = null; _loaded = false; });
      }
    }
    try {
      if (widget.format == ScoreXAdFormat.native) {
        candidate = NativeAd(
          adUnitId: _service.nativeId,
          request: const AdRequest(),
          listener: NativeAdListener(onAdLoaded: loaded, onAdFailedToLoad: failed),
          nativeTemplateStyle: NativeTemplateStyle(
            templateType: TemplateType.medium,
            mainBackgroundColor: const Color(0xFF102820),
            cornerRadius: 16,
            primaryTextStyle: NativeTemplateTextStyle(textColor: Colors.white, size: 16),
            secondaryTextStyle: NativeTemplateTextStyle(textColor: const Color(0xFFCCE5D9), size: 13),
            tertiaryTextStyle: NativeTemplateTextStyle(textColor: const Color(0xFFCCE5D9), size: 12),
            callToActionTextStyle: NativeTemplateTextStyle(
              textColor: const Color(0xFF071A14), backgroundColor: const Color(0xFFFFC857), size: 14),
          ),
        );
      } else {
        final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
        if (!mounted || generation != _generation || !_service.ready.value || size == null) return;
        candidate = BannerAd(
          adUnitId: _service.bannerId, size: size, request: const AdRequest(),
          listener: BannerAdListener(onAdLoaded: loaded, onAdFailedToLoad: failed),
        );
      }
      _ad = candidate;
      if (candidate is BannerAd) await candidate.load();
      if (candidate is NativeAd) await candidate.load();
    } catch (_) {
      candidate?.dispose();
      if (mounted && generation == _generation) setState(() { _ad = null; _loaded = false; });
    }
  }

  @override
  void dispose() {
    _generation++;
    _service.ready.removeListener(_consentChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.ready.value) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.floor();
      if (width < 320) return const SizedBox.shrink();
      if (_width != width) {
        _reset();
        _width = width;
      }
      if (!_attempted) {
        _attempted = true;
        // One attempt per size/consent change, rather than on every score refresh.
        final generation = ++_generation;
        _loaded = false;
        WidgetsBinding.instance.addPostFrameCallback((_) { _load(width, generation); });
      }
      final ad = _ad;
      if (!_loaded || ad == null) return const SizedBox.shrink();
      final isNative = widget.format == ScoreXAdFormat.native;
      final height = ad is BannerAd ? ad.size.height.toDouble() : 360.0;
      final adWidth = ad is BannerAd ? ad.size.width.toDouble() : width.clamp(320, 400).toDouble();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_service.testMode ? 'ADVERTISEMENT • TEST AD' : 'ADVERTISEMENT',
            style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 6),
          SizedBox(width: adWidth, height: isNative ? 360 : height, child: AdWidget(ad: ad)),
        ]),
      );
    });
  }
}

class AdsPrivacyTile extends StatelessWidget {
  const AdsPrivacyTile({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: AdsService.instance.privacyRequired,
    builder: (context, required, child) => !required ? const SizedBox.shrink() : Card(
      child: ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Ad privacy choices'),
        subtitle: const Text('Review your advertising consent'),
        onTap: () => AdsService.instance.showPrivacyOptions(),
      ),
    ),
  );
}
