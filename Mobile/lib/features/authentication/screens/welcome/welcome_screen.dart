import 'package:b2win/constants/colors.dart';
import 'package:b2win/constants/image_strings.dart';
import 'package:b2win/constants/sizes.dart';
import 'package:b2win/constants/text_strings.dart';
import 'package:b2win/core/services/storage_service.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:b2win/utils/animations/fade_in_animation/animation_design.dart';
import 'package:b2win/utils/animations/fade_in_animation/fade_in_animation_controller.dart';
import 'package:b2win/utils/animations/fade_in_animation/fade_in_animation_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FadeInAnimationController>();
    controller.animationIn();

    var mediaQuery = MediaQuery.of(context);
    var width = mediaQuery.size.width;
    var height = mediaQuery.size.height;
    var brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    Future<void> storePrefsNavLogin() async {
      final storage = await StorageService.getInstance();
      await storage.setOnboarded(true);
      Get.offNamed(AppRoutes.login);
    }

    Future<void> storePrefsNavSignup() async {
      final storage = await StorageService.getInstance();
      await storage.setOnboarded(true);
      Get.offNamed(AppRoutes.signup);
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkMode ? tSecondaryColor : tPrimaryColor,
        body: Stack(
          children: [
            TFadeInAnimation(
              isTwoWayAnimation: false,
              durationInMs: 1200,
              animate: TAnimatePosition(
                bottomAfter: 0,
                bottomBefore: -100,
                leftBefore: 0,
                leftAfter: 0,
                topAfter: 0,
                topBefore: 0,
                rightAfter: 0,
                rightBefore: 0,
              ),
              child: Container(
                padding: const EdgeInsets.all(defaultSpace),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Hero(
                      tag: 'welcome-image-tag',
                      child: Image(
                        image: const AssetImage(tWelcomeScreenImage),
                        width: width * 0.7,
                        height: height * 0.6,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          tWelcomeTitle,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        Text(
                          tWelcomeSubTitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: storePrefsNavLogin,
                            child: Text(tLogin.toUpperCase()),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: storePrefsNavSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tPrimaryColor,
                            ),
                            child: Text(tSignup.toUpperCase()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
