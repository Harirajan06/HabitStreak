import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:hive/hive.dart';

class PurchaseService {
  PurchaseService._privateConstructor();
  static final PurchaseService instance = PurchaseService._privateConstructor();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Stream controller for purchase status updates
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Use your product ids defined in App Store / Play Console
  final List<String> productIds = <String>[
    'premium_monthly',
    'premium_yearly',
    'premium_lifetime',
  ];

  Future<bool> get isAvailable => _iap.isAvailable();

  Future<void> init() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(_listenToPurchaseUpdated, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint('Purchase stream error: $error');
    });
  }

  Future<List<ProductDetails>> queryProducts() async {
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(productIds.toSet());
    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
    }
    return response.productDetails;
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('Purchase pending: ${purchaseDetails.productID}');
          _statusController.add('pending');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliverPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchaseDetails.error}');
          _statusController.add('error: ${purchaseDetails.error?.message ?? "Unknown error"}');
          break;
        case PurchaseStatus.canceled:
          debugPrint('Purchase canceled');
          _statusController.add('canceled');
          break;
      }
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchase) async {
    // NOTE: This is a local-only verification. For production, validate receipts on a server.
    try {
      final Box settings = Hive.box('settings_box');
      // Mark premium unlocked locally
      settings.put('isPremium', true);

      // Optionally store purchase record
      if (Hive.isBoxOpen('purchases_box')) {
        final Box purchasesBox = Hive.box('purchases_box');
        purchasesBox.put(purchase.purchaseID ?? DateTime.now().toIso8601String(), {
          'productId': purchase.productID,
          'transactionDate': purchase.transactionDate,
          'status': purchase.status.toString(),
          'remark': 'local-only validated',
        });
      }
      debugPrint('Delivered purchase ${purchase.productID} — premium enabled locally.');
      _statusController.add('success');
    } catch (e) {
      debugPrint('Error delivering purchase: $e');
      _statusController.add('error: Failed to deliver purchase');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _statusController.close();
  }
}
