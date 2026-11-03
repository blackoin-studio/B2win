import 'package:b2win/common_widgets/buttons/primary_button.dart';
import 'package:b2win/constants/sizes.dart';
import 'package:b2win/constants/text_strings.dart';
import 'package:b2win/features/core/controllers/ad_controller.dart';
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
                final isVip = profileController.isVipActive.value;
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
                                if (isVip) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'VIP PASS',
                                      style: TextStyle(
                                        color: Colors.amberAccent,
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
                title: "Upgrade to Premium (VIP)",
                icon: LineAwesomeIcons.crown,
                onPress: () => _showVipPassModal(context, profileController),
              ),
              ProfileMenuWidget(
                title: "Edit Profile & Password",
                icon: LineAwesomeIcons.user_edit,
                onPress: () => _showEditProfileDialog(context, profileController),
              ),
              Obx(
                () => ProfileMenuWidget(
                  title: profileController.isDarkMode.value
                      ? "Appearance: Dark Mode"
                      : "Appearance: Light Mode",
                  icon: profileController.isDarkMode.value
                      ? LineAwesomeIcons.moon
                      : LineAwesomeIcons.sun,
                  onPress: () => profileController.toggleThemeMode(),
                ),
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
                    'Get daily AI-backed sports predictions on B2WIN! Download here: https://play.google.com/store/apps/details?id=com.blackoinstudio.b2win',
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
                title: "Delete Account",
                icon: LineAwesomeIcons.trash,
                textColor: Colors.redAccent,
                onPress: () => _showDeleteAccountModal(profileController),
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

  void _showVipPassModal(BuildContext context, ProfileController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Obx(() {
            final isVip = controller.isVipActive.value;
            final expiry = controller.vipExpiry.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amberAccent, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'B2WIN VIP Premium Pass',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Instant access to all [VIP] high-confidence predictions\n'
                  '• Full AI tactical breakdowns & high-odds accumulator picks\n'
                  '• 24-hour complimentary Ad-Supported VIP Pass available!',
                  style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 18),
                if (isVip)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Text(
                      expiry != null
                          ? 'Active VIP Pass until ${expiry.toLocal().toString().substring(0, 16)}'
                          : 'Your VIP Pass is currently active!',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (Get.isRegistered<AdController>()) {
                          Get.find<AdController>()
                              .recordInteractionAndMaybeShowInterstitial();
                        }
                        await controller.unlockVipPass();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text(
                        'Unlock 24h VIP Pass (Free / Ad-Supported)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          }),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileController controller) {
    final usernameCtrl = TextEditingController(
      text: controller.currentUser.value?.username ?? '',
    );
    final passwordCtrl = TextEditingController();

    Get.defaultDialog(
      title: "Edit Profile & Password",
      titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter new username',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (optional)',
                hintText: 'Min 6 characters to change',
              ),
            ),
          ],
        ),
      ),
      confirm: Obx(
        () => TPrimaryButton(
          isFullWidth: false,
          isLoading: controller.isUpdating.value,
          onPressed: () async {
            final ok = await controller.updateProfile(
              username: usernameCtrl.text.trim(),
              newPassword: passwordCtrl.text.trim().isEmpty
                  ? null
                  : passwordCtrl.text.trim(),
            );
            if (ok) Get.back();
          },
          text: "Save",
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text("Cancel"),
      ),
    );
  }

  void _showDeleteAccountModal(ProfileController controller) {
    Get.defaultDialog(
      title: "DELETE ACCOUNT",
      titleStyle: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: Colors.redAccent,
      ),
      content: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Text(
          "Are you sure you want to permanently delete your B2WIN account and all associated profile data? This action cannot be undone.",
          textAlign: TextAlign.center,
        ),
      ),
      confirm: Obx(
        () => TPrimaryButton(
          isFullWidth: false,
          isLoading: controller.isDeleting.value,
          onPressed: () {
            Get.back();
            controller.deleteAccount();
          },
          text: "Delete Forever",
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text("Cancel"),
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
