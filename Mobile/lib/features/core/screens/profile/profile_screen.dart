import 'package:b2win/common_widgets/buttons/primary_button.dart';
import 'package:b2win/constants/sizes.dart';
import 'package:b2win/constants/text_strings.dart';
import 'package:b2win/features/core/controllers/profile_controller.dart';
import 'package:b2win/features/core/screens/profile/widgets/profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();
    final Uri privacyPolicyUrl = Uri.parse(
      'https://www.termsfeed.com/live/2880e2ce-f6fc-4ff3-994a-a15333c9686b',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tProfile, style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(defaultSpace),
          child: Column(
            children: [
              // Dynamic User Profile Card
              Obx(() {
                final user = profileController.currentUser.value;
                final username =
                    (user?.username != null && user!.username!.isNotEmpty)
                        ? user.username!
                        : 'B2WIN Member';
                final email = user?.email ?? '';
                final initial = username[0].toUpperCase();

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.redAccent,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    username,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (user?.isAdmin == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              ProfileMenuWidget(
                title: "Upgrade to Premium",
                icon: LineAwesomeIcons.paypal_credit_card,
                onPress: () {},
              ),
              ProfileMenuWidget(
                title: "Rate On Play Store",
                icon: LineAwesomeIcons.star,
                onPress: () {
                  final InAppReview inAppReview = InAppReview.instance;
                  inAppReview.openStoreListing();
                },
              ),
              ProfileMenuWidget(
                title: "Invite Your Friends",
                icon: LineAwesomeIcons.user_check,
                onPress: () async {
                  await Share.share(
                    'https://play.google.com/store/apps/details?id=com.blackoinstudio.b2win',
                  );
                },
              ),
              const Divider(),
              const SizedBox(height: 10),
              ProfileMenuWidget(
                title: "Privacy Policy",
                icon: LineAwesomeIcons.info,
                onPress: () async {
                  if (!await launchUrl(privacyPolicyUrl)) {
                    Get.snackbar(
                      'Error',
                      'Check your Network Connection',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
              ProfileMenuWidget(
                title: "Logout",
                icon: LineAwesomeIcons.alternate_sign_out,
                textColor: Colors.red,
                endIcon: false,
                onPress: () => _showLogoutModal(profileController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutModal(ProfileController controller) {
    Get.defaultDialog(
      title: "LOGOUT",
      titleStyle: const TextStyle(fontSize: 20),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        child: Text("Are you sure you want to logout?"),
      ),
      confirm: Obx(
        () => TPrimaryButton(
          isFullWidth: false,
          isLoading: controller.isLoggingOut.value,
          onPressed: () {
            Get.back();
            controller.logout();
          },
          text: "Yes",
        ),
      ),
      cancel: SizedBox(
        width: 100,
        child: OutlinedButton(
          onPressed: () => Get.back(),
          child: const Text("No"),
        ),
      ),
    );
  }
}
