import 'package:get/get.dart';

class NavbarController extends GetxController {
  RxInt currentIndex = 0.obs;
  changeScreen(index) {
    currentIndex.value = index;
   }
}
