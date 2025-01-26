import 'dart:convert';
import 'package:b2win/features/authentication/screens/login/login_screen.dart';
import 'package:http/http.dart' as http;

import 'package:b2win/constants/api_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final showPassword = false.obs;
  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // TextField Controllers to get data from TextFields
  final email = TextEditingController();
  final password = TextEditingController();
  final userName = TextEditingController();
  final phoneNo = TextEditingController();

  /// Loader
  final isLoading = false.obs;

  // As in the AuthenticationRepository we are calling _setScreen() Method
  // so, whenever there is change in the user state(), screen will be updated.
  // Therefore, when new user is authenticated, AuthenticationRepository() detects
  // the change and call _setScreen() to switch screens



  /// Register New User 
  Future createUser() async {
      isLoading.value = true;
      if (!signupFormKey.currentState!.validate()) {
        isLoading.value = false;
        return;
      }

          final fEmail = email.text.trim();
          final fPassword = password.text.trim();
          final fUsername = userName.text.trim();

      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': fEmail,
          'password': fPassword,
          'username': fUsername,
        }),
      );

      if (response.statusCode == 201) {
          final success = jsonDecode(response.body)['message'];
          isLoading.value = false;
          Get.snackbar("Success", success.toString(),
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 20));

          Get.off(() => const LoginScreen());
      }
     else {
        final error = jsonDecode(response.body)['error'];
        isLoading.value = false;
        Get.snackbar("Error", error.toString(),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 20));
      }
  }
}
