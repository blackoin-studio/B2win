import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../constants/image_strings.dart';
import '../../constants/sizes.dart';
import '../../constants/text_strings.dart';
import '../buttons/clickable_richtext_widget.dart';
import '../buttons/social_button.dart';

class SocialFooter extends StatelessWidget {
  const SocialFooter({
    super.key,
    this.text1 = tDontHaveAnAccount,
    this.text2 = tSignup,
    required this.onPressed,
    this.onGooglePressed,
    this.onFacebookPressed,
  });

  final String text1, text2;
  final VoidCallback onPressed;
  final VoidCallback? onGooglePressed;
  final VoidCallback? onFacebookPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: defaultSpace * 1.5, bottom: defaultSpace),
      child: Column(
        children: [
          TSocialButton(
            image: tGoogleLogo,
            background: tGoogleBgColor,
            foreground: tGoogleForegroundColor,
            text: '${tConnectWith.tr} ${tGoogle.tr}',
            onPressed: onGooglePressed ?? () {},
          ),
          const SizedBox(height: 10),
          TSocialButton(
            image: tFacebookLogo,
            foreground: tWhiteColor,
            background: tFacebookBgColor,
            text: '${tConnectWith.tr} ${tFacebook.tr}',
            onPressed: onFacebookPressed ?? () {},
          ),
          const SizedBox(height: defaultSpace * 2),
          ClickableRichTextWidget(
            text1: text1.tr,
            text2: text2.tr,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
