import 'package:b2win/constants/colors.dart';
import 'package:b2win/features/core/controllers/navbar_controller.dart';
import "package:flutter/material.dart";
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class Navbar extends StatelessWidget {
  Navbar({
    super.key,
    required this.isDark,
  });

  final bool isDark;
  final NavbarController controller = Get.put(NavbarController());

  @override
  Widget build(context) {
    return Container(
      color: isDark ? tSecondaryColor : tCardBgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
        child: GNav(
            backgroundColor: isDark ? tSecondaryColor : tCardBgColor,
            color: isDark ? tWhiteColor : tDarkColor,
            activeColor: isDark ? tWhiteColor : tDarkColor,
            tabBackgroundColor: Colors.red.shade800,
            gap: 8,
            onTabChange: (index) {
              controller.changeScreen(index);
            },
            padding: const EdgeInsets.all(16),
            tabs: const [
              GButton(icon: LineAwesomeIcons.football_ball, text: 'Tips'),
              GButton(icon: LineAwesomeIcons.blog, text: 'Blog'),
              GButton(icon: LineAwesomeIcons.user_cog, text: 'Settings')
            ]),
      ),
    );
  }
}
