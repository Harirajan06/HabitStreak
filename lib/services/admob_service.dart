import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../main.dart'; // Import to access scaffoldMessengerKey

class AdmobService {
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-7032488559595942/1531318834'; // Android Production ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7032488559595942/2195138598'; // iOS Production ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
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
          // DEBUG: Notify user ad is ready (remove in final production if desired)
          // scaffoldMessengerKey.currentState?.showSnackBar(
          //   const SnackBar(
          //     content: Text('Ad Loaded & Ready!'),
          //     backgroundColor: Colors.green,
          //     duration: Duration(seconds: 1),
          //   ),
          // );
        },
        onAdFailedToLoad: (err) {
          debugPrint("AdmobService: Interstitial ad failed to load: $err");
          _interstitialAd = null;
          // DEBUG: Show error to user
          // scaffoldMessengerKey.currentState?.showSnackBar(
          //   SnackBar(
          //     content: Text('Ad Failed: Code ${err.code} - ${err.message}'),
          //     backgroundColor: Colors.red,
          //     behavior: SnackBarBehavior.floating, // Prevent pushing FAB
          //     margin: const EdgeInsets.all(16),
          //     duration: const Duration(seconds: 4),
          //   ),
          // );
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
      // DEBUG: Notify user
      // scaffoldMessengerKey.currentState?.showSnackBar(
      //   const SnackBar(
      //     content: Text('Ad not ready yet. Please try again later.'),
      //     duration: Duration(seconds: 2),
      //     behavior: SnackBarBehavior.floating, // Prevent pushing FAB
      //   ),
      // );
      loadInterstitialAd(); // Load an ad to be ready for the next time.
    }
  }
}
