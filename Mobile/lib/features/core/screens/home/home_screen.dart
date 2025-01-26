import 'package:b2win/features/core/controllers/navbar_controller.dart';
import 'package:b2win/features/core/screens/blog/blog_screen.dart';
import 'package:b2win/features/core/screens/home/home_card.dart';
import 'package:b2win/features/core/screens/home/navbar.dart';
import 'package:b2win/features/core/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(context) {
    final NavbarController controller = Get.put(NavbarController());
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Welcome back!"),
          centerTitle: false,
        ),
        body: Obx(
          () => controller.currentIndex.value == 0? const MatchCard()
        : controller.currentIndex.value == 1? const BlogScreen(): const ProfileScreen(),
        ),
        bottomNavigationBar: Navbar(
          isDark: isDark,
        ));
  }
}
