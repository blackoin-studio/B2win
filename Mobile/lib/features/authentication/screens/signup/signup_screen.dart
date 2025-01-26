import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:b2win/common_widgets/form/social_footer.dart';
import 'package:b2win/constants/image_strings.dart';
import 'package:b2win/constants/text_strings.dart';
import 'package:b2win/features/authentication/screens/login/login_screen.dart';
import 'package:b2win/features/authentication/screens/signup/widgets/signup_form_widget.dart';
import '../../../../common_widgets/form/form_divider_widget.dart';
import '../../../../common_widgets/form/form_header_widget.dart';
import '../../../../constants/sizes.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    title: tSignUpTitle,
                    subTitle: tSignUpSubTitle,
                    imageHeight: 0.1),
                const SignUpFormWidget(),
                const TFormDividerWidget(),
                SocialFooter(
                    text1: tAlreadyHaveAnAccount,
                    text2: tLogin,
                    onPressed: () => Get.off(() => const LoginScreen())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
