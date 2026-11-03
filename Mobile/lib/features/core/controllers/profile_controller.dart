import 'package:b2win/core/services/storage_service.dart';
import 'package:b2win/data/models/user_model.dart';
import 'package:b2win/data/repositories/auth_repository.dart';
import 'package:b2win/routes/app_routes.dart';
import 'package:b2win/utils/helper/helper_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final AuthRepository _authRepository;

  ProfileController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final RxBool isLoggingOut = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool isVipActive = false.obs;
  final RxBool isDarkMode = true.obs;
  final Rxn<DateTime> vipExpiry = Rxn<DateTime>();
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    loadUserProfile();
    loadVipStatus();
    loadThemeMode();
    super.onInit();
  }

  Future<void> loadThemeMode() async {
    try {
      final storage = await StorageService.getInstance();
      final saved = storage.getThemeMode();
      if (saved == 'light') {
        isDarkMode.value = false;
      } else if (saved == 'dark') {
        isDarkMode.value = true;
      } else {
        isDarkMode.value = Get.isDarkMode;
      }
    } catch (_) {}
  }

  Future<void> toggleThemeMode() async {
    final nextDark = !isDarkMode.value;
    isDarkMode.value = nextDark;
    Get.changeThemeMode(nextDark ? ThemeMode.dark : ThemeMode.light);
    try {
      final storage = await StorageService.getInstance();
      await storage.saveThemeMode(nextDark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> loadVipStatus() async {
    try {
      final storage = await StorageService.getInstance();
      isVipActive.value = storage.isVipPassActive();
      vipExpiry.value = storage.getVipPassExpiry();
    } catch (_) {
      isVipActive.value = false;
    }
  }

  Future<void> unlockVipPass({Duration duration = const Duration(hours: 24)}) async {
    final storage = await StorageService.getInstance();
    final expiry = await storage.activateVipPass(duration: duration);
    isVipActive.value = true;
    vipExpiry.value = expiry;
    Helper.successSnackBar(
      title: 'VIP Pass Activated!',
      message: 'All VIP predictions are now unlocked for 24 hours.',
    );
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

  Future<bool> updateProfile({String? username, String? newPassword}) async {
    try {
      isUpdating.value = true;
      final updated = await _authRepository.updateAccount(
        username: username,
        newPassword: newPassword,
      );
      currentUser.value = updated;
      Helper.successSnackBar(
        title: 'Success',
        message: 'Your account details have been updated.',
      );
      return true;
    } catch (e) {
      Helper.errorSnackBar(
        title: 'Update Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      isDeleting.value = true;
      await _authRepository.deleteAccount();
      currentUser.value = null;
      Helper.successSnackBar(
        title: 'Account Deleted',
        message: 'Your account and personal data have been permanently removed.',
      );
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Helper.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete account: $e',
      );
    } finally {
      isDeleting.value = false;
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
