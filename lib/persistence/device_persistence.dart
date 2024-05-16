import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class DevicePersistence {
  FutureOr<void> set(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  FutureOr<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
