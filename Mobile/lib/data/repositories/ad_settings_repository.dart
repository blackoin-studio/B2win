import 'package:b2win/data/models/ad_settings_model.dart';
import 'package:b2win/data/providers/ad_settings_provider.dart';

class AdSettingsRepository {
  final AdSettingsProvider _provider;

  AdSettingsRepository({required AdSettingsProvider provider})
      : _provider = provider;

  Future<AdSettingsModel> getAdSettings() async {
    final response = await _provider.fetchAdSettings();
    if (response is Map<String, dynamic>) {
      return AdSettingsModel.fromJson(response);
    }
    return const AdSettingsModel();
  }
}

