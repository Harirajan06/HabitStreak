import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/hive_service.dart';
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

  AuthProvider(this._admobService) {
    _loadLocalUser();
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
      final currentUserId = settings['currentUserId'] as String?;
      if (currentUserId != null) {
        final users = HiveService.instance.getUsers();
        _currentUser = _findUserById(users, currentUserId);
        _isAuthenticated = _currentUser != null;
        _admobService.loadInterstitialAd(isPremium: _currentUser?.premium ?? false);
      }
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  // PIN & Biometric support (secure storage)
  String _bytesToHex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  String _iteratedHash(String pin, String salt, int iterations) {
    // Simple iterated SHA-256 KDF (reasonable iterations)
    var digest = sha256.convert(utf8.encode('$pin:$salt')).bytes;
    for (var i = 0; i < iterations - 1; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return _bytesToHex(digest);
  }

  Future<bool> setPin(String pin, {int iterations = 10000}) async {
    try {
      final salt = _bytesToHex(List<int>.generate(16, (_) => DateTime.now().microsecondsSinceEpoch.remainder(256)));
      final hash = _iteratedHash(pin, salt, iterations);
      await _secureStorage.write(key: 'pin_salt', value: salt);
      await _secureStorage.write(key: 'pin_hash', value: hash);
      await _secureStorage.write(key: 'pin_iters', value: iterations.toString());
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
      final match = id != null ? _findUserById(users, id) : (users.isNotEmpty ? users.first : null);
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
        final match = id != null ? _findUserById(users, id) : (users.isNotEmpty ? users.first : null);
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
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
