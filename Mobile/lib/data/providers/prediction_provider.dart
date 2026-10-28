import 'package:b2win/core/network/api_client.dart';

class PredictionProvider {
  final ApiClient _apiClient;

  PredictionProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<dynamic>> fetchPredictions() async {
    final response = await _apiClient.get('/predictions');
    if (response is List) {
      return response;
    }
    return [];
  }
}
