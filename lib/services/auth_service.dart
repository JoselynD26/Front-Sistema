import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = "https://sistema-de-gestion-act-bj8j.onrender.com";
  final storage = const FlutterSecureStorage();

  Future<bool> login(String correo, String contrasena) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo, "contrasena": contrasena}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["access_token"];
      await storage.write(key: "jwt", value: token);
      return true;
    } else {
      return false;
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: "jwt");
  }

  Future<void> logout() async {
    await storage.delete(key: "jwt");
  }
}