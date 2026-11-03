import 'package:b2win/core/services/storage_service.dart';
import 'package:b2win/data/models/prediction_model.dart';
import 'package:b2win/data/repositories/prediction_repository.dart';
import 'package:b2win/utils/helper/helper_controller.dart';
import 'package:get/get.dart';

class GameController extends GetxController {
  static GameController get instance => Get.find();

  final PredictionRepository _repository;

  GameController({PredictionRepository? repository})
      : _repository = repository ?? PredictionRepository();

  final RxBool isLoading = true.obs;
  final RxList<PredictionModel> games = <PredictionModel>[].obs;
  final RxSet<String> savedIds = <String>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString searchQuery = ''.obs;

  static String gameKey(PredictionModel g) =>
      (g.id != null && g.id!.isNotEmpty)
          ? g.id!
          : '${g.homeTeam}_${g.awayTeam}_${g.date}';

  List<PredictionModel> get filteredGames {
    final status = selectedStatus.value.toLowerCase();
    final query = searchQuery.value.trim().toLowerCase();

    return games.where((g) {
      final matchesStatus = status == 'all' ||
          (status == 'saved'
              ? savedIds.contains(gameKey(g))
              : g.status.toLowerCase() == status);
      final matchesSearch = query.isEmpty ||
          g.homeTeam.toLowerCase().contains(query) ||
          g.awayTeam.toLowerCase().contains(query) ||
          g.league.toLowerCase().contains(query) ||
          g.tip.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  double get savedCombinedOdds {
    final savedGames =
        games.where((g) => savedIds.contains(gameKey(g))).toList();
    if (savedGames.isEmpty) return 0.0;
    double product = 1.0;
    for (final g in savedGames) {
      final parsed = double.tryParse(g.odds) ?? 1.5;
      final odd = parsed > 1.0 ? parsed : 1.5;
      product *= odd;
    }
    return double.parse(product.toStringAsFixed(2));
  }

  int get wonCount =>
      games.where((g) => g.status.toLowerCase() == 'won').length;

  int get lostCount =>
      games.where((g) => g.status.toLowerCase() == 'lost').length;

  int get pendingCount =>
      games.where((g) => g.status.toLowerCase() == 'pending').length;

  int get winRatePercent {
    final settled = wonCount + lostCount;
    if (settled == 0) return 0;
    return ((wonCount / settled) * 100).round();
  }

  List<String> get recentSettledForm {
    return games
        .where((g) {
          final s = g.status.toLowerCase();
          return s == 'won' || s == 'lost';
        })
        .take(5)
        .map((g) => g.status.toLowerCase() == 'won' ? 'W' : 'L')
        .toList();
  }

  bool isSaved(String id) => savedIds.contains(id);

  Future<void> toggleSaved(String id) async {
    if (savedIds.contains(id)) {
      savedIds.remove(id);
    } else {
      savedIds.add(id);
    }
    savedIds.refresh();
    try {
      final storage = await StorageService.getInstance();
      await storage.saveSavedPredictionIds(savedIds.toList());
    } catch (_) {}
  }

  Future<void> loadSavedPredictions() async {
    try {
      final storage = await StorageService.getInstance();
      final ids = storage.getSavedPredictionIds();
      savedIds.assignAll(ids);
    } catch (_) {}
  }

  void setStatusFilter(String status) {
    selectedStatus.value = status.toLowerCase();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  @override
  void onInit() {
    loadSavedPredictions();
    fetchGameData();
    super.onInit();
  }

  Future<void> fetchGameData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _repository.getPredictions();
      games.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
      Helper.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
