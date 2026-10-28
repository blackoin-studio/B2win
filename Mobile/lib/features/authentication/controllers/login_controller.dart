import 'package:b2win/core/network/api_exceptions.dart';
import 'package:b2win/data/repositories/auth_repository.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/text_strings.dart';
import '../../../utils/helper/helper_controller.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final AuthRepository _authRepository;

  LoginController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  /// TextField Controllers & State
  final showPassword = false.obs;
  final email = TextEditingController();
  final password = TextEditingController();
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  /// Loader
  final isLoading = false.obs;

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }

  /// Login User via Supabase Auth
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;
      final trimmedEmail = email.text.trim();
      final trimmedPassword = password.text.trim();

      await _authRepository.login(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      Get.offAllNamed(AppRoutes.home);
    } on ApiException catch (e) {
      Helper.errorSnackBar(title: tOhSnap, message: e.message);
    } catch (e) {
      Helper.errorSnackBar(title: tOhSnap, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Send Forgot Password Email via Supabase Auth
  Future<void> forgotPassword() async {
    final trimmedEmail = email.text.trim();
    if (trimmedEmail.isEmpty) {
      Helper.warningSnackBar(
        title: 'Email Required',
        message: 'Please enter your email address first.',
      );
      return;
    }

    try {
      isLoading.value = true;
      final msg = await _authRepository.forgotPassword(trimmedEmail);
      Helper.successSnackBar(title: 'Reset Email Sent', message: msg);
    } on ApiException catch (e) {
      Helper.errorSnackBar(title: tOhSnap, message: e.message);
    } catch (e) {
      Helper.errorSnackBar(title: tOhSnap, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend Confirmation Email via Supabase Auth
  Future<void> resendConfirmationEmail() async {
    final trimmedEmail = email.text.trim();
    if (trimmedEmail.isEmpty) {
      Helper.warningSnackBar(
        title: 'Email Required',
        message: 'Please enter your email address to resend confirmation.',
      );
      return;
    }

    try {
      isLoading.value = true;
      final msg = await _authRepository.resendConfirmation(trimmedEmail);
      Helper.successSnackBar(title: 'Confirmation Sent', message: msg);
    } on ApiException catch (e) {
      Helper.errorSnackBar(title: tOhSnap, message: e.message);
    } catch (e) {
      Helper.errorSnackBar(title: tOhSnap, message: e.toString());
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
          title: tOhSnap,
          message: 'Could not launch Google Sign-In browser.',
        );
      }
    } on ApiException catch (e) {
      Helper.errorSnackBar(title: tOhSnap, message: e.message);
    } catch (e) {
      Helper.errorSnackBar(title: tOhSnap, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
