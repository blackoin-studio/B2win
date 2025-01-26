import 'dart:convert';
import 'package:b2win/constants/api_config.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class GameController extends GetxController {
  var isLoading = true.obs;
  var games = <dynamic>[].obs;

  @override
  void onInit() {
    fetchGameData();
    super.onInit();
  }

  Future<void> fetchGameData() async {
    try {
      isLoading(true);
      
      final response = await http.get(Uri.parse('$baseUrl/predictions'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        games.value = sortGameDataByDate(data);
      } else {
        Get.snackbar('Error', 'Failed to load data');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  List<dynamic> sortGameDataByDate(List<dynamic> data) {
    data.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    return data;
  }
}
