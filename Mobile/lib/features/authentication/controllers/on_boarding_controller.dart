import 'package:b2win/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/PageHelpers/LiquidController.dart';
import '../../../constants/colors.dart';
import '../../../constants/image_strings.dart';
import '../../../constants/text_strings.dart';
import '../models/model_on_boarding.dart';
import '../screens/on_boarding/on_boarding_page_widget.dart';

class OnBoardingController extends GetxController {
  //Variables
  final controller = LiquidController();
  RxInt currentPage = 0.obs;

  //Functions to trigger Skip, Next and onPageChange Events
  skip() => currentPage.value != 2
      ? controller.jumpToPage(page: 2)
      : Get.off(
        
        const WelcomeScreen()
        );

  animateToNextSlide() => currentPage.value <= 1?
      controller.animateToPage(page: controller.currentPage + 1): Get.off(const WelcomeScreen());
  onPageChangedCallback(int activePageIndex) =>
      currentPage.value = activePageIndex;

  //Three Onboarding Pages
  final pages = [
    OnBoardingPageWidget(
      model: OnBoardingModel(
        image: onBoardingImage1,
        title: tOnBoardingTitle1,
        subTitle: tOnBoardingSubTitle1,
        counterText: tOnBoardingCounter1,
        bgColor: tOnBoardingPage1Color,
        textColor: onBoardingPageTextColor,
      ),
    ),
    OnBoardingPageWidget(
      model: OnBoardingModel(
        image: onBoardingImage2,
        title: tOnBoardingTitle2,
        subTitle: tOnBoardingSubTitle2,
        counterText: tOnBoardingCounter2,
        bgColor: tOnBoardingPage2Color,
        textColor: onBoardingPageTextColor,
      ),
    ),
    OnBoardingPageWidget(
      model: OnBoardingModel(
        image: onBoardingImage3,
        title: tOnBoardingTitle3,
        subTitle: tOnBoardingSubTitle3,
        counterText: tOnBoardingCounter3,
        bgColor: tOnBoardingPage3Color,
        textColor: onBoardingPageTextColor,
      ),
    ),
  ];
}
