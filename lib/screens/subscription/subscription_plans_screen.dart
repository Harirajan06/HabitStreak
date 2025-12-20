import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../services/purchase_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _isPremium = false;
  StreamSubscription<String>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _initSubscription();
    _setupPurchaseListener();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _setupPurchaseListener() {
    _statusSubscription = PurchaseService.instance.statusStream.listen((status) {
      if (!mounted) return;

      if (status == 'pending') {
        setState(() => _loading = true);
      } else {
        setState(() => _loading = false);
        
        if (status == 'success') {
          _refreshPremiumStatus();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase successful! Premium features unlocked.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (status == 'canceled') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase canceled')),
          );
        } else if (status.startsWith('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status.substring(7)), // Remove 'error: ' prefix
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _refreshPremiumStatus() async {
    final Box settings = Hive.box('settings_box');
    setState(() {
      _isPremium = settings.get('isPremium', defaultValue: false) as bool;
    });
  }

  Future<void> _initSubscription() async {
    await PurchaseService.instance.init();
    
    // Check if the store is available
    final bool available = await PurchaseService.instance.isAvailable;
    if (!available) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store not available. Please use a device with Google Play Store.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final prods = await PurchaseService.instance.queryProducts();
      if (mounted) {
        setState(() {
          _products = prods;
          _loading = false;
        });
        _refreshPremiumStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  Future<void> _buy(ProductDetails product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text('Do you want to subscribe to ${product.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      await PurchaseService.instance.buyProduct(product);
      // Loading state will be handled by the stream listener
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    await PurchaseService.instance.restorePurchases();
    // Loading state will be handled by the stream listener
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required String duration,
    required List<String> features,
    required Color accentColor,
    bool isPopular = false,
    ProductDetails? product,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: title == 'Free'
              ? Colors.white
              : title == 'Monthly Pro'
                  ? const Color(0xFF9B5DE5) // Bright Purple
                  : const Color(0xFFFFD700),
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isPopular) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Most Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: duration,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: title == 'Free' || product == null || _isPremium ? null : () => _buy(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: title == 'Free'
                      ? Colors.white
                      : title == 'Monthly Pro'
                          ? const Color(0xFF9B5DE5) // Bright Purple
                          : const Color(0xFFFFD700),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: title == 'Free' || title == 'Yearly Pro'
                      ? Colors.black // Black text for white and gold buttons
                      : Colors.white, // White text for purple button
                ),
                child: Text(
                  title == 'Free' ? 'Current Plan' : (_isPremium ? 'Purchased' : 'Subscribe'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withAlpha((0.95 * 255).round()),
        elevation: 0,
        title: Text(
          'Subscription Plans',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Choose Your Plan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the perfect plan for your needs',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
              ),
            ),
            const SizedBox(height: 24),
            if (_isPremium)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Active',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'You have access to all features',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            _buildPlanCard(
              context: context,
              title: 'Free',
              price: '₹0',
              duration: '/forever',
              accentColor: Colors.grey,
              features: [
                'Create up to 3 habits',
                'Basic habit tracking',
                'Daily reminders',
                'Progress statistics',
              ],
            ),
            _buildPlanCard(
              context: context,
              title: 'Monthly Pro',
              price: '₹99',
              duration: '/month',
              accentColor: theme.colorScheme.primary,
              isPopular: true,
              product: _products.isNotEmpty 
                  ? _products.firstWhere(
                      (p) => p.id.contains('monthly'), 
                      orElse: () => _products.first
                    ) 
                  : null,
              features: [
                'Unlimited habits',
                'Advanced analytics',
                'Priority support',
                'Custom habit icons',
                'Multiple reminders per habit',
                'Export data & insights',
              ],
            ),
            _buildPlanCard(
              context: context,
              title: 'Yearly Pro',
              price: '₹999',
              duration: '/year',
              accentColor: const Color(0xFFFFD700), // Gold color
              product: _products.isNotEmpty 
                  ? _products.firstWhere(
                      (p) => p.id.contains('yearly'), 
                      orElse: () => _products.first
                    ) 
                  : null,
              features: [
                'All Monthly Pro features',
                '2 months free',
                'Early access to new features',
                'Premium habit templates',
                'Advanced habit insights',
                'Personal habit coach AI',
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _restore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore Purchases'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}