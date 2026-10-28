import 'package:b2win/core/network/api_client.dart';

class BlogProvider {
  final ApiClient _apiClient;

  BlogProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<dynamic>> fetchBlogs() async {
    final response = await _apiClient.get('/blogs');
    if (response is List) {
      return response;
    }
    return [];
  }
}
