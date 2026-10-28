import 'dart:convert';
import 'dart:io';
import 'package:b2win/constants/api_config.dart';
import 'package:b2win/core/network/api_exceptions.dart';
import 'package:b2win/core/services/storage_service.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:b2win/utils/helper/helper_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final storage = await StorageService.getInstance();
      final token = await storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final storage = await StorageService.getInstance();
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final uri = Uri.parse('$baseUrl/users/refresh');
      final response = await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final newToken = data['token']?.toString();
          final newRefresh = data['refreshToken']?.toString();
          if (newToken != null && newToken.isNotEmpty) {
            await storage.saveToken(newToken);
            if (newRefresh != null && newRefresh.isNotEmpty) {
              await storage.saveRefreshToken(newRefresh);
            }
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = false}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      var headers = await _getHeaders(requireAuth: requireAuth);
      var response = await _client.get(uri, headers: headers);

      if (response.statusCode == 401 && requireAuth) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          headers = await _getHeaders(requireAuth: true);
          response = await _client.get(uri, headers: headers);
        }
      }

      return _processResponse(response);
    } on SocketException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      var headers = await _getHeaders(requireAuth: requireAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;
      var response = await _client.post(
        uri,
        headers: headers,
        body: encodedBody,
      );

      if (response.statusCode == 401 &&
          requireAuth &&
          endpoint != '/users/login' &&
          endpoint != '/users/refresh') {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          headers = await _getHeaders(requireAuth: true);
          response = await _client.post(
            uri,
            headers: headers,
            body: encodedBody,
          );
        }
      }

      return _processResponse(response);
    } on SocketException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonResponse;
    try {
      jsonResponse = jsonDecode(response.body);
    } catch (_) {
      jsonResponse = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonResponse;
    }

    final errorMessage = (jsonResponse is Map &&
            (jsonResponse['error'] != null || jsonResponse['message'] != null))
        ? (jsonResponse['error'] ?? jsonResponse['message']).toString()
        : 'Request failed with status code ${response.statusCode}';

    switch (response.statusCode) {
      case 401:
      case 403:
        _handleUnauthorized();
        throw UnauthorizedException(errorMessage);
      case 500:
      case 502:
      case 503:
        throw ServerException(errorMessage);
      default:
        throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  void _handleUnauthorized() {
    StorageService.getInstance().then((storage) async {
      await storage.clearAuthSession();
      if (Get.currentRoute != AppRoutes.login &&
          Get.currentRoute != AppRoutes.signup) {
        Get.offAllNamed(AppRoutes.login);
        Helper.warningSnackBar(
          title: 'Session Expired',
          message: 'Please log in again to continue.',
        );
      }
    });
  }
}
