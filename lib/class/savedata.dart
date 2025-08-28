import 'package:shared_preferences/shared_preferences.dart';

class SaveData {

  static final SaveData _instance = SaveData._internal();


  SaveData._internal();

  factory SaveData() {
    return _instance;
  }

  SharedPreferences? pref;

  Future<void> initPreferences() async {
    pref = await SharedPreferences.getInstance();
  }

  Future<void> saveWithKey(String key, var value) async {
    await pref?.setString(key, value);
  }

  Future<String?> loadWithKey(String key) async {
    return pref?.getString(key);
  }


  Future<void> saveBool(String key, bool value) async {
    await pref?.setBool(key, value);
  }


  Future<bool?> loadBool(String key) async {
    return pref?.getBool(key);
  }
}
