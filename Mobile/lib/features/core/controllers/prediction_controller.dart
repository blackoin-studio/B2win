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
  final RxString errorMessage = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString searchQuery = ''.obs;

  List<PredictionModel> get filteredGames {
    final status = selectedStatus.value.toLowerCase();
    final query = searchQuery.value.trim().toLowerCase();

    return games.where((g) {
      final matchesStatus =
          status == 'all' || g.status.toLowerCase() == status;
      final matchesSearch = query.isEmpty ||
          g.homeTeam.toLowerCase().contains(query) ||
          g.awayTeam.toLowerCase().contains(query) ||
          g.league.toLowerCase().contains(query) ||
          g.tip.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  void setStatusFilter(String status) {
    selectedStatus.value = status.toLowerCase();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  @override
  void onInit() {
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
