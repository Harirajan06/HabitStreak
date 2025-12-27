import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/purchase_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isLoading = true;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await PurchaseService.instance.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _isLoading = true);
    await PurchaseService.instance.purchasePackage(package);
    if (mounted) {
      setState(() => _isLoading = false);
      // Logic to close or show success is handled by listeners or manual check
      // Ideally we check if premium is now true and pop
      Navigator.pop(context); // Or show success dialog
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    await PurchaseService.instance.restorePurchases();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define feature list
    final features = [
      {'icon': Icons.all_inclusive, 'text': 'Unlimited Habits'},
      {'icon': Icons.block, 'text': 'No Ads'},
      {'icon': Icons.show_chart, 'text': 'Advanced Analytics'},
      {'icon': Icons.cloud_upload, 'text': 'Data Backup & Export'},
      {'icon': Icons.support_agent, 'text': 'Priority Support'},
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700).withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        size: 60,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unlock Streakly Pro',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Build better habits with unlimited access to all features.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Features List
                  ...features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(
                              feature['icon'] as IconData,
                              color: const Color(0xFFFFD700),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              feature['text'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 40),

                  // Packages
                  if (_offerings != null &&
                      _offerings!.current != null &&
                      _offerings!.current!.availablePackages.isNotEmpty) ...[
                    ..._offerings!.current!.availablePackages.map((package) {
                      final isAnnual =
                          package.packageType == PackageType.annual;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPackageCard(
                          context,
                          package,
                          isBestValue: isAnnual,
                          onTap: () => _purchasePackage(package),
                        ),
                      );
                    }),
                  ] else ...[
                    const Center(
                      child: Text('No plans available right now.'),
                    ),
                  ],

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _restorePurchases,
                    child: Text(
                      'Restore Purchases',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard(BuildContext context, Package package,
      {bool isBestValue = false, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isBestValue
              ? const Color(0xFFFFD700).withOpacity(0.1)
              : (isDark ? Colors.grey[850] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBestValue
                ? const Color(0xFFFFD700)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isBestValue ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBestValue) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'BEST VALUE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    package.storeProduct.title.split(' (').first, // Clean title
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.storeProduct.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  package.storeProduct.priceString,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isBestValue
                        ? const Color(0xFFFFD700)
                        : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  isBestValue ? '/ year' : '/ month',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
