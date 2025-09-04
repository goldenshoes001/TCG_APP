import 'package:shared_preferences/shared_preferences.dart';

class SaveData {
  static final SaveData _instance = SaveData._internal();
  SaveData._internal();

  factory SaveData() {
    return _instance;
  }

  static late SharedPreferences _pref;

  static Future<void> initPreferences() async {
    _pref = await SharedPreferences.getInstance();
  }

  Future<void> saveWithKey(String key, var value) async {
    await _pref.setString(key, value);
  }

  Future<String?> loadWithKey(String key) async {
    return _pref.getString(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await _pref.setBool(key, value);
  }

  Future<bool?> loadBool(String key) async {
    return _pref.getBool(key);
  }
}
