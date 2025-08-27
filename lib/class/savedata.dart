import 'package:shared_preferences/shared_preferences.dart';

class SaveData {
  SharedPreferences? pref;
  String key;
  String value;

  SaveData({this.key = "", this.value = ""});

  Future<void> initPreferences() async {
    pref = await SharedPreferences.getInstance();
  }

  Future<void> saveWithKey(String key, var value) async {
    await pref?.setString(key, value);
  }

  Future<String?> loadWithKey(String key) async {
    return pref?.getString(key);
  }

  // Methode zum Speichern eines booleschen Wertes
  Future<void> saveBool(String key, bool value) async {
    await pref?.setBool(key, value);
  }

  // Methode zum Laden eines booleschen Wertes
  Future<bool?> loadBool(String key) async {

    return pref!.getBool(key);
  }
}
