import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  Future<void> initialize() async {
    await hotKeyManager.unregisterAll();
  }
}




