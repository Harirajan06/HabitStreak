import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';


import 'screens/auth/splash_screen.dart';
import 'screens/auth/pin_auth_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/note_provider.dart';
import 'providers/theme_provider.dart';
import 'services/admob_service.dart';
import 'services/hive_service.dart';
import 'notification_initializer.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (local storage)
  try {
    await HiveService.instance.init();
    debugPrint('✅ Hive initialized and boxes opened');
  } catch (e) {
    debugPrint('⚠️ Hive initialization failed: $e');
  }

  // Initialize notifications (channels, timezone, schedule saved reminders)
  try {
    await initializeNotificationService();
    debugPrint('✅ Notifications initialized (or skipped on failure)');
  } catch (e) {
    debugPrint('⚠️ Notification initializer failed: $e');
  }

  // Initialize Google Mobile Ads (safe mode)
  try {
    await MobileAds.instance.initialize();
    debugPrint('✅ MobileAds initialized');
  } catch (e) {
    debugPrint('⚠️ Ads unavailable: $e');
  }

  // Notification initialization removed. Re-add notification initialization
  // later if you want push/local reminders. Currently the app uses Hive
  // for local storage and does not schedule OS-level notifications.

  // Initialize purchase service (in-app purchases) and attempt restore
  try {
    await PurchaseService.instance.init();
    // Attempt automatic restore so users retain entitlements after reinstall
    await PurchaseService.instance.restorePurchases();
    debugPrint('✅ PurchaseService initialized and restore attempted');
  } catch (e) {
    debugPrint('⚠️ Purchase service unavailable: $e');
  }

  // Prevent Flutter-specific non-fatal framework crashes (DevicePreview)
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('_debugDuringDeviceUpdate')) {
      return; // Ignore mouse tracker errors in DevicePreview
    }
    FlutterError.presentError(details);
  };

  // Check whether a PIN is set in secure storage and pass flag to the app
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String? pinHash = await secureStorage.read(key: 'pin_hash');
  final bool pinRequired = pinHash != null;

  runApp(StreaklyApp(pinRequired: pinRequired));
}

class StreaklyApp extends StatefulWidget {
  final bool pinRequired;
  const StreaklyApp({super.key, this.pinRequired = false});

  @override
  State<StreaklyApp> createState() => _StreaklyAppState();
}

class _StreaklyAppState extends State<StreaklyApp> {
  final AdmobService _admobService = AdmobService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _admobService),
        ChangeNotifierProvider(create: (_) => AuthProvider(_admobService)),
        ChangeNotifierProvider(create: (_) => HabitProvider(_admobService)),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        title: 'Streakly - Habit Tracker',
        debugShowCheckedModeBanner: false,
        // DevicePreview removed — using default locale and builder
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9B5DE5), // Bright Purple
            secondary: Color(0xFF9B5DE5),
            surface: Color(0xFF121212),
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: const CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        home: widget.pinRequired ? const PinAuthScreen() : SplashScreen(),
      ),
    );
  }
}
