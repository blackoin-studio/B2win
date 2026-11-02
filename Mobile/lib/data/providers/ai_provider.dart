import 'package:b2win/core/network/api_client.dart';

class AiProvider {
  final ApiClient _apiClient;

  AiProvider({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<dynamic> fetchMatchInsight({
    required String homeTeam,
    required String awayTeam,
    required String league,
    required String tip,
    required String odds,
    required String status,
    required String score,
  }) async {
    return await _apiClient.post(
      '/ai/match-insight',
      body: {
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'league': league,
        'tip': tip,
        'odds': odds,
        'status': status,
        'score': score,
      },
      requireAuth: false,
    );
  }

  Future<dynamic> fetchSmartSlip({String riskProfile = 'balanced'}) async {
    return await _apiClient.post(
      '/ai/smart-slip',
      body: {'riskProfile': riskProfile},
      requireAuth: false,
    );
  }

  Future<dynamic> fetchBlogSummary({
    required String title,
    required String description,
  }) async {
    return await _apiClient.post(
      '/ai/blog-summary',
      body: {
        'title': title,
        'description': description,
      },
      requireAuth: false,
    );
  }

  Future<dynamic> sendChatMessage({required String message}) async {
    return await _apiClient.post(
      '/ai/chat',
      body: {'message': message},
      requireAuth: false,
    );
  }
}

