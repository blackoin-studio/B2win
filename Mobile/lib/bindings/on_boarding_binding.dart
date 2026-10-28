import 'package:b2win/features/authentication/controllers/on_boarding_controller.dart';
import 'package:b2win/utils/animations/fade_in_animation/fade_in_animation_controller.dart';
import 'package:get/get.dart';

class OnBoardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnBoardingController>(() => OnBoardingController());
    Get.lazyPut<FadeInAnimationController>(() => FadeInAnimationController());
  }
}
