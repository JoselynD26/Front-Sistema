class AppConfig {
  static const bool isWeb = bool.fromEnvironment('dart.library.js_util');

  static String get baseUrl {
    if (isWeb) {
      return "http://192.168.1.5:8000"; // tu IP local
    } else {
      return "http://10.0.2.2:8000"; // emulador Android
    }
  }
}