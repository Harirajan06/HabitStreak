import 'package:flutter/material.dart';

import '../services/premium_service.dart';

class PremiumGuard extends StatelessWidget {
  final Widget child;
  final Widget? lockedChild;

  const PremiumGuard({super.key, required this.child, this.lockedChild});

  @override
  Widget build(BuildContext context) {
    if (PremiumService.instance.isPremium) return child;

    return lockedChild ?? Column(
      children: [
        child,
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            // Simple local upgrade (no payment) for demo
            final messenger = ScaffoldMessenger.of(context);
            PremiumService.instance.setPremium(true).then((_) {
              messenger.showSnackBar(const SnackBar(content: Text('Upgraded to premium (local)')));
            });
          },
          child: const Text('Unlock Premium (Local)'),
        ),
      ],
    );
  }
}
