import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../services/admob_service.dart';
import '../../services/navigation_service.dart';
import '../main_navigation_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      // Initialize saved view mode preference
      try {
        await NavigationService.initializeViewMode();
      } catch (e) {
        debugPrint('⚠️ NavigationService init failed: $e');
      }

      // Give auth provider extra time to initialize if needed
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Try to load and show ad (may fail on web)
      try {
        final admobService = Provider.of<AdmobService>(context, listen: false);
        admobService.loadInterstitialAd();
        await Future.delayed(const Duration(seconds: 1));
        admobService.showInterstitialAd();
      } catch (e) {
        debugPrint('⚠️ AdMob not available: $e');
      }

      if (!mounted) return;

      if (!hasSeenOnboarding) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        return;
      }

      // Navigate to the appropriate view based on saved preference
      if (NavigationService.isGridViewMode) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainNavigationScreen()),
        );
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // Fallback to onboarding if there's any error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/splash/splash.png',
                      width: 250,
                      height: 250,
                    ),
                    const SizedBox(height: 0),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        children: [
                          TextSpan(
                            text: 'Habit ',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          TextSpan(
                            text: 'Sensai',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build Better Habits',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface
                            .withAlpha((0.6 * 255).round()),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
