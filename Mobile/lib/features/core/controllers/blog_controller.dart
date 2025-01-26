import 'dart:convert';
import 'package:b2win/constants/api_config.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class BlogController extends GetxController {
  var isLoading = true.obs;
  var blogs = <dynamic>[].obs;

  @override
  void onInit() {
    fetchBlogData();
    super.onInit();
  }

  Future<void> fetchBlogData() async {
    try {
      isLoading(true);
      
      final response = await http.get(Uri.parse('$baseUrl/blogs'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        blogs.value = sortBlogDataByDate(data);
      } else {
        Get.snackbar('Error', 'Failed to load data');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  List<dynamic> sortBlogDataByDate(List<dynamic> data) {
    data.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    return data;
  }
}
