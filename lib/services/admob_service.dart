// import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    }
    return 'ca-app-pub-9133183118664083/7252895988'; // Production ID
  }

  InterstitialAd? _interstitialAd;

  void loadInterstitialAd({bool isPremium = false}) {
    if (isPremium) {
      if (_interstitialAd != null) {
        _interstitialAd!.dispose();
        _interstitialAd = null;
      }
      return;
    }

    if (_interstitialAd != null) return;

    debugPrint("AdmobService: Loading interstitial ad.");
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("AdmobService: Interstitial ad loaded successfully.");
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          debugPrint("AdmobService: Interstitial ad failed to load: $err");
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd({bool isPremium = false}) {
    if (isPremium) {
      debugPrint("AdmobService: Premium user, not showing ad.");
      return;
    }

    if (_interstitialAd != null) {
      debugPrint("AdmobService: Showing interstitial ad.");
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint("AdmobService: Interstitial ad dismissed.");
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // Pre-load next ad
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint("AdmobService: Interstitial ad failed to show: $err");
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // Pre-load next ad
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      debugPrint("AdmobService: Interstitial ad not ready.");
      loadInterstitialAd(); // Load an ad to be ready for the next time.
    }
  }
}
