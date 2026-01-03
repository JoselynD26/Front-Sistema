class AppConfig {
  static const bool isWeb = bool.fromEnvironment('dart.library.js_util');

  static String get baseUrl {
    return "https://sistema-de-gestion-act-bj8j.onrender.com";
  }
}