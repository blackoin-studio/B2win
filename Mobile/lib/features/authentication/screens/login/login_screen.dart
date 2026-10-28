import 'package:b2win/common_widgets/form/form_divider_widget.dart';
import 'package:b2win/common_widgets/form/form_header_widget.dart';
import 'package:b2win/common_widgets/form/social_footer.dart';
import 'package:b2win/constants/image_strings.dart';
import 'package:b2win/constants/sizes.dart';
import 'package:b2win/constants/text_strings.dart';
import 'package:b2win/features/authentication/controllers/login_controller.dart';
import 'package:b2win/features/authentication/screens/login/widgets/login_form_widget.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormHeaderWidget(
                  image: tWelcomeScreenImage,
                  title: tLoginTitle,
                  subTitle: tLoginSubTitle,
                ),
                const LoginFormWidget(),
                const TFormDividerWidget(),
                SocialFooter(
                  text1: tDontHaveAnAccount,
                  text2: tSignup,
                  onGooglePressed: () => controller.signInWithGoogle(),
                  onPressed: () => Get.offNamed(AppRoutes.signup),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
