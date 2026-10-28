import 'package:b2win/data/models/user_model.dart';
import 'package:b2win/data/repositories/auth_repository.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:b2win/utils/helper/helper_controller.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final AuthRepository _authRepository;

  ProfileController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final RxBool isLoggingOut = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    loadUserProfile();
    super.onInit();
  }

  Future<void> loadUserProfile() async {
    final cached = await _authRepository.getCurrentUser(refreshRemote: false);
    if (cached != null) {
      currentUser.value = cached;
    }
    final remote = await _authRepository.getCurrentUser(refreshRemote: true);
    if (remote != null) {
      currentUser.value = remote;
    }
  }

  Future<void> logout() async {
    try {
      isLoggingOut.value = true;
      await _authRepository.logout();
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Helper.errorSnackBar(title: 'Error', message: 'Failed to log out: $e');
    } finally {
      isLoggingOut.value = false;
    }
  }
}
