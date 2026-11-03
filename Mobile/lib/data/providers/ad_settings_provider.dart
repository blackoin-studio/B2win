import 'package:b2win/core/network/api_client.dart';

class AdSettingsProvider {
  final ApiClient _apiClient;

  AdSettingsProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<dynamic> fetchAdSettings() async {
    return await _apiClient.get('/settings/ads', requireAuth: false);
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    try {
      final response = await _apiClient.get(
        '/settings/announcements',
        requireAuth: false,
      );
      if (response is List) {
        return response
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (response is Map && response['data'] is List) {
        return (response['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}

