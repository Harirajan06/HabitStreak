import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/purchase_service.dart';
import '../../services/toast_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isLoading = true;
  Offerings? _offerings;
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await PurchaseService.instance.getOfferings();
    if (mounted) {
      if (offerings?.current != null &&
          offerings!.current!.availablePackages.isNotEmpty) {
        // Default to annual if available, else first
        final annual = offerings.current!.availablePackages.firstWhere(
            (p) => p.packageType == PackageType.annual,
            orElse: () => offerings.current!.availablePackages.first);
        _selectedPackage = annual;
      }
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseSelectedPackage() async {
    if (_selectedPackage == null) return;
    setState(() => _isLoading = true);
    await PurchaseService.instance.purchasePackage(_selectedPackage!);
    if (mounted) {
      setState(() => _isLoading = false);
      // If purchase was successful (listener handles entitlement update), pop
      // Ideally we check entitlement status, but PurchaseService handles it.
      // We can just try to pop if we believe it succeeded or check status.
      // For now, let's assume PurchaseService shows toast/handles logic.
      final isPremium = await PurchaseService.instance.isPro();
      if (isPremium && mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    // Listen to the status stream for feedback
    final subscription = PurchaseService.instance.statusStream.listen((status) {
      if (mounted) {
        setState(() => _isLoading = false);

        if (status == 'success') {
          ToastService.show(context, '✅ Purchases restored successfully!');
          // Check if premium and pop
          PurchaseService.instance.isPro().then((isPro) {
            if (isPro && mounted) Navigator.pop(context);
          });
        } else if (status.contains('No purchases to restore')) {
          ToastService.show(context, 'ℹ️ No purchases found to restore');
        } else if (status.startsWith('error:')) {
          ToastService.show(context, '❌ ${status.replaceFirst('error: ', '')}',
              isError: true);
        }
      }
    });

    await PurchaseService.instance.restorePurchases();

    // Cancel subscription after a delay to ensure we catch the status
    Future.delayed(const Duration(seconds: 2), () {
      subscription.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor =
        isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7);
    final backgroundColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

    // Feature list with adaptive text colors will be handled in _buildFeatureItem
    final features = [
      {
        'icon': Icons.grid_view,
        'text': 'Unlimited number of habits',
        'subtext':
            'Unlimited possibilities by creating as many habits as you like',
        'color': Colors.green
      },
      {
        'icon': Icons.widgets,
        'text': 'Home Screen Widgets',
        'subtext': 'Show your favorite habits on your home screen',
        'color': Colors.blue
      },
      {
        'icon': Icons.notifications_active,
        'text': 'Multiple Reminders',
        'subtext': 'Add up to three reminders for the same habit',
        'color': Colors.redAccent
      },
      {
        'icon': Icons.mood,
        'text': 'Mood & Mood Analysis',
        'subtext': 'Track your mood and see how your habits affect it',
        'color': Colors.pinkAccent
      },
      {
        'icon': Icons.insights,
        'text': 'Charts & Statistics',
        'subtext': 'See charts and statistics about your consistency',
        'color': Colors.amber
      },
      {
        'icon': Icons.edit,
        'text': 'Notes',
        'subtext': 'Add notes to your habit completions and mood entries',
        'color': Colors.orange
      },
      {
        'icon': Icons.cloud_upload,
        'text': 'Export your data',
        'subtext': 'Generate a file from your habits and completions',
        'color': Colors.blueAccent
      },
      {
        'icon': Icons.cloud_download,
        'text': 'Import your data',
        'subtext': 'Switching phones? Restore a previously exported backup',
        'color': Colors.brown
      },
      {
        'icon': Icons.star,
        'text': 'Support an Indie Developer',
        'subtext': 'Your purchase supports an independent app developer',
        'color': Colors.purpleAccent
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Unlock Streakly Pro',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_offerings != null && _offerings!.current != null)
                            _buildPlanSelection(
                                _offerings!.current!.availablePackages, isDark),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Recurring billing. Cancel anytime.',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _restorePurchases,
                              child: const Text(
                                'Already subscribed? Restore purchase',
                                style: TextStyle(
                                  color: Color(0xFF9B5DE5), // Purple
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'By subscribing you\'ll also unlock:',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...features
                              .map((f) => _buildFeatureItem(f, isDark))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border(
                          top: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black12)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _purchaseSelectedPackage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF9B5DE5), // Purple action button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanSelection(List<Package> unmodifiablePackages, bool isDark) {
    // Create a mutable copy to allow sorting
    final packages = unmodifiablePackages.toList();
    // Sort packages: Monthly, 3M, 6M, Annual
    packages.sort((a, b) {
      final order = {
        PackageType.monthly: 1,
        PackageType.threeMonth: 2,
        PackageType.sixMonth: 3,
        PackageType.annual: 4,
        PackageType.lifetime: 5,
      };
      final aOrder = order[a.packageType] ?? 99;
      final bOrder = order[b.packageType] ?? 99;
      return aOrder.compareTo(bOrder);
    });

    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor =
        isDark ? const Color(0xFF9B5DE5) : const Color(0xFF9B5DE5);

    return Column(
      children: packages.map((package) {
        final isSelected = _selectedPackage?.identifier == package.identifier;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => _selectedPackage = package),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: borderColor, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Radio Circle
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? const Color(0xFF9B5DE5) : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF9B5DE5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPlanTitle(package),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Visibility(
                          visible: package.packageType == PackageType.annual,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              // Placeholder logic
                              '1200.00 -> ${package.storeProduct.priceString}',
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Visibility(
                        visible: package.packageType == PackageType.annual,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '-50%',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.storeProduct.priceString,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getPlanTitle(Package package) {
    switch (package.packageType) {
      case PackageType.annual:
        return 'Annual';
      case PackageType.sixMonth:
        return '6 Months';
      case PackageType.threeMonth:
        return '3 Months';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.lifetime:
        return 'Lifetime';
      case PackageType.weekly:
        return 'Weekly';
      default:
        return 'Premium';
    }
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature, bool isDark) {
    final titleColor = isDark ? const Color(0xFF9B5DE5) : Colors.purple;
    final subtextColor =
        isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature['icon'] as IconData,
                color: feature['color'] as Color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['text'] as String,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['subtext'] as String,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
