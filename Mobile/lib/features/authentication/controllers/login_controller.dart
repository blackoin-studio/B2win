import 'dart:convert';

import 'package:b2win/constants/api_config.dart';
import 'package:b2win/features/core/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/text_strings.dart';
import '../../../utils/helper/helper_controller.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();
  final storage = const FlutterSecureStorage();

  /// TextField Controllers to get data from TextFields
  final showPassword = false.obs;
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  /// Loader
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;

  /// Login User
  Future<void> login() async {
    isLoading.value = true;
    if (!loginFormKey.currentState!.validate()) {
      isLoading.value = false;
      return;
    }

    // Trim users input
    final email = this.email.text.trim();
    final password = this.password.text.trim();

    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'token', value: data['token']);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("loggedIn", true);
      Get.off(() => const HomeScreen());
      return;
    } else {
      final error = jsonDecode(response.body)['error'];
      isLoading.value = false;
      Helper.errorSnackBar(title: tOhSnap, message: error.toString());
    }
  }
}

  /// [GoogleSignInAuthentication]
  // Future<void> googleSignIn() async {
  //   try {
  //     isGoogleLoading.value = true;
  //     final auth = AuthenticationRepository.instance;
  //     // Sign In with Google
  //     await auth.signInWithGoogle();
  //     // Once the user Signed In, Check if the User Data is already stored in Firestore Collection('Users')
  //     // If not store the data and let the user Login.
  //     // [auth.getUserEmail] will return current LoggedIn user email.
  //     // If record does not exit -> Create new
  //     /// --  In this case or any case do not store password in the Firestore. This is just for learning purpose.
  //     if(!await UserRepository.instance.recordExist(auth.getUserEmail)) {
  //       UserModel user = UserModel(email: auth.getUserEmail, password: '', fullName: auth.getDisplayName, phoneNo: auth.getPhoneNo);
  //       await UserRepository.instance.createUser(user);
  //     }
  //     isGoogleLoading.value = false;
  //     auth.setInitialScreen(auth.firebaseUser);
  //   } catch (e) {
  //     isGoogleLoading.value = false;
  //     Helper.errorSnackBar(title: tOhSnap, message: e.toString());
  //   }
  // }

  /// [FacebookSignInAuthentication]
  // Future<void> facebookSignIn() async {
  //   try {
  //     isFacebookLoading.value = true;
  //     final auth = AuthenticationRepository.instance;
  //     await auth.signInWithFacebook();
  //     /// --  In this case or any case do not store password in the Firestore. This is just for learning purpose.
  //     if(!await UserRepository.instance.recordExist(auth.getUserID)) {
  //       UserModel user = UserModel(email: auth.getUserEmail, password: '', fullName: auth.getDisplayName, phoneNo: auth.getPhoneNo);
  //       await UserRepository.instance.createUser(user);
  //     }
  //     isFacebookLoading.value = false;
  //   } catch (e) {
  //     isFacebookLoading.value = false;
  //     Helper.errorSnackBar(title: tOhSnap, message: e.toString());
  //   }
  // }

