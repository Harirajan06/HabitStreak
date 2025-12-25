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
import 'providers/mood_provider.dart';
import 'services/admob_service.dart';
import 'services/hive_service.dart';
import 'notification_initializer.dart';
import 'services/purchase_service.dart';
import 'services/widget_service.dart';
import 'screens/widgets/widget_habit_selection_screen.dart';

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

  final admobService = AdmobService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: admobService),
        ChangeNotifierProvider(create: (_) => AuthProvider(admobService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<ThemeProvider, HabitProvider>(
          create: (_) => HabitProvider(admobService),
          update: (_, themeProvider, habitProvider) {
            habitProvider!.updateTheme(themeProvider.isDarkMode);
            return habitProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: StreaklyApp(pinRequired: pinRequired),
    ),
  );
}

class StreaklyApp extends StatelessWidget {
  final bool pinRequired;
  const StreaklyApp({super.key, this.pinRequired = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Streakly - Habit Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF9B5DE5), // Bright Purple
              secondary: Color(0xFF9B5DE5),
              surface: Color(0xFFF5F5F7), // Light Gray/White
              onSurface: Colors.black87,
            ),
            textTheme: GoogleFonts.interTextTheme(
              ThemeData.light().textTheme,
            ),
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              titleTextStyle: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9B5DE5), // Bright Purple
              secondary: Color(0xFF9B5DE5),
              surface: Color(0xFF1E1E1E), // Lighter dark background
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
          home: StreaklyLogicWrapper(pinRequired: pinRequired),
        );
      },
    );
  }
}

class StreaklyLogicWrapper extends StatefulWidget {
  final bool pinRequired;
  const StreaklyLogicWrapper({super.key, this.pinRequired = false});

  @override
  State<StreaklyLogicWrapper> createState() => _StreaklyLogicWrapperState();
}

class _StreaklyLogicWrapperState extends State<StreaklyLogicWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check if we were launched for widget configuration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWidgetLaunch();
    });
  }

  Future<void> _checkWidgetLaunch() async {
    final widgetService = WidgetService();
    final config = await widgetService.getWidgetConfig();

    if (config != null && config['mode'] == true) {
      final int appWidgetId = config['appWidgetId'] ?? -1;
      if (appWidgetId != -1 && mounted) {
        debugPrint(
            "🚀 Launched in Widget Configuration Mode for ID: $appWidgetId");
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                WidgetHabitSelectionScreen(appWidgetId: appWidgetId),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("App Resumed - Syncing Widget Actions");
      // Check for widget config launch on resume (if app was in background)
      _checkWidgetLaunch();

      // Delay slightly to ensure provider is ready if needed, though usually safe immediately
      Future.delayed(Duration.zero, () {
        if (mounted) {
          debugPrint("App Resumed - Syncing Widget Actions immediately");
          Provider.of<HabitProvider>(context, listen: false)
              .syncWidgetActions();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.pinRequired ? const PinAuthScreen() : SplashScreen();
  }
}
