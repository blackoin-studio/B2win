import 'package:b2win/features/authentication/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:b2win/common_widgets/buttons/primary_button.dart';
import 'package:b2win/constants/sizes.dart';
import 'package:b2win/constants/text_strings.dart';
import 'package:b2win/features/core/screens/profile/widgets/image_with_icon.dart';
import 'package:b2win/features/core/screens/profile/widgets/profile_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

//import '../../../../repository/authentication_repository/authentication_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final Uri url = Uri.parse('https://www.termsfeed.com/live/2880e2ce-f6fc-4ff3-994a-a15333c9686b');

    //var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //     onPressed: () => Get.back(),
        //     icon: const Icon(LineAwesomeIcons.angle_left)),
        title:
            Text(tProfile, style: Theme.of(context).textTheme.headlineMedium),
        // actions: [
        //   IconButton(
        //       onPressed: () {},
        //       icon: Icon(isDark ? LineAwesomeIcons.sun : LineAwesomeIcons.moon))
        // ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(defaultSpace),
          child: Column(
            children: [
              /// -- IMAGE with ICON
              // const ImageWithIcon(),
              // const SizedBox(height: 10),
              // Text(tProfileHeading,
              //     style: Theme.of(context).textTheme.headlineMedium),
              // Text(tProfileSubHeading,
              //     style: Theme.of(context).textTheme.bodyMedium),
              // const SizedBox(height: 20),

              /// -- BUTTON
              TPrimaryButton(
                  isFullWidth: false,
                  width: 200,
                  text: tEditProfile,
                  onPressed: () {}),//() => Get.to(() => UpdateProfileScreen())),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),

              /// -- MENU
              ProfileMenuWidget(
                  title: "Upgrade to Premium",
                  icon: LineAwesomeIcons.paypal_credit_card,
                  onPress: () {}),
                  ProfileMenuWidget(
                  title: "Rate On Play Store",
                  icon: LineAwesomeIcons.star,
                  onPress: () {
                    final InAppReview inAppReview = InAppReview.instance;

                    inAppReview.openStoreListing();
                  }),
              ProfileMenuWidget(
                  title: "Invite Your Friends",
                  icon: LineAwesomeIcons.user_check,
                  onPress: ()async{
                  await Share.share('https://play.google.com/store/apps/details?id=com.blackoinstudio.b2win');
                  }),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                  title: "Privacy Policy",
                  icon: LineAwesomeIcons.info,
                  onPress: () async {

                    if (!await launchUrl(url)) {
                      throw Exception('Check your  Network Connection');
                      }
                  }),
              ProfileMenuWidget(
                title: "Logout",
                icon: LineAwesomeIcons.alternate_sign_out,
                textColor: Colors.red,
                endIcon: false,
                onPress: () => _showLogoutModal(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showLogoutModal() {
    Get.defaultDialog(
      title: "LOGOUT",
      titleStyle: const TextStyle(fontSize: 20),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        child: Text("Are you sure, you want to Logout?"),
      ),
      confirm: TPrimaryButton(
        isFullWidth: false,
        onPressed: () async {
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'token');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("loggedIn", false);
      Get.off(() => const LoginScreen());
        },
        text: "Yes",
      ),
      cancel: SizedBox(
          width: 100,
          child: OutlinedButton(
              onPressed: () => Get.back(), child: const Text("No"))),
    );
  }
}
