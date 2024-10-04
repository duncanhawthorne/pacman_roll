import 'package:shared_preferences/shared_preferences.dart';

import '../google_logic.dart';
import '../utils/helper.dart';

class User {
  Future<List<String>> loadFromFilesystem() async {
    final prefs = await SharedPreferences.getInstance();
    String gUser = prefs.getString('gUser') ?? G.gUserDefault;
    String gUserIcon = prefs.getString('gUserIcon') ?? G.gUserIconDefault;
    debug(["loadUser", gUser, gUserIcon]);
    return [gUser, gUserIcon];
  }

  Future<void> saveToFilesystem(String gUser, String gUserIcon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', gUser);
    await prefs.setString('gUserIcon', gUserIcon);
    debug(["saveUser", gUser, gUserIcon]);
  }
}

User user = User();
