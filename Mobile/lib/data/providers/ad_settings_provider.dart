import 'package:b2win/core/network/api_client.dart';

class AdSettingsProvider {
  final ApiClient _apiClient;

  AdSettingsProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<dynamic> fetchAdSettings() async {
    return await _apiClient.get('/settings/ads', requireAuth: false);
  }
}

