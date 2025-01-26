import 'package:b2win/features/authentication/screens/login/login_screen.dart';
import 'package:b2win/features/authentication/screens/on_boarding/on_boarding_screen.dart';
import 'package:b2win/features/core/screens/home/home_screen.dart';
import 'package:b2win/utils/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

// checking if onboarded
  final prefs = await SharedPreferences.getInstance();
  final onboardingValue = prefs.getBool("onboarded") ?? false;

// checking if logged In
  final loggedIn = prefs.getBool("loggedIn") ?? false;

  runApp(
    GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: loggedIn
          ? const HomeScreen()
          : onboardingValue
              ? const LoginScreen()
              : const OnBoardingScreen(),
    ),
  );
  FlutterNativeSplash.remove();
}
