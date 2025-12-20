import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'splash_screen.dart';

class PinAuthScreen extends StatefulWidget {
  const PinAuthScreen({super.key});

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'PIN'),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      setState(() { _loading = true; _error = null; });
                      final ok = await auth.loginWithPin(_pinController.text.trim());
                      if (!mounted) return;
                      setState(() { _loading = false; });
                      if (!ok) {
                        setState(() { _error = 'Invalid PIN'; });
                      } else {
                        navigator.pushReplacement(
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                        );
                      }
                    },
              child: _loading ? const CircularProgressIndicator() : const Text('Unlock'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final available = await auth.isBiometricAvailable();
                if (!mounted) return;
                if (available) {
                  final ok = await auth.authenticateWithBiometrics();
                  if (!mounted) return;
                  if (ok) {
                    navigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                    );
                  }
                } else {
                  setState(() { _error = 'Biometric not available on this device'; });
                }
              },
              child: const Text('Use biometrics'),
            ),
          ],
        ),
      ),
    );
  }
}
