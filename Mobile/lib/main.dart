import 'package:b2win/bindings/initial_binding.dart';
import 'package:b2win/core/services/storage_service.dart';
import 'package:b2win/routes/app_pages.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:b2win/utils/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final storageService = await StorageService.getInstance();
  final bool isOnboarded = storageService.isOnboarded();
  final bool isLoggedIn = storageService.isLoggedIn();

  final String initialRoute = isLoggedIn
      ? AppRoutes.home
      : isOnboarded
          ? AppRoutes.login
          : AppRoutes.onBoarding;

  runApp(
    GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    ),
  );
  FlutterNativeSplash.remove();
}
