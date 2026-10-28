import 'dart:convert';
import 'package:b2win/core/services/storage_service.dart';
import 'package:b2win/data/models/prediction_model.dart';
import 'package:b2win/data/providers/prediction_provider.dart';

class PredictionRepository {
  final PredictionProvider _provider;
  final StorageService? _storageService;

  PredictionRepository({
    PredictionProvider? provider,
    StorageService? storageService,
  })  : _provider = provider ?? PredictionProvider(),
        _storageService = storageService;

  Future<StorageService> _getStorage() async {
    return _storageService ?? await StorageService.getInstance();
  }

  Future<List<PredictionModel>> getPredictions() async {
    try {
      final rawData = await _provider.fetchPredictions();

      final predictions = rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => PredictionModel.fromJson(e))
          .toList();

      _sortPredictions(predictions);

      // Cache for offline resilience
      final storage = await _getStorage();
      await storage.saveCachedPredictions(
        jsonEncode(predictions.map((p) => p.toJson()).toList()),
      );

      return predictions;
    } catch (networkError) {
      // Fallback to offline cache
      final storage = await _getStorage();
      final cachedJson = storage.getCachedPredictions();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson) as List;
          final cachedPredictions = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => PredictionModel.fromJson(e))
              .toList();
          _sortPredictions(cachedPredictions);
          return cachedPredictions;
        } catch (_) {
          // If cached parsing fails, rethrow network error
        }
      }
      rethrow;
    }
  }

  void _sortPredictions(List<PredictionModel> items) {
    items.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
  }
}
