import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = '_tokenKey';
const _emailKey = '_emailKey';

class LocalStorage extends GetxService {
  late final SharedPreferences sharedPreferences;

  Future<void> onInitStorage() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  Future cacheToken(String token) =>
      sharedPreferences.setString(_tokenKey, token);

  Future cacheEmail(String email) =>
      sharedPreferences.setString(_emailKey, email);

  String get email => sharedPreferences.getString(_emailKey) ?? '';

  String get token => sharedPreferences.getString(_tokenKey) ?? '';

  void clear() {
    sharedPreferences.clear();
  }
}
