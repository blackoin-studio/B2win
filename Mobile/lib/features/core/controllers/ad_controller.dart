import 'package:b2win/data/models/ad_settings_model.dart';
import 'package:b2win/data/repositories/ad_settings_repository.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdController extends GetxController {
  final AdSettingsRepository _repository;
  final bool enableSdkInitialization;

  AdController({
    required AdSettingsRepository repository,
    this.enableSdkInitialization = true,
  }) : _repository = repository;

  final Rx<AdSettingsModel> settings = const AdSettingsModel().obs;
  final RxBool isSdkInitialized = false.obs;

  InterstitialAd? _interstitialAd;
  int _interactionCount = 0;
  bool _isLoadingInterstitial = false;

  @override
  void onInit() {
    super.onInit();
    fetchAdSettings();
  }

  Future<void> fetchAdSettings() async {
    try {
      final fetched = await _repository.getAdSettings();
      settings.value = fetched;

      if (!fetched.adsEnabled) {
        _disposeInterstitial();
        return;
      }

      if (enableSdkInitialization && fetched.isSupportedMobilePlatform) {
        if (!isSdkInitialized.value) {
          await MobileAds.instance.initialize();
          isSdkInitialized.value = true;
        }
        if (fetched.interstitialEnabled) {
          _preloadInterstitialAd();
        } else {
          _disposeInterstitial();
        }
      }
    } catch (_) {
      // Fail silently; ads stay disabled if the backend cannot be reached
    }
  }

  void _preloadInterstitialAd() {
    final current = settings.value;
    if (!enableSdkInitialization ||
        !current.isSupportedMobilePlatform ||
        !current.adsEnabled ||
        !current.interstitialEnabled ||
        _interstitialAd != null ||
        _isLoadingInterstitial) {
      return;
    }

    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: current.activeInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoadingInterstitial = false;
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Tracks user interactions (such as opening a blog post) and shows an
  /// interstitial ad every `interstitialInterval` actions if enabled by Admin.
  void recordInteractionAndMaybeShowInterstitial() {
    final current = settings.value;
    if (!current.adsEnabled || !current.interstitialEnabled) {
      return;
    }

    _interactionCount++;
    if (_interactionCount >= current.interstitialInterval) {
      if (_interstitialAd != null) {
        _interactionCount = 0;
        _interstitialAd!.show();
        _interstitialAd = null;
      } else {
        _preloadInterstitialAd();
      }
    }
  }

  void _disposeInterstitial() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoadingInterstitial = false;
  }

  @override
  void onClose() {
    _disposeInterstitial();
    super.onClose();
  }
}

