import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  Future<SharedPreferences> get prefs async => SharedPreferences.getInstance();
}




