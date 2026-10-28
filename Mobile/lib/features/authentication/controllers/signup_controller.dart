import 'package:b2win/core/network/api_exceptions.dart';
import 'package:b2win/data/repositories/auth_repository.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:b2win/utils/helper/helper_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final AuthRepository _authRepository;

  SignUpController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final showPassword = false.obs;
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // Form Field Controllers
  final email = TextEditingController();
  final password = TextEditingController();
  final userName = TextEditingController();

  /// Loader
  final isLoading = false.obs;

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    userName.dispose();
    super.onClose();
  }

  /// Register New User (triggers Supabase confirmation email when enabled)
  Future<void> createUser() async {
    if (!signupFormKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;
      final fEmail = email.text.trim();
      final fPassword = password.text.trim();
      final fUsername = userName.text.trim();

      final message = await _authRepository.register(
        email: fEmail,
        password: fPassword,
        username: fUsername,
      );

      Helper.successSnackBar(title: 'Success', message: message);
      Get.offNamed(AppRoutes.login);
    } on ApiException catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.message);
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Initiate Supabase Google OAuth Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final oauthUrl = await _authRepository.getGoogleSignInUrl();
      final uri = Uri.parse(oauthUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        Helper.errorSnackBar(
          title: 'Error',
          message: 'Could not launch Google Sign-In browser.',
        );
      }
    } on ApiException catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.message);
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
