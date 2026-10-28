import 'package:b2win/data/repositories/auth_repository.dart';
import 'package:b2win/features/authentication/controllers/login_controller.dart';
import 'package:b2win/features/authentication/controllers/signup_controller.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(authRepository: Get.find<AuthRepository>()),
    );
    Get.lazyPut<SignUpController>(
      () => SignUpController(authRepository: Get.find<AuthRepository>()),
    );
  }
}
