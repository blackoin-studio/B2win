import 'dart:convert';
import 'package:b2win/core/services/storage_service.dart';
import 'package:b2win/data/models/blog_model.dart';
import 'package:b2win/data/providers/blog_provider.dart';

class BlogRepository {
  final BlogProvider _provider;
  final StorageService? _storageService;

  BlogRepository({
    BlogProvider? provider,
    StorageService? storageService,
  })  : _provider = provider ?? BlogProvider(),
        _storageService = storageService;

  Future<StorageService> _getStorage() async {
    return _storageService ?? await StorageService.getInstance();
  }

  Future<List<BlogModel>> getBlogs() async {
    try {
      final rawData = await _provider.fetchBlogs();

      final blogs = rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => BlogModel.fromJson(e))
          .toList();

      _sortBlogs(blogs);

      // Cache for offline resilience
      final storage = await _getStorage();
      await storage.saveCachedBlogs(
        jsonEncode(blogs.map((b) => b.toJson()).toList()),
      );

      return blogs;
    } catch (networkError) {
      // Fallback to offline cache
      final storage = await _getStorage();
      final cachedJson = storage.getCachedBlogs();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson) as List;
          final cachedBlogs = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => BlogModel.fromJson(e))
              .toList();
          _sortBlogs(cachedBlogs);
          return cachedBlogs;
        } catch (_) {
          // If cached parsing fails, rethrow network error
        }
      }
      rethrow;
    }
  }

  void _sortBlogs(List<BlogModel> items) {
    items.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
  }
}
