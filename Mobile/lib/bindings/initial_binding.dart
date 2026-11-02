import 'package:b2win/core/network/api_client.dart';
import 'package:b2win/data/providers/ad_settings_provider.dart';
import 'package:b2win/data/providers/ai_provider.dart';
import 'package:b2win/data/providers/auth_provider.dart';
import 'package:b2win/data/providers/blog_provider.dart';
import 'package:b2win/data/providers/prediction_provider.dart';
import 'package:b2win/data/repositories/ad_settings_repository.dart';
import 'package:b2win/data/repositories/ai_repository.dart';
import 'package:b2win/data/repositories/auth_repository.dart';
import 'package:b2win/data/repositories/blog_repository.dart';
import 'package:b2win/data/repositories/prediction_repository.dart';
import 'package:b2win/features/core/controllers/ad_controller.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = ApiClient();
    Get.put<ApiClient>(apiClient, permanent: true);

    // Providers
    final authProvider = AuthProvider(apiClient: apiClient);
    final predictionProvider = PredictionProvider(apiClient: apiClient);
    final blogProvider = BlogProvider(apiClient: apiClient);
    final adSettingsProvider = AdSettingsProvider(apiClient: apiClient);
    final aiProvider = AiProvider(apiClient: apiClient);

    // Repositories
    Get.put<AuthRepository>(AuthRepository(provider: authProvider), permanent: true);
    Get.put<PredictionRepository>(PredictionRepository(provider: predictionProvider), permanent: true);
    Get.put<BlogRepository>(BlogRepository(provider: blogProvider), permanent: true);
    Get.put<AiRepository>(AiRepository(provider: aiProvider), permanent: true);
    final adSettingsRepository = AdSettingsRepository(provider: adSettingsProvider);
    Get.put<AdSettingsRepository>(adSettingsRepository, permanent: true);
    Get.put<AdController>(AdController(repository: adSettingsRepository), permanent: true);
  }
}
