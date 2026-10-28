import 'package:b2win/core/services/storage_service.dart';
import 'package:b2win/data/models/user_model.dart';
import 'package:b2win/data/providers/auth_provider.dart';

class AuthRepository {
  final AuthProvider _provider;
  final StorageService? _storageService;

  AuthRepository({
    AuthProvider? provider,
    StorageService? storageService,
  })  : _provider = provider ?? AuthProvider(),
        _storageService = storageService;

  Future<StorageService> _getStorage() async {
    return _storageService ?? await StorageService.getInstance();
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _provider.login(email: email, password: password);
    final user = UserModel.fromJson(data);
    final storage = await _getStorage();

    if (user.token != null && user.token!.isNotEmpty) {
      await storage.saveToken(user.token!);
      await storage.setLoggedIn(true);
    }
    if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
      await storage.saveRefreshToken(user.refreshToken!);
    }
    await storage.saveUser(user);

    return user;
  }

  Future<String> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final data = await _provider.register(
      email: email,
      password: password,
      username: username,
    );
    return data['message']?.toString() ?? 'Account created successfully';
  }

  Future<String> resendConfirmation(String email) async {
    final data = await _provider.resendConfirmation(email: email);
    return data['message']?.toString() ??
        'Confirmation email sent! Please check your inbox.';
  }

  Future<String> forgotPassword(String email) async {
    final data = await _provider.forgotPassword(email: email);
    return data['message']?.toString() ??
        'Password reset instructions sent to your email.';
  }

  Future<String> getGoogleSignInUrl() async {
    return await _provider.getGoogleOAuthUrl();
  }

  Future<UserModel> completeGoogleSignIn({
    String? idToken,
    String? accessToken,
    String? refreshToken,
  }) async {
    final data = await _provider.googleOAuthExchange(
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    final user = UserModel.fromJson(data);
    final storage = await _getStorage();

    if (user.token != null && user.token!.isNotEmpty) {
      await storage.saveToken(user.token!);
      await storage.setLoggedIn(true);
    }
    if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
      await storage.saveRefreshToken(user.refreshToken!);
    }
    await storage.saveUser(user);
    return user;
  }

  Future<UserModel?> getCurrentUser({bool refreshRemote = false}) async {
    final storage = await _getStorage();
    final cached = storage.getCachedUser();

    if (!refreshRemote && cached != null) {
      return cached;
    }

    try {
      final data = await _provider.getMe();
      final user = UserModel.fromJson(data);
      await storage.saveUser(user);
      return user;
    } catch (_) {
      return cached;
    }
  }

  Future<void> logout() async {
    try {
      await _provider.logout();
    } catch (_) {}
    final storage = await _getStorage();
    await storage.clearAuthSession();
  }

  Future<bool> isAuthenticated() async {
    final storage = await _getStorage();
    final token = await storage.getToken();
    return storage.isLoggedIn() && token != null && token.isNotEmpty;
  }
}
