import 'package:b2win/core/network/api_client.dart';

class AuthProvider {
  final ApiClient _apiClient;

  AuthProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/users/login',
      body: {'email': email, 'password': password},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _apiClient.post(
      '/users/register',
      body: {
        'email': email,
        'password': password,
        'username': username,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resendConfirmation({
    required String email,
  }) async {
    final response = await _apiClient.post(
      '/users/resend-confirmation',
      body: {'email': email},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await _apiClient.post(
      '/users/forgot-password',
      body: {'email': email},
    );
    return response as Map<String, dynamic>;
  }

  Future<String> getGoogleOAuthUrl() async {
    final response = await _apiClient.get('/users/oauth/google');
    if (response is Map<String, dynamic> && response['url'] != null) {
      return response['url'].toString();
    }
    throw Exception('Failed to retrieve Google Sign-In URL');
  }

  Future<Map<String, dynamic>> googleOAuthExchange({
    String? idToken,
    String? accessToken,
    String? refreshToken,
  }) async {
    final response = await _apiClient.post(
      '/users/oauth/google',
      body: {
        if (idToken != null) 'idToken': idToken,
        if (accessToken != null) 'accessToken': accessToken,
        if (refreshToken != null) 'refreshToken': refreshToken,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiClient.get('/users/me', requireAuth: true);
    return response as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _apiClient.post('/users/logout', requireAuth: true);
  }
}
