// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Streakly/main.dart';
import 'package:Streakly/providers/auth_provider.dart';
import 'package:Streakly/providers/habit_provider.dart';
import 'package:Streakly/providers/mood_provider.dart';
import 'package:Streakly/providers/note_provider.dart';
import 'package:Streakly/providers/theme_provider.dart';
import 'package:Streakly/services/admob_service.dart';
import 'package:Streakly/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    const MethodChannel pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    final Directory tempDir =
        await Directory.systemTemp.createTemp('streakly_test');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel,
            (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getApplicationSupportDirectory':
        case 'getTemporaryDirectory':
        case 'getLibraryDirectory':
        case 'getDownloadsDirectory':
          return tempDir.path;
        default:
          return tempDir.path;
      }
    });

    await HiveService.instance.init();

    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadGoogleFonts();
  });

  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final fakeAdmob = _FakeAdmobService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AdmobService>.value(value: fakeAdmob),
          ChangeNotifierProvider(create: (_) => AuthProvider(fakeAdmob)),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProxyProvider<ThemeProvider, HabitProvider>(
            create: (_) => HabitProvider(fakeAdmob),
            update: (_, themeProvider, habitProvider) {
              habitProvider!.updateTheme(themeProvider.isDarkMode);
              return habitProvider;
            },
          ),
          ChangeNotifierProvider(create: (_) => NoteProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
        ],
        child: const StreaklyApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Build Better Habits'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Track Your Habits'), findsOneWidget);
  });
}

Future<void> _loadGoogleFonts() async {
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);

  final Map<String, Set<String>> fontFamilies = {};
  for (final assetPath in manifestMap.keys) {
    if (!assetPath.endsWith('.ttf') && !assetPath.endsWith('.otf')) continue;
    final isGoogleFontsAsset = assetPath.startsWith('packages/google_fonts/');
    final isLocalTestFont = assetPath.startsWith('assets/fonts/');
    if (!isGoogleFontsAsset && !isLocalTestFont) continue;

    final fileName = assetPath.split('/').last;
    final familyName = fileName.split('-').first;
    fontFamilies.putIfAbsent(familyName, () => <String>{}).add(assetPath);
  }

  if (fontFamilies.isEmpty) {
    throw StateError(
      'No bundled Google Fonts assets found in AssetManifest.json. '
      'Ensure google_fonts is added as a dependency with bundled assets.',
    );
  }

  await Future.wait(fontFamilies.entries.map((entry) async {
    final loader = FontLoader(entry.key);
    for (final assetPath in entry.value) {
      loader.addFont(rootBundle.load(assetPath));
    }
    await loader.load();
  }));
}

class _FakeAdmobService extends AdmobService {
  @override
  void loadInterstitialAd({bool isPremium = false}) {}

  @override
  void showInterstitialAd({bool isPremium = false}) {}
}
