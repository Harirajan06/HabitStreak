import 'package:flutter/material.dart';

import '../services/premium_service.dart';
import '../services/toast_service.dart';

class PremiumGuard extends StatelessWidget {
  final Widget child;
  final Widget? lockedChild;

  const PremiumGuard({super.key, required this.child, this.lockedChild});

  @override
  Widget build(BuildContext context) {
    if (PremiumService.instance.isPremium) return child;

    return lockedChild ??
        Column(
          children: [
            child,
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Simple local upgrade (no payment) for demo
                PremiumService.instance.setPremium(true).then((_) {
                  ToastService.show(context, 'Upgraded to premium (local)');
                });
              },
              child: const Text('Unlock Premium (Local)'),
            ),
          ],
        );
  }
}
