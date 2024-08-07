import 'package:colorpicker/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HotkeyProvider with ChangeNotifier {
  String _hotkey = Constants.defaultHotKey;

  String get hotkey => _hotkey;

  HotkeyProvider() {
    _loadHotkey();
  }

  Future<void> _loadHotkey() async {
    final prefs = await SharedPreferences.getInstance();
    _hotkey = prefs.getString('hotkey') ?? Constants.defaultHotKey;
    const platform = MethodChannel('com.example.colorpicker/color_picker');
    await platform.invokeMethod('updateHotkey', hotkey);
    notifyListeners();
  }

  void updateHotkey(String newHotkey) {
    _hotkey = newHotkey;
    notifyListeners();
  }
}