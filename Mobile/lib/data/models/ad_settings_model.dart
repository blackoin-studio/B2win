import 'dart:io';
import 'package:flutter/foundation.dart';

class AdSettingsModel {
  final bool adsEnabled;
  final bool testMode;
  final bool bannerEnabled;
  final bool interstitialEnabled;
  final bool showOnHome;
  final bool showOnBlog;
  final int interstitialInterval;
  final String androidBannerUnitId;
  final String iosBannerUnitId;
  final String androidInterstitialUnitId;
  final String iosInterstitialUnitId;

  static const String testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testIosBannerId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String testAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testIosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  const AdSettingsModel({
    this.adsEnabled = false,
    this.testMode = true,
    this.bannerEnabled = true,
    this.interstitialEnabled = true,
    this.showOnHome = true,
    this.showOnBlog = true,
    this.interstitialInterval = 3,
    this.androidBannerUnitId = testAndroidBannerId,
    this.iosBannerUnitId = testIosBannerId,
    this.androidInterstitialUnitId = testAndroidInterstitialId,
    this.iosInterstitialUnitId = testIosInterstitialId,
  });

  factory AdSettingsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final int parsedInterval =
        int.tryParse(payload['interstitialInterval']?.toString() ?? '3') ?? 3;

    return AdSettingsModel(
      adsEnabled: payload['adsEnabled'] == true,
      testMode: payload['testMode'] != false,
      bannerEnabled: payload['bannerEnabled'] != false,
      interstitialEnabled: payload['interstitialEnabled'] != false,
      showOnHome: payload['showOnHome'] != false,
      showOnBlog: payload['showOnBlog'] != false,
      interstitialInterval: parsedInterval.clamp(1, 50),
      androidBannerUnitId:
          (payload['androidBannerUnitId']?.toString().trim().isNotEmpty ??
                  false)
              ? payload['androidBannerUnitId'].toString().trim()
              : testAndroidBannerId,
      iosBannerUnitId:
          (payload['iosBannerUnitId']?.toString().trim().isNotEmpty ?? false)
              ? payload['iosBannerUnitId'].toString().trim()
              : testIosBannerId,
      androidInterstitialUnitId:
          (payload['androidInterstitialUnitId']?.toString().trim().isNotEmpty ??
                  false)
              ? payload['androidInterstitialUnitId'].toString().trim()
              : testAndroidInterstitialId,
      iosInterstitialUnitId:
          (payload['iosInterstitialUnitId']?.toString().trim().isNotEmpty ??
                  false)
              ? payload['iosInterstitialUnitId'].toString().trim()
              : testIosInterstitialId,
    );
  }

  bool get isSupportedMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get activeBannerUnitId {
    if (!kIsWeb && Platform.isIOS) {
      return testMode ? testIosBannerId : iosBannerUnitId;
    }
    return testMode ? testAndroidBannerId : androidBannerUnitId;
  }

  String get activeInterstitialUnitId {
    if (!kIsWeb && Platform.isIOS) {
      return testMode ? testIosInterstitialId : iosInterstitialUnitId;
    }
    return testMode ? testAndroidInterstitialId : androidInterstitialUnitId;
  }

  bool shouldShowBanner(String placement) {
    if (!adsEnabled || !bannerEnabled) return false;
    if (placement == 'home') return showOnHome;
    if (placement == 'blog') return showOnBlog;
    return true;
  }
}

