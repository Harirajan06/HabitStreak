import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
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
  static const _apiKey = 'test_UJOGBiKtFpwTBReIuyUejnhRbog';
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
    final bool isPremium =
        customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;

    debugPrint(
        'Updating Premium Status (EncTitl: $_entitlementId): $isPremium');

    final settings = HiveService.instance.getSettings();
    settings['isPremium'] = isPremium;
    await HiveService.instance.setSettings(settings);

    // Notify listeners via stream
    _subscriptionStatusController.add(isPremium);
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
}
