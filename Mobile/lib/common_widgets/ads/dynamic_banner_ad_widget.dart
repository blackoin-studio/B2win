import 'package:b2win/features/core/controllers/ad_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class DynamicBannerAdWidget extends StatefulWidget {
  final String placement; // 'home' or 'blog'

  const DynamicBannerAdWidget({
    super.key,
    required this.placement,
  });

  @override
  State<DynamicBannerAdWidget> createState() => _DynamicBannerAdWidgetState();
}

class _DynamicBannerAdWidgetState extends State<DynamicBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  String? _loadedUnitId;
  Worker? _settingsWorker;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AdController>()) {
      final adController = Get.find<AdController>();
      _syncBannerWithSettings(adController);
      _settingsWorker = ever(adController.settings, (_) {
        if (mounted) {
          _syncBannerWithSettings(adController);
        }
      });
    }
  }

  void _syncBannerWithSettings(AdController adController) {
    final cfg = adController.settings.value;
    if (!cfg.shouldShowBanner(widget.placement) ||
        !cfg.isSupportedMobilePlatform) {
      _disposeBanner();
      return;
    }

    final unitId = cfg.activeBannerUnitId;
    if (_bannerAd != null && _loadedUnitId == unitId) {
      return;
    }

    _disposeBanner();
    _loadedUnitId = unitId;

    final banner = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
        },
      ),
    );

    banner.load();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _loadedUnitId = null;
    if (_isLoaded && mounted) {
      setState(() {
        _isLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _settingsWorker?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdController>()) {
      return const SizedBox.shrink();
    }

    final adController = Get.find<AdController>();

    return Obx(() {
      final cfg = adController.settings.value;
      if (!cfg.shouldShowBanner(widget.placement) ||
          !_isLoaded ||
          _bannerAd == null) {
        return const SizedBox.shrink();
      }

      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 6),
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    });
  }
}

