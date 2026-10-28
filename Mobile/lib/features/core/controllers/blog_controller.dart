import 'package:b2win/data/models/blog_model.dart';
import 'package:b2win/data/repositories/blog_repository.dart';
import 'package:b2win/utils/helper/helper_controller.dart';
import 'package:get/get.dart';

class BlogController extends GetxController {
  static BlogController get instance => Get.find();

  final BlogRepository _repository;

  BlogController({BlogRepository? repository})
      : _repository = repository ?? BlogRepository();

  final RxBool isLoading = true.obs;
  final RxList<BlogModel> blogs = <BlogModel>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    fetchBlogData();
    super.onInit();
  }

  Future<void> fetchBlogData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _repository.getBlogs();
      blogs.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
      Helper.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
