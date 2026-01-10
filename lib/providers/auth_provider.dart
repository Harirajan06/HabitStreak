import 'package:flutter/material.dart';
import 'dart:async'; // Added for StreamSubscription
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/hive_service.dart';
import '../services/purchase_service.dart'; // Added PurchaseService
import '../models/user.dart';
import '../services/admob_service.dart'; // Import AdmobService

class AuthProvider with ChangeNotifier {
  final AdmobService _admobService;
  bool _isAuthenticated = false;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final Uuid _uuid = const Uuid();

  bool get isAuthenticated => _isAuthenticated;
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userAvatar => _currentUser?.avatarUrl;

  StreamSubscription<bool>? _premiumStatusSubscription;

  AuthProvider(this._admobService) {
    _loadLocalUser();
    _listenToPurchaseUpdates();
  }

  void _listenToPurchaseUpdates() {
    _premiumStatusSubscription =
        PurchaseService.instance.subscriptionStatusStream.listen((isPremium) {
      debugPrint('AuthProvider: Received premium update: $isPremium');
      if (_currentUser != null) {
        setPremiumStatus(isPremium);
      }
    });
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  AppUser? _findUserById(List<AppUser> users, String? id) {
    if (id == null) return null;
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  AppUser? _findUserByEmail(List<AppUser> users, String? email) {
    if (email == null) return null;
    for (final u in users) {
      if (u.email == email) return u;
    }
    return null;
  }

  // Secure storage for PIN
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> _loadLocalUser() async {
    try {
      final settings = HiveService.instance.getSettings();
      var currentUserId = settings['currentUserId'] as String?;
      final users = HiveService.instance.getUsers();

      if (currentUserId == null && users.isNotEmpty) {
        // Recover: Pick first user if exists but no current ID
        currentUserId = users.first.id;
        settings['currentUserId'] = currentUserId;
        await HiveService.instance.setSettings(settings);
      }

      if (currentUserId != null) {
        _currentUser = _findUserById(users, currentUserId);
        _isAuthenticated = _currentUser != null;

        // Sync with global premium status (from RevenueCat/PurchaseService)
        if (_currentUser != null) {
          final isPremiumGlobal = settings['isPremium'] ?? false;
          if (isPremiumGlobal is bool &&
              _currentUser!.premium != isPremiumGlobal) {
            debugPrint(
                'AuthProvider: Syncing user premium status with global settings ($isPremiumGlobal)');
            _currentUser = _currentUser!.copyWith(premium: isPremiumGlobal);
            try {
              await HiveService.instance.updateUser(_currentUser!);
            } catch (e) {
              debugPrint(
                  'AuthProvider: Failed to sync user premium status: $e');
            }
          }
          // Ensure RevenueCat is identified with this user's id so purchases
          // persist across reinstalls when the same user id is reused.
          try {
            await PurchaseService.instance.identify(currentUserId);
          } catch (e) {
            debugPrint('AuthProvider: identify failed: $e');
          }
        }
      }

      if (_currentUser == null) {
        // No users at all (First Run or Cleared), create Guest User
        debugPrint('AuthProvider: No user found. Creating Guest User.');
        await _createGuestUser();
      } else {
        _admobService.loadInterstitialAd(
            isPremium: _currentUser?.premium ?? false);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Error loading/creating user: $e');
    }
  }

  Future<void> _createGuestUser() async {
    final id = _uuid.v4();
    final user = AppUser(
      id: id,
      email: 'guest@streakly.app',
      name: 'Guest',
      premium: false,
      createdAt: DateTime.now(),
    );
    await HiveService.instance.addUser(user);
    final settings = HiveService.instance.getSettings();
    settings['currentUserId'] = id;
    await HiveService.instance.setSettings(settings);
    _currentUser = user;
    _isAuthenticated = true;
    _admobService.loadInterstitialAd(isPremium: false);
    // Identify RevenueCat with guest id so purchases (if any) attach to this id.
    try {
      await PurchaseService.instance.identify(id);
    } catch (e) {
      debugPrint('AuthProvider: identify after guest create failed: $e');
    }
  }

  // PIN & Biometric support (secure storage)
  String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  String _iteratedHash(String pin, String salt, int iterations) {
    // Simple iterated SHA-256 KDF (reasonable iterations)
    var digest = sha256.convert(utf8.encode('$pin:$salt')).bytes;
    for (var i = 0; i < iterations - 1; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return _bytesToHex(digest);
  }

  List<int> _generateSalt(int length) {
    try {
      final rng = Random.secure();
      return List<int>.generate(length, (_) => rng.nextInt(256));
    } catch (_) {
      final fallback = Random();
      return List<int>.generate(length, (_) => fallback.nextInt(256));
    }
  }

  Future<bool> setPin(String pin, {int iterations = 10000}) async {
    try {
      final salt = _bytesToHex(_generateSalt(16));
      final hash = _iteratedHash(pin, salt, iterations);
      await _secureStorage.write(key: 'pin_salt', value: salt);
      await _secureStorage.write(key: 'pin_hash', value: hash);
      await _secureStorage.write(
          key: 'pin_iters', value: iterations.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _secureStorage.read(key: 'pin_salt');
    final hash = await _secureStorage.read(key: 'pin_hash');
    final itersStr = await _secureStorage.read(key: 'pin_iters');
    if (salt == null || hash == null || itersStr == null) return false;
    final iterations = int.tryParse(itersStr) ?? 10000;
    final candidate = _iteratedHash(pin, salt, iterations);
    return candidate == hash;
  }

  Future<bool> removePin() async {
    try {
      await _secureStorage.delete(key: 'pin_salt');
      await _secureStorage.delete(key: 'pin_hash');
      await _secureStorage.delete(key: 'pin_iters');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: 'pin_hash');
    return hash != null;
  }

  Future<bool> loginWithPin(String pin) async {
    if (await verifyPin(pin)) {
      // Auto-login with first user (or stored currentUserId)
      final settings = HiveService.instance.getSettings();
      final id = settings['currentUserId'] as String?;
      final users = HiveService.instance.getUsers();
      final match = id != null
          ? _findUserById(users, id)
          : (users.isNotEmpty ? users.first : null);
      if (match != null) {
        _currentUser = match;
        _isAuthenticated = true;
        _admobService.loadInterstitialAd(isPremium: match.premium);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<bool> isBiometricAvailable() async {
    final auth = LocalAuthentication();
    return await auth.canCheckBiometrics || await auth.isDeviceSupported();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final auth = LocalAuthentication();
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Streakly',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuthenticate) {
        // proceed to login similarly to PIN
        final settings = HiveService.instance.getSettings();
        final id = settings['currentUserId'] as String?;
        final users = HiveService.instance.getUsers();
        final match = id != null
            ? _findUserById(users, id)
            : (users.isNotEmpty ? users.first : null);
        if (match != null) {
          _currentUser = match;
          _isAuthenticated = true;
          _admobService.loadInterstitialAd(isPremium: match.premium);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<bool> login(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final users = HiveService.instance.getUsers();
      final match = _findUserByEmail(users, email);
      if (match != null) {
        _currentUser = match;
        _isAuthenticated = true;
        final settings = HiveService.instance.getSettings();
        settings['currentUserId'] = match.id;
        await HiveService.instance.setSettings(settings);
        _admobService.loadInterstitialAd(isPremium: match.premium);
        // Identify RevenueCat to ensure this user's purchases are associated
        try {
          await PurchaseService.instance.identify(match.id);
        } catch (e) {
          debugPrint('AuthProvider: identify after login failed: $e');
        }
        return true;
      }

      _errorMessage = 'No account found with that email';
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final id = _uuid.v4();
      final user = AppUser(
        id: id,
        email: email,
        name: name,
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: null,
        preferences: {},
        premium: false,
      );
      await HiveService.instance.addUser(user);
      _currentUser = user;
      _isAuthenticated = true;
      final settings = HiveService.instance.getSettings();
      settings['currentUserId'] = id;
      await HiveService.instance.setSettings(settings);
      _admobService.loadInterstitialAd(isPremium: false);
      // Identify RevenueCat with the new registered user id
      try {
        await PurchaseService.instance.identify(id);
      } catch (e) {
        debugPrint('AuthProvider: identify after register failed: $e');
      }
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPremiumStatus(bool isPremium) async {
    if (_currentUser == null) {
      debugPrint('AuthProvider: cannot set premium, currentUser is null');
      return;
    }
    debugPrint('AuthProvider: setPremiumStatus called with $isPremium');

    // Optimistic update
    _currentUser = _currentUser!.copyWith(premium: isPremium);
    _admobService.loadInterstitialAd(isPremium: isPremium);
    notifyListeners();

    try {
      await HiveService.instance.updateUser(_currentUser!);
      debugPrint('AuthProvider: Hive user updated successfully');
    } catch (e) {
      debugPrint('AuthProvider: Failed to save user premium status: $e');
      // Revert on failure? Or just keep in-memory?
      // For developer tool, keeping in-memory is fine, but let's log it contentiously.
    }
  }

  Future<bool> updateAvatar(String emoji) async {
    try {
      if (_currentUser == null) {
        _errorMessage = 'User not logged in';
        return false;
      }
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = _currentUser!.copyWith(avatarUrl: emoji);
      await HiveService.instance.updateUser(_currentUser!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update avatar: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      final settings = HiveService.instance.getSettings();
      settings.remove('currentUserId');
      await HiveService.instance.setSettings(settings);
      _currentUser = null;
      _isAuthenticated = false;
      _admobService.loadInterstitialAd(isPremium: false);
      // Reset RevenueCat to anonymous user on logout to avoid tying
      // subsequent actions to the previous user id.
      try {
        await PurchaseService.instance.reset();
      } catch (e) {
        debugPrint('AuthProvider: PurchaseService.reset failed: $e');
      }
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    // No remote password: simply return true if user exists
    final users = HiveService.instance.getUsers();
    final match = _findUserByEmail(users, email);
    return match != null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    debugPrint('Error type: ${error.runtimeType}, Error: $error');

    // Legacy remote-auth specific exception handling removed.
    // We return generic messages based on error text below.

    final errorString = error.toString();
    if (errorString.contains('404') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('SocketException') ||
        errorString.contains('Connection refused')) {
      return 'Cannot connect to server. Please check your internet connection or use demo mode.';
    }

    if (errorString.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }

    if (errorString.contains('User not found')) {
      return 'No account found with this email. Please sign up first.';
    }

    return 'Authentication failed. Please try again.';
  }
}
