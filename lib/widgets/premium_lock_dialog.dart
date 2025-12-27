import 'package:flutter/material.dart';
import '../screens/subscription/subscription_plans_screen.dart';

void showPremiumLockDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
          SizedBox(width: 8),
          Text('Premium Required'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SubscriptionPlansScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9B5DE5),
            foregroundColor: Colors.white,
          ),
          child: const Text('Upgrade to Pro'),
        ),
      ],
    ),
  );
}
