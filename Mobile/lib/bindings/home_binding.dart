import 'package:b2win/data/repositories/auth_repository.dart';
import 'package:b2win/data/repositories/blog_repository.dart';
import 'package:b2win/data/repositories/prediction_repository.dart';
import 'package:b2win/features/core/controllers/blog_controller.dart';
import 'package:b2win/features/core/controllers/navbar_controller.dart';
import 'package:b2win/features/core/controllers/prediction_controller.dart';
import 'package:b2win/features/core/controllers/profile_controller.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavbarController>(() => NavbarController());
    Get.lazyPut<GameController>(
      () => GameController(repository: Get.find<PredictionRepository>()),
    );
    Get.lazyPut<BlogController>(
      () => BlogController(repository: Get.find<BlogRepository>()),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(authRepository: Get.find<AuthRepository>()),
    );
  }
}
