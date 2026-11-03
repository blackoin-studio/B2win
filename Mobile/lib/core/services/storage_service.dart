import 'dart:convert';
import 'package:b2win/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _preferences;

  static const String _keyToken = 'token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyLoggedIn = 'loggedIn';
  static const String _keyOnboarded = 'onboarded';
  static const String _keyCachedUser = 'cached_user_profile';
  static const String _keyCachedPredictions = 'cached_predictions';
  static const String _keyCachedBlogs = 'cached_blogs';
  static const String _keySavedPredictionIds = 'saved_prediction_ids';
  static const String _keyVipExpiryMs = 'vip_pass_expiry_ms';
  static const String _keyThemeMode = 'theme_mode';

  StorageService._({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  // Token Management (Supabase Auth JWT + Refresh Token)
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _keyToken);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  // User Profile Caching
  Future<void> saveUser(UserModel user) async {
    await _preferences?.setString(_keyCachedUser, jsonEncode(user.toJson()));
  }

  UserModel? getCachedUser() {
    final raw = _preferences?.getString(_keyCachedUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  // Auth State
  bool isLoggedIn() {
    return _preferences?.getBool(_keyLoggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    await _preferences?.setBool(_keyLoggedIn, value);
  }

  // Onboarding State
  bool isOnboarded() {
    return _preferences?.getBool(_keyOnboarded) ?? false;
  }

  Future<void> setOnboarded(bool value) async {
    await _preferences?.setBool(_keyOnboarded, value);
  }

  // Offline Caching
  Future<void> saveCachedPredictions(String jsonString) async {
    await _preferences?.setString(_keyCachedPredictions, jsonString);
  }

  String? getCachedPredictions() {
    return _preferences?.getString(_keyCachedPredictions);
  }

  Future<void> saveCachedBlogs(String jsonString) async {
    await _preferences?.setString(_keyCachedBlogs, jsonString);
  }

  String? getCachedBlogs() {
    return _preferences?.getString(_keyCachedBlogs);
  }

  // Bookmarked / Saved Slip Prediction IDs
  List<String> getSavedPredictionIds() {
    return _preferences?.getStringList(_keySavedPredictionIds) ?? <String>[];
  }

  Future<void> saveSavedPredictionIds(List<String> ids) async {
    await _preferences?.setStringList(_keySavedPredictionIds, ids);
  }

  // VIP 24-Hour Pass Management
  bool isVipPassActive() {
    final expiryMs = _preferences?.getInt(_keyVipExpiryMs) ?? 0;
    return expiryMs > DateTime.now().millisecondsSinceEpoch;
  }

  DateTime? getVipPassExpiry() {
    final expiryMs = _preferences?.getInt(_keyVipExpiryMs) ?? 0;
    if (expiryMs <= DateTime.now().millisecondsSinceEpoch) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiryMs);
  }

  Future<DateTime> activateVipPass({
    Duration duration = const Duration(hours: 24),
  }) async {
    final expiry = DateTime.now().add(duration);
    await _preferences?.setInt(_keyVipExpiryMs, expiry.millisecondsSinceEpoch);
    return expiry;
  }

  // Theme Mode ('system', 'dark', 'light')
  String getThemeMode() {
    return _preferences?.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    await _preferences?.setString(_keyThemeMode, mode);
  }

  // Clear Session
  Future<void> clearAuthSession() async {
    await deleteToken();
    await deleteRefreshToken();
    await _preferences?.remove(_keyCachedUser);
    await setLoggedIn(false);
  }
}
