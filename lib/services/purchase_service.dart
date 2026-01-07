import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:hive/hive.dart';
import '../services/hive_service.dart';

class PurchaseService {
  // ... (existing code)

  Future<void> showPaywall() async {
    try {
      final paywallResult =
          await RevenueCatUI.presentPaywallIfNeeded(_entitlementId);
      debugPrint('Paywall result: $paywallResult');
    } catch (e) {
      debugPrint('Error showing paywall: $e');
    }
  }

  Future<void> showCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Error showing customer center: $e');
    }
  }

  // ... (rest of class)
  PurchaseService._privateConstructor();
  static final PurchaseService instance = PurchaseService._privateConstructor();

  // STREAM CONTROLLERS
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  final _subscriptionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStatusStream =>
      _subscriptionStatusController.stream;

  // CONFIGURATION
  // RevenueCat API key (set from user input)
  static const _apiKey = 'test_cafUGSoLzloRwcCwdfxeiTTnZuq';
  static const _entitlementId = 'Habit Sensai Pro';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);

    await Purchases.configure(configuration);
    _isInitialized = true;

    // Log User ID for debugging
    final appUserId = await Purchases.appUserID;
    debugPrint('RevenueCat App User ID: $appUserId');

    await _checkSubscriptionStatus();

    // Listen to customer info updates
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updatePremiumStatus(customerInfo);
    });
  }

  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } on PlatformException catch (e) {
      debugPrint('Error fetching offerings: $e');
      return null;
    }
  }

  Future<void> purchasePackage(Package package) async {
    try {
      _statusController.add('pending');
      final customerInfo = await Purchases.purchasePackage(package);
      _updatePremiumStatus(customerInfo);

      if (customerInfo.entitlements.all[_entitlementId]?.isActive ?? false) {
        _statusController.add('success');
      } else {
        // Purchase successful but no entitlement (rare)
        _statusController
            .add('error: Purchase completed but premium not active');
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        _statusController.add('canceled');
      } else {
        _statusController.add('error: ${e.message}');
      }
    } catch (e) {
      _statusController.add('error: $e');
    }
  }

  Future<void> restorePurchases() async {
    try {
      _statusController.add('pending');
      final customerInfo = await Purchases.restorePurchases();
      _updatePremiumStatus(customerInfo);

      // Check if anything was actually restored
      if (customerInfo.entitlements.active.isNotEmpty) {
        _statusController.add('success');
      } else {
        _statusController.add('error: No purchases to restore');
      }
    } on PlatformException catch (e) {
      _statusController.add('error: ${e.message}');
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    if (!_isInitialized) return;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updatePremiumStatus(customerInfo);
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  Future<void> _updatePremiumStatus(CustomerInfo customerInfo) async {
    // Determine whether the configured entitlement is active.
    // We attempt a tolerant match in case the entitlement identifier
    // in RevenueCat differs by whitespace/casing (e.g. 'HabitSensai Pro').
    final allEntitlementKeys =
        customerInfo.entitlements.all.keys.map((k) => k).toList();
    final activeEntitlementKeys =
        customerInfo.entitlements.active.keys.map((k) => k).toList();

    // Normalization helper: lowercase and remove non-alphanumerics
    String normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final normTarget = normalize(_entitlementId);

    String? matchedKey;
    // 1) Exact lookup first
    if (customerInfo.entitlements.all.containsKey(_entitlementId)) {
      matchedKey = _entitlementId;
    } else {
      // 2) Try tolerant match across all entitlement keys
      for (final k in allEntitlementKeys) {
        if (normalize(k) == normTarget) {
          matchedKey = k;
          break;
        }
      }
    }

    final bool isPremium = matchedKey != null
        ? (customerInfo.entitlements.all[matchedKey]?.isActive ?? false)
        : false;

    // Debug: list all entitlements and active ones for troubleshooting
    debugPrint('Updating Premium Status (Configured entitlement: $_entitlementId)');
    debugPrint(' - Normalized configured entitlement: $normTarget');
    debugPrint(' - All entitlements: $allEntitlementKeys');
    debugPrint(' - Active entitlements: $activeEntitlementKeys');
    debugPrint(' - Matched entitlement key: ${matchedKey ?? 'none'}');
    debugPrint(' - Computed isPremium: $isPremium');

    // Persist a short snapshot into purchases_box for local inspection
    try {
      final box = Hive.box('purchases_box');
      await box.put('last_entitlements', {
        'active': activeEntitlementKeys,
        'all': allEntitlementKeys,
        'checkedAt': DateTime.now().toIso8601String(),
        'entitlementChecked': _entitlementId,
      });
    } catch (e) {
      debugPrint('Failed to write purchases_box snapshot: $e');
    }

    // Write to settings (used by PremiumService/AuthProvider)
    final settings = HiveService.instance.getSettings();
    settings['isPremium'] = isPremium;
    await HiveService.instance.setSettings(settings);

    // Notify listeners via stream
    _subscriptionStatusController.add(isPremium);
  }

  /// Debug helper: fetch current CustomerInfo and log entitlements
  Future<Map<String, dynamic>> dumpCustomerInfo() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.active.keys.toList();
      final all = info.entitlements.all.keys.toList();
      debugPrint('dumpCustomerInfo - active: $active all: $all');
      return {
        'active': active,
        'all': all,
        'appUserId': await Purchases.appUserID,
      };
    } catch (e) {
      debugPrint('dumpCustomerInfo failed: $e');
      return {'error': e.toString()};
    }
  }

  Future<bool> isPro() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking isPro: $e');
      return false;
    }
  }

  /// Identify RevenueCat with a stable app user id (recommended on login)
  Future<void> identify(String userId) async {
    try {
      debugPrint('PurchaseService: Logging in RevenueCat with userId: $userId');
      // Use logIn to associate the app user id with RevenueCat
      try {
        await Purchases.logIn(userId);
      } catch (e) {
        debugPrint('Purchases.logIn failed: $e');
      }
      // Refresh customer info after login
      final info = await Purchases.getCustomerInfo();
      _updatePremiumStatus(info);
    } catch (e) {
      debugPrint('PurchaseService.identify failed: $e');
    }
  }

  /// Reset RevenueCat to anonymous user (use on logout)
  Future<void> reset() async {
    try {
      debugPrint('PurchaseService: logging out RevenueCat (anonymous)');
      try {
        await Purchases.logOut();
      } catch (e) {
        debugPrint('Purchases.logOut failed: $e');
      }
      final info = await Purchases.getCustomerInfo();
      _updatePremiumStatus(info);
    } catch (e) {
      debugPrint('PurchaseService.reset failed: $e');
    }
  }
}
