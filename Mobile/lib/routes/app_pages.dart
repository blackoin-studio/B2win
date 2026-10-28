import 'package:b2win/bindings/auth_binding.dart';
import 'package:b2win/bindings/home_binding.dart';
import 'package:b2win/bindings/on_boarding_binding.dart';
import 'package:b2win/features/authentication/screens/login/login_screen.dart';
import 'package:b2win/features/authentication/screens/on_boarding/on_boarding_screen.dart';
import 'package:b2win/features/authentication/screens/signup/signup_screen.dart';
import 'package:b2win/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:b2win/features/core/screens/blog/blog_details_screen.dart';
import 'package:b2win/features/core/screens/home/home_screen.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:get/get.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.onBoarding,
      page: () => const OnBoardingScreen(),
      binding: OnBoardingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomeScreen(),
      binding: OnBoardingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.blogDetails,
      page: () => const BlogDetailsScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
