// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Servidor local para web o Prod desde environment
  final String baseUrl = const String.fromEnvironment('API_URL', defaultValue: "http://localhost:8000");
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 🔒 STORAGE HELPERS (Conditional Web/Mobile)
  
  Future<void> _storageWrite({required String key, required String value}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _storageRead({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  Future<void> _storageDeleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // -------------------- AUTH --------------------
  Future<bool> login(String username, String password) async {
    try {
      // Limpiar datos previos
      await _storageDeleteAll();

      final url = Uri.parse("$baseUrl/login/");
      final body = jsonEncode({"correo": username, "contrasena": password});

      print("[LOGIN] Intentando conectar a: $url");
      
      final response = await http.post(url, headers: {
        "Content-Type": "application/json",
      }, body: body).timeout(Duration(seconds: 30));

      print("[LOGIN] ${response.statusCode} -> ${response.body}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["access_token"];
        if (token != null) {
          await _storageWrite(key: "jwt", value: token);
          if (data.containsKey("rol")) {
            await _storageWrite(key: "rol", value: data["rol"].toString());
          }
          if (data.containsKey("id")) {
            await _storageWrite(key: "usuario_id", value: data["id"].toString());
          }
          if (data.containsKey("nombres")) {
            await _storageWrite(key: "nombres", value: data["nombres"].toString());
          }
          if (data.containsKey("apellidos")) {
            await _storageWrite(key: "apellidos", value: data["apellidos"].toString());
          }
          if (data.containsKey("docente_id") && data["docente_id"] != null) {
            final dId = data["docente_id"].toString();
            await _storageWrite(key: "docente_id", value: dId);
          }
          // Guardar correo
          await _storageWrite(key: "email", value: username);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("[LOGIN ERROR] $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _storageDeleteAll();
  }

  Future<String?> getToken() async {
    return await _storageRead(key: "jwt");
  }

  // Helper: headers con o sin token
  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await getToken();
    final h = <String, String>{};
    if (json) h["Content-Type"] = "application/json";
    if (token != null) h["Authorization"] = "Bearer $token";
    return h;
  }

  // Helper: success codes
  bool _isSuccess(int code) => code == 200 || code == 201 || code == 204;
  Future<bool> crearReserva(Map<String, dynamic> datos) async {
  try {
    final url = Uri.parse("$baseUrl/reservas/");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(datos),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  } catch (e) {
    print("[ERROR][CREAR RESERVA] $e");
    return false;
  }
}
  Future<List<dynamic>> listarReservas() async {
    try {
      final url = Uri.parse("$baseUrl/reservas/");
      final h = await _headers(json: false);
      final res = await http.get(url, headers: h);
      
      final data = jsonDecode(res.body);
      if (data is List) return data;
      
      print("[API][listarReservas] Expected List but got: ${data.runtimeType}");
      return [];
    } catch (e) {
      print("[API][listarReservas] Error: $e");
      return [];
    }
  }



  Future<List<dynamic>> listarMisReservas() async {
    try {
      final url = Uri.parse("$baseUrl/reservas/mis/");
      final h = await _headers(json: false);
      final res = await http.get(url, headers: h);
      
      final data = jsonDecode(res.body);
      if (data is List) return data;
      
      print("[API][listarMisReservas] Expected List but got: ${data.runtimeType}");
      return [];
    } catch (e) {
      print("[API][listarMisReservas] Error: $e");
      return [];
    }
  }

  Future<bool> aprobarReservaAntigua(int id) async {
    final url = Uri.parse("$baseUrl/reservas/aprobar/$id");
    final res = await http.post(url);
    return res.statusCode == 200;
  }

  Future<bool> cancelarReserva(int id) async {
    final url = Uri.parse("$baseUrl/reservas/cancelar/$id");
    final res = await http.post(url);
    return res.statusCode == 200;
  }

  /// 📤 Subir PDF de Horario a Supabase (vía backend o directo si es necesario)
  Future<String?> subirHorarioPDF(Uint8List bytes, String fileName) async {
    try {
      final url = Uri.parse("$baseUrl/utils/upload-pdf"); // Endpoint proxy o directo
      final request = http.MultipartRequest('POST', url)
        ..files.add(http.MultipartFile.fromBytes(
          'file', 
          bytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ));
      
      final h = await _headers(json: false);
      request.headers.addAll(h);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['publicUrl']; // La URL pública del archivo en Supabase
      }
      return null;
    } catch (e) {
      print("[ERROR][UPLOAD PDF] $e");
      return null;
    }
  }
  // -------------------- GENERIC LIST / CRUD PATTERN --------------------
  // Para endpoints que devuelven listas (GET) -> devolver List<dynamic> o lanzar excepción
  // Para crear/actualizar/eliminar -> devolver bool según status
  Future<bool> register(String correo, String contrasena, String nombres, String apellidos) async {
  final url = Uri.parse("$baseUrl/registro-admin/");
  final body = jsonEncode({
    "correo": correo,
    "contrasena": contrasena,
    "nombres": nombres,
    "apellidos": apellidos,
    "rol": "admin"
  });

  final response = await http.post(url, headers: {
    "Content-Type": "application/json",
  }, body: body);

  print("[REGISTER] ${response.statusCode} -> ${response.body}");
  return _isSuccess(response.statusCode);
}

  Future<bool> actualizarUsuario(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/usuarios/$id/");
    final headers = await _headers();
    // Intenta PATCH con slash final
    final response = await http.patch(url, headers: headers, body: jsonEncode(datos));
    print("[USUARIO][UPDATE] ${response.statusCode} -> ${response.body}");
    return _isSuccess(response.statusCode);
  }

 // -------------------- SEDES --------------------
Future<List<dynamic>> listarSedes() async {
  final url = Uri.parse("$baseUrl/sedes/");
  final headers = await _headers(json: false);

  final response = await http.get(url, headers: headers);

  print("[SEDES][GET ALL] ${response.statusCode} -> ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Error al listar sedes: ${response.statusCode}");
  }
}

 Future<void> crearSede(Map<String, dynamic> cuerpo) async {
  final url = Uri.parse('$baseUrl/sedes/');
  final headers = await _headers(json: true);

  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(cuerpo),
  );

  print("[SEDES][POST] ${response.statusCode} -> ${response.body}");

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Error al crear sede: ${response.statusCode}");
  }
}

  // -------------------- CARRERAS (multi-sede) --------------------
  Future<List<dynamic>> listarCarreras() async {
    final url = Uri.parse("$baseUrl/carreras/");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[CARRERAS][GET ALL] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception("Error al listar carreras: ${r.statusCode}");
  }

  Future<List<dynamic>> listarCarrerasPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/carreras/sede/$idSede");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[CARRERAS][GET POR SEDE] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception("Error al listar carreras por sede: ${r.statusCode}");
  }

  Future<bool> crearCarrera(Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/carreras/");
    final headers = await _headers();
    final r = await http.post(url, headers: headers, body: jsonEncode(datos));
    print("[CARRERAS][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> actualizarCarrera(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/carreras/$id");
    final headers = await _headers();
    final r = await http.put(url, headers: headers, body: jsonEncode(datos));
    print("[CARRERAS][PUT] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> eliminarCarrera(int id) async {
    final url = Uri.parse("$baseUrl/carreras/$id");
    final headers = await _headers(json: false);
    final r = await http.delete(url, headers: headers);
    print("[CARRERAS][DELETE] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  // -------------------- AULAS --------------------
  Future<List<dynamic>> listarAulas() async {
    final url = Uri.parse("$baseUrl/aulas/");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[AULAS][GET ALL] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception("Error al listar aulas: ${r.statusCode}");
  }

  Future<List<dynamic>> listarAulasPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/aulas/sede/$idSede");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[AULAS][GET POR SEDE] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception("Error al listar aulas por sede: ${r.statusCode}");
  }

  Future<bool> crearAula(Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/aulas/");
    final headers = await _headers();
    final r = await http.post(url, headers: headers, body: jsonEncode(datos));
    print("[AULAS][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> actualizarAula(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/aulas/$id");
    final headers = await _headers();
    final r = await http.put(url, headers: headers, body: jsonEncode(datos));
    print("[AULAS][PUT] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> eliminarAula(int id) async {
    final url = Uri.parse("$baseUrl/aulas/$id");
    final headers = await _headers(json: false);
    final r = await http.delete(url, headers: headers);
    print("[AULAS][DELETE] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  // -------------------- MATERIAS --------------------
  Future<List<dynamic>> listarMateriasPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/materias/sede/$idSede");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[MATERIAS][GET POR SEDE] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception("Error al listar materias por sede: ${r.statusCode}");
  }

  Future<bool> crearMateria(Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/materias/");
    final headers = await _headers();
    final r = await http.post(url, headers: headers, body: jsonEncode(datos));
    print("[MATERIAS][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> actualizarMateria(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/materias/$id");
    final headers = await _headers();
    final r = await http.put(url, headers: headers, body: jsonEncode(datos));
    print("[MATERIAS][PUT] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> eliminarMateria(int id) async {
    final url = Uri.parse("$baseUrl/materias/$id");
    final headers = await _headers(json: false);
    final r = await http.delete(url, headers: headers);
    print("[MATERIAS][DELETE] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  // -------------------- CURSOS --------------------
  Future<List<dynamic>> listarCursosPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/cursos/sede/$idSede");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[CURSOS][GET POR SEDE] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception("Error al listar cursos por sede: ${r.statusCode}");
  }

  Future<bool> crearCurso(Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/cursos/");
    final headers = await _headers();
    final r = await http.post(url, headers: headers, body: jsonEncode(datos));
    print("[CURSOS][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> actualizarCurso(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/cursos/$id");
    final headers = await _headers();
    final r = await http.put(url, headers: headers, body: jsonEncode(datos));
    print("[CURSOS][PUT] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> eliminarCurso(int id) async {
    final url = Uri.parse("$baseUrl/cursos/$id");
    final headers = await _headers(json: false);
    final r = await http.delete(url, headers: headers);
    print("[CURSOS][DELETE] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

// ==============================
//    ESCRITORIOS SERVICE
// ==============================

  Future<List<dynamic>> listarEscritorios() async {
    final url = Uri.parse("$baseUrl/escritorios/");
    final headers = await _headers(json: false);

    final r = await http.get(url, headers: headers);
    print("[ESCRITORIOS][GET ALL] ${r.statusCode} -> ${r.body}");

    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    } else {
      throw Exception("Error al listar escritorios: ${r.statusCode}");
    }
  }

  Future<List<dynamic>> listarEscritoriosPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/escritorios/sede/$idSede");
    final headers = await _headers(json: false);

    final r = await http.get(url, headers: headers);
    print("[ESCRITORIOS][GET POR SEDE] ${r.statusCode} -> ${r.body}");

    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    } else {
      throw Exception("Error al listar escritorios por sede: ${r.statusCode}");
    }
  }

  Future<List<dynamic>> listarEscritoriosPorSala(int idSala) async {
    final url = Uri.parse("$baseUrl/escritorios/sala/$idSala");
    final headers = await _headers(json: false);

    final r = await http.get(url, headers: headers);
    print("[ESCRITORIOS][GET POR SALA] ${r.statusCode} -> ${r.body}");

    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    } else {
      throw Exception("Error al listar escritorios por sala: ${r.statusCode}");
    }
  }

  Future<bool> crearEscritorio(Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/escritorios/");
    final headers = await _headers();

    final r = await http.post(
      url,
      headers: headers,
      body: jsonEncode(datos),
    );

    print("[ESCRITORIOS][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> actualizarEscritorio(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/escritorios/$id");
    final headers = await _headers();

    final r = await http.put(
      url,
      headers: headers,
      body: jsonEncode(datos),
    );

    print("[ESCRITORIOS][PUT] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> eliminarEscritorio(int id) async {
    final url = Uri.parse("$baseUrl/escritorios/$id");
    final headers = await _headers(json: false);

    final r = await http.delete(url, headers: headers);
    print("[ESCRITORIOS][DELETE] ${r.statusCode} -> ${r.body}");

    return _isSuccess(r.statusCode);
  }

  /// ASIGNAR DOCENTE A ESCRITORIO
  Future<bool> asignarDocente(int escritorioId, int docenteId) async {
    final url = Uri.parse("$baseUrl/escritorios/asignar/$escritorioId?docente_id=$docenteId");
    final headers = await _headers(json: false);

    final r = await http.post(url, headers: headers);
    print("[ESCRITORIOS][ASIGNAR DOCENTE] ${r.statusCode} -> ${r.body}");

    return _isSuccess(r.statusCode);
  }
  Future<List<dynamic>> listarDocentes(int idSede) async {
    final url = Uri.parse("$baseUrl/docentes/sede/$idSede");
    final headers = await _headers(json: false);

    final r = await http.get(url, headers: headers);
    print("[DOCENTES][GET POR SEDE] ${r.statusCode} -> ${r.body}");

    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    } else {
      throw Exception("Error al listar docentes: ${r.statusCode}");
    }
  }



// -------------------- DOCENTES --------------------

  Future<List<dynamic>> listarDocentesPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/docentes/sede/$idSede");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[DOCENTES][GET POR SEDE] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) {
      final List<dynamic> data = jsonDecode(r.body);
      return data;
    }
    throw Exception("Error al listar docentes por sede: ${r.statusCode}");
  }

  Future<bool> crearDocente(Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/docentes/");
    final headers = await _headers();
    final r = await http.post(url, headers: headers, body: jsonEncode(datos));
    print("[DOCENTES][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> actualizarDocente(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/docentes/$id");
    final headers = await _headers();
    final r = await http.put(url, headers: headers, body: jsonEncode(datos));
    print("[DOCENTES][PUT] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> eliminarDocente(int id) async {
    final url = Uri.parse("$baseUrl/docentes/$id");
    final headers = await _headers(json: false);
    final r = await http.delete(url, headers: headers);
    print("[DOCENTES][DELETE] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  // ✅ NUEVO: listar docentes que NO tienen cuenta
  Future<List<dynamic>> listarDocentesSinCuenta() async {
    final url = Uri.parse("$baseUrl/usuarios/docentes-sin-cuenta/");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[DOCENTES][SIN CUENTA] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception("Error al listar docentes sin cuenta: ${r.statusCode}");
  }

  // ✅ NUEVO: crear cuenta docente
  Future<bool> crearCuentaDocente(Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/usuarios/docente/");
    final headers = await _headers();
    final r = await http.post(url, headers: headers, body: jsonEncode(datos));
    print("[USUARIO DOCENTE][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  // ✅ NUEVO: actualizar contraseña del docente
  Future<bool> actualizarContrasenaDocente(int docenteId, String nueva) async {
    final url = Uri.parse("$baseUrl/usuarios/reset/$docenteId");
    final headers = await _headers();
    final body = jsonEncode({"nueva_contrasena": nueva});

    final r = await http.put(url, headers: headers, body: body);
    print("[USUARIO][RESET CONTRASEÑA] ${r.statusCode} -> ${r.body}");

    return _isSuccess(r.statusCode);
  }
  Future<List<dynamic>> listarSalasPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/sala-profesores/sede/$idSede");
    final headers = await _headers(json: false);

    final r = await http.get(url, headers: headers);
    print("[SALAS][GET POR SEDE] ${r.statusCode} -> ${r.body}");

    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    } else {
      throw Exception("Error al listar salas por sede: ${r.statusCode}");
    }
  }

  Future<bool> crearSala(Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/sala-profesores/");
    final headers = await _headers();

    final r = await http.post(url, headers: headers, body: jsonEncode(datos));
    print("[SALAS][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> actualizarSala(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/sala-profesores/$id");
    final headers = await _headers();

    final r = await http.put(url, headers: headers, body: jsonEncode(datos));
    print("[SALAS][PUT] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> eliminarSala(int id) async {
    final url = Uri.parse("$baseUrl/sala-profesores/$id");
    final headers = await _headers(json: false);

    final r = await http.delete(url, headers: headers);
    print("[SALAS][DELETE] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }
  // -------------------- MODULOS POR SEDE --------------------
  Future<List<dynamic>> listarModulosPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/modulos-sede/$idSede");
    final headers = await _headers(json: false);
    final r = await http.get(url, headers: headers);
    print("[MODULOS][GET POR SEDE] ${r.statusCode} -> ${r.body}");
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception("Error al listar modulos por sede: ${r.statusCode}");
  }
 // --------------------------------------------------
  // 🧾 HORARIOS - PDF
  // --------------------------------------------------

  /// ✅ Subir PDF (Android / iOS / Desktop usando path)
  Future<bool> subirPdfHorario(String tipo, String filePath) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/pdf/$tipo");

      final request = http.MultipartRequest("POST", url);

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          filePath,
          contentType: MediaType("application", "pdf"),
        ),
      );

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("[ERROR][SUBIR PDF PATH] $e");
      return false;
    }
  }

  /// ✅ Subir PDF (WEB usando bytes)
  Future<bool> subirPdfHorarioWeb(
    String tipo,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/pdf/$tipo");

      final request = http.MultipartRequest("POST", url);

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: fileName,
          contentType: MediaType("application", "pdf"),
        ),
      );

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("[ERROR][SUBIR PDF WEB] $e");
      return false;
    }
  }

  /// ✅ Obtener PDF como bytes (Flutter Web / Mobile)
  Future<Uint8List?> obtenerPdfBytes(String tipo) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/pdf/bytes/$tipo");

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/pdf",
        },
      );

      if (response.statusCode == 200) {
        print("PDF bytes recibidos: ${response.bodyBytes.length}");
        return response.bodyBytes;
      } else {
        print("[ERROR][OBTENER PDF BYTES] ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("[ERROR][OBTENER PDF BYTES] $e");
      return null;
    }
  }
  Future<Map<String, dynamic>?> obtenerMiCroquis(int docenteId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profesor/mi-croquis/$docenteId'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }


  // --------------------------------------------------
  // 🗓️ HORARIOS - CRUD
  // --------------------------------------------------
  Future<bool> crearHorarioAdmin({
    required int docenteId,
    required int cursoId,
    required int materiaId,
    required int aulaId,
    required String dia,
    required String horaInicio,
    required String horaFin,
  }) async {
    final url = Uri.parse('$baseUrl/horario-docente/');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'docente_id': docenteId,
        'curso_id': cursoId,
        'materia_id': materiaId,
        'aula_id': aulaId,
        'dia': dia,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print("Error crear horario: ${response.body}");
      return false;
    }
  }

  Future<List<dynamic>> obtenerHorarioDocente(int docenteId) async {
    final url = Uri.parse('$baseUrl/horario-docente/docente/$docenteId');

    final response = await http.get(
      url,
      headers: await _headers(),
    );

    // print("[DEBUG API] obtenerHorarioDocente($docenteId): Code ${response.statusCode}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener horario del docente");
    }
  }

  /// ✅ Listar horarios docentes por Sede (Optimizado con Fallback)
  Future<List<dynamic>> listarHorariosDocentesPorSede(int sedeId) async {
    // 1. Intentar endpoint masivo (Optimo)
    try {
      final url = Uri.parse('$baseUrl/horario-docente/sede/$sedeId');
      final response = await http.get(url, headers: await _headers());
      // print("[HORARIO DOCENTE][GET POR SEDE] ${response.statusCode}");
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("[API] Error intentando bulk fetch: $e");
    }

    // 2. Fallback: Peticiones por lotes (Batching) para evitar saturación
    print("[API] Bulk fetch no disponible (404/Error). Iniciando carga por lotes...");
    try {
      // a) Obtener lista de docentes
      final docentes = await listarDocentesPorSede(sedeId);
      final List<dynamic> todosLosHorarios = [];
      
      // b) Procesar en lotes de 6 para no saturar conexiones (Chrome suele limitar a 6 por dominio)
      final int batchSize = 6; 
      for (var i = 0; i < docentes.length; i += batchSize) {
        final end = (i + batchSize < docentes.length) ? i + batchSize : docentes.length;
        final batch = docentes.sublist(i, end);
        
        final results = await Future.wait(
          batch.map((d) async {
             try {
               return await obtenerHorarioDocente(d["id"]);
             } catch (e) {
               print("Error cargando horario docente ${d['id']}: $e");
               return [];
             }
          })
        );
        
        for (var list in results) {
          if (list is List) todosLosHorarios.addAll(list);
        }
        // Pequeña pausa para dar respiro al event loop si es necesario
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      print("[API] Carga por lotes completada. Total horarios: ${todosLosHorarios.length}");
      return todosLosHorarios;
      
    } catch (e) {
      print("[API] Error grave en fallback por lotes: $e");
      return [];
    }
  }

  Future<bool> actualizarHorarioDocente(int id, Map<String, dynamic> datos) async {
    try {
      final url = Uri.parse('$baseUrl/horario-docente/$id/');
      final response = await http.patch(
        url,
        headers: await _headers(),
        body: jsonEncode(datos),
      );
      print("[HORARIO DOCENTE][PATCH $id] ${response.statusCode} -> ${response.body}");
      return _isSuccess(response.statusCode);
    } catch (e) {
      print("[ERROR][PUT HORARIO DOCENTE] $e");
      return false;
    }
  }

  Future<bool> eliminarHorarioDocente(int id) async {
    try {
      final url = Uri.parse('$baseUrl/horario-docente/$id');
      final response = await http.delete(
        url,
        headers: await _headers(json: false),
      );
      print("[HORARIO DOCENTE][DELETE $id] ${response.statusCode}");
      return _isSuccess(response.statusCode);
    } catch (e) {
      print("[ERROR][DELETE HORARIO DOCENTE] $e");
      return false;
    }
  }


  /// ✅ Crear horario
  Future<bool> crearHorario(Map<String, dynamic> datos) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(datos),
      );

      print("[HORARIOS][CREAR] ${res.statusCode} -> ${res.body}");
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("[ERROR][CREAR HORARIO] $e");
      return false;
    }
  }

  /// ✅ Listar horarios por sede
  Future<List<dynamic>> listarHorariosPorSede(int sedeId) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/sede/$sedeId");
      final res = await http.get(url);

      print("[HORARIOS][GET POR SEDE] ${res.statusCode}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al listar horarios: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][LISTAR HORARIOS POR SEDE] $e");
      rethrow;
    }
  }

  /// ✅ Listar horarios cancelados
  Future<List<dynamic>> listarHorariosCancelados(
    int sedeId,
    String fecha,
  ) async {
    try {
      final url = Uri.parse(
        "$baseUrl/horarios/cancelados/?sede_id=$sedeId&fecha=$fecha",
      );

      final res = await http.get(url);

      print("[HORARIOS][CANCELADOS] ${res.statusCode}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception(
          "Error al listar horarios cancelados: ${res.statusCode}",
        );
      }
    } catch (e) {
      print("[ERROR][LISTAR CANCELADOS] $e");
      rethrow;
    }
  }

  /// ✅ Obtener horario por ID
  Future<Map<String, dynamic>> obtenerHorario(int id) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/$id");
      final res = await http.get(url);

      print("[HORARIOS][GET ID $id] ${res.statusCode}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener horario: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][OBTENER HORARIO] $e");
      rethrow;
    }
  }

  /// ✅ Actualizar horario
  Future<bool> actualizarHorario(
    int id,
    Map<String, dynamic> datos,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/$id");
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(datos),
      );

      print("[HORARIOS][ACTUALIZAR $id] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][ACTUALIZAR HORARIO] $e");
      return false;
    }
  }

  /// ✅ Eliminar horario
  Future<bool> eliminarHorario(int id) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/$id");
      final res = await http.delete(url);

      print("[HORARIOS][ELIMINAR $id] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][ELIMINAR HORARIO] $e");
      return false;
    }
  }

  /// ✅ Cancelar horario
  Future<bool> cancelarHorario(int id) async {
    try {
      final url = Uri.parse("$baseUrl/horarios/$id/cancelar");
      final res = await http.put(url);

      print("[HORARIOS][CANCELAR $id] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][CANCELAR HORARIO] $e");
      return false;
    }
  }

  // ==========================================
  // RESERVA DE AULAS
  // ==========================================

  /// Obtener aulas disponibles en fecha/hora específica
  Future<List<dynamic>> obtenerAulasDisponibles(
    String fecha,
    String hora,
    int sedeId,
  ) async {
    try {
      final url = Uri.parse(
        "$baseUrl/reserva-aulas/aulas-disponibles?fecha=$fecha&hora=$hora&sede_id=$sedeId",
      );
      final res = await http.get(url);
      
      print("[AULAS DISPONIBLES] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener aulas disponibles: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][AULAS DISPONIBLES] $e");
      rethrow;
    }
  }

  /// Crear nueva reserva
  Future<bool> crearReservaAula(
    String fecha,
    String hora,
    int aulaId,
    int docenteId,
    String motivo,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/reserva-aulas/crear-reserva");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fecha": fecha,
          "hora": hora,
          "aula_id": aulaId,
          "docente_id": docenteId,
          "motivo": motivo,
        }),
      );
      
      print("[CREAR RESERVA AULA] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][CREAR RESERVA AULA] $e");
      return false;
    }
  }

  /// Crear nueva reserva con rango de horas
  Future<bool> crearReservaAulaConRango(
    String fecha,
    String horaInicio,
    String horaFin,
    int aulaId,
    int docenteId,
    String motivo,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/reserva-aulas/crear-reserva");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fecha": fecha,
          "hora_inicio": horaInicio,
          "hora_fin": horaFin,
          "aula_id": aulaId,
          "docente_id": docenteId,
          "motivo": motivo,
        }),
      );
      
      print("[CREAR RESERVA AULA RANGO] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][CREAR RESERVA AULA RANGO] $e");
      return false;
    }
  }

  /// Obtener mis reservas
  Future<List<dynamic>> obtenerMisReservas(int docenteId) async {
    try {
      final url = Uri.parse("$baseUrl/reserva-aulas/mis-reservas/$docenteId");
      final res = await http.get(url);
      
      print("[MIS RESERVAS] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener reservas: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][MIS RESERVAS] $e");
      rethrow;
    }
  }

/// Cancelar reserva
  Future<bool> cancelarReservaAula(int reservaId, int docenteId) async {
    try {
      final url = Uri.parse(
        "$baseUrl/reserva-aulas/cancelar-reserva/$reservaId"
      );

      final res = await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode({
          "docente_id": docenteId,
          "id_docente": docenteId,
        }),
      );
        
      print("[CANCELAR RESERVA] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][CANCELAR RESERVA] $e");
      return false;
    }
  }

  /// ✅ Listar TODAS las reservas de la sede (Aprobadas)
  // Nota: El endpoint '/reservas/' devuelve todas, filtramos por lógica de negocio si es necesario.
  Future<List<dynamic>> listarReservasPorSede(int sedeId) async {
    try {
      final url = Uri.parse("$baseUrl/reservas/");
      final headers = await _headers(json: false);
      final res = await http.get(url, headers: headers);
      
      print("[LISTAR TODAS RESERVAS] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Filtrar por sede si el objeto tiene sede_id, si no, devolvemos todo y que el dashboard filtre por aula
        if (data is List) {
           return data; 
        }
        return [];
      } else {
        print("Error al listar reservas: ${res.statusCode}");
        return [];
      }
    } catch (e) {
      print("[ERROR][LISTAR TODAS RESERVAS] $e");
      return []; 
    }
  }

  /// Obtener reservas pendientes (admin)
  Future<List<dynamic>> obtenerReservasPendientes() async {
    try {
      final url = Uri.parse("$baseUrl/reserva-aulas/reservas-pendientes");
      final res = await http.get(url);
      
      print("[RESERVAS PENDIENTES] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener reservas pendientes: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][RESERVAS PENDIENTES] $e");
      rethrow;
    }
  }

  /// Aprobar reserva (admin)
  Future<bool> aprobarReserva(int reservaId) async {
    try {
      final url = Uri.parse("$baseUrl/reserva-aulas/aprobar-reserva/$reservaId");
      final res = await http.post(url);
      
      print("[APROBAR RESERVA] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][APROBAR RESERVA] $e");
      return false;
    }
  }

  /// Rechazar reserva (admin)
  Future<bool> rechazarReserva(int reservaId) async {
    try {
      final url = Uri.parse("$baseUrl/reserva-aulas/rechazar-reserva/$reservaId");
      final res = await http.post(url);
      
      print("[RECHAZAR RESERVA] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][RECHAZAR RESERVA] $e");
      return false;
    }
  }

  /// Eliminar reserva (admin y docente)
  Future<bool> eliminarReserva(int reservaId) async {
    try {
      // Usaremos el estándar REST: DELETE /reserva-aulas/{id}/
      final url = Uri.parse("$baseUrl/reserva-aulas/$reservaId");
      final headers = await _headers(json: false);
      
      final res = await http.delete(url, headers: headers);
      print("[ELIMINAR RESERVA] ${res.statusCode}");
      
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("[ERROR][ELIMINAR RESERVA] $e");
      return false;
    }
  }

  /// Listar Historial Completo (Admin)
  Future<List<dynamic>> listarHistorialReservas() async {
    try {
      // Endpoint específico que pediremos crear en el backend
      final url = Uri.parse("$baseUrl/reserva-aulas/historial");
      final headers = await _headers(json: false);
      
      final res = await http.get(url, headers: headers);
      print("[HISTORIAL RESERVAS] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      print("[ERROR][HISTORIAL RESERVAS] $e");
      return []; 
    }
  }

  // ==========================================
  // PANEL PROFESOR
  // ==========================================

  /// Obtener materias del profesor
  Future<List<dynamic>> obtenerMisMaterias(int docenteId) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/mis-materias/$docenteId");
      final res = await http.get(url);
      
      print("[MIS MATERIAS] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener materias: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][MIS MATERIAS] $e");
      rethrow;
    }
  }

  /// Obtener horario del profesor
  Future<List<dynamic>> obtenerMiHorario(int docenteId) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/mi-horario/$docenteId");
      final res = await http.get(url);
      
      print("[MI HORARIO] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener horario: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][MI HORARIO] $e");
      rethrow;
    }
  }

  /// Crear horario de clase
  Future<bool> crearHorarioProfesor(
    String fecha,
    String hora,
    int materiaId,
    int aulaId,
    int docenteId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/crear-horario");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fecha": fecha,
          "hora": hora,
          "materia_id": materiaId,
          "aula_id": aulaId,
          "docente_id": docenteId,
        }),
      );
      
      print("[CREAR HORARIO PROFESOR] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][CREAR HORARIO PROFESOR] $e");
      return false;
    }
  }

  /// Actualizar horario
  Future<bool> actualizarHorarioProfesor(
    int horarioId,
    String fecha,
    String hora,
    int materiaId,
    int aulaId,
    int docenteId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/actualizar-horario/$horarioId");
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fecha": fecha,
          "hora": hora,
          "materia_id": materiaId,
          "aula_id": aulaId,
          "docente_id": docenteId,
        }),
      );
      
      print("[ACTUALIZAR HORARIO PROFESOR] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][ACTUALIZAR HORARIO PROFESOR] $e");
      return false;
    }
  }

  /// Eliminar horario
  Future<bool> eliminarHorarioProfesor(int horarioId, int docenteId) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/eliminar-horario/$horarioId");
      final res = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"docente_id": docenteId}),
      );
      
      print("[ELIMINAR HORARIO PROFESOR] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][ELIMINAR HORARIO PROFESOR] $e");
      return false;
    }
  }

  /// Obtener cursos disponibles
  Future<List<dynamic>> obtenerCursosDisponibles(int sedeId) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/cursos-disponibles/$sedeId");
      final res = await http.get(url);
      
      print("[CURSOS DISPONIBLES] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener cursos: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][CURSOS DISPONIBLES] $e");
      rethrow;
    }
  }

  /// Obtener mi escritorio asignado
  Future<Map<String, dynamic>> obtenerMiEscritorio(int docenteId) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/mi-escritorio/$docenteId");
      final res = await http.get(url);
      
      print("[MI ESCRITORIO] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener escritorio: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][MI ESCRITORIO] $e");
      rethrow;
    }
  }

  /// Obtener escritorios disponibles
  Future<List<dynamic>> obtenerEscritoriosDisponibles(int sedeId) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/escritorios-disponibles/$sedeId");
      final res = await http.get(url);
      
      print("[ESCRITORIOS DISPONIBLES] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener escritorios: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][ESCRITORIOS DISPONIBLES] $e");
      rethrow;
    }
  }

  /// Solicitar asignación de escritorio
  Future<bool> solicitarEscritorio(int escritorioId, int docenteId, String motivo) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/solicitar-escritorio");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "escritorio_id": escritorioId,
          "docente_id": docenteId,
          "motivo": motivo,
        }),
      );
      
      print("[SOLICITAR ESCRITORIO] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][SOLICITAR ESCRITORIO] $e");
      return false;
    }
  }

  /// Obtener horario de ocupación de aulas
  Future<List<dynamic>> obtenerHorarioAulas(int sedeId, String fecha) async {
    try {
      final url = Uri.parse("$baseUrl/profesor/horario-aulas?sede_id=$sedeId&fecha=$fecha");
      final res = await http.get(url);
      
      print("[HORARIO AULAS] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al obtener horario de aulas: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][HORARIO AULAS] $e");
      rethrow;
    }
  }


  // ==========================================
  // PDF HORARIOS
  // ==========================================

  /// Listar PDFs de horarios por sede
  Future<List<dynamic>> listarPdfHorarios(int sedeId) async {
    try {
      final url = Uri.parse("$baseUrl/pdf-horarios/listar/$sedeId");
      final headers = await _headers(json: false);
      final res = await http.get(url, headers: headers);
      
      print("[PDF HORARIOS][LISTAR] ${res.statusCode}");
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Error al listar PDFs: ${res.statusCode}");
      }
    } catch (e) {
      print("[ERROR][LISTAR PDF HORARIOS] $e");
      rethrow;
    }
  }

  /// Obtener PDF de horario como bytes
  Future<Uint8List?> obtenerPdfHorario(int sedeId, String tipo) async {
    try {
      final url = Uri.parse("$baseUrl/pdf-horarios/ver/$sedeId/$tipo");
      final headers = await _headers(json: false);
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        print("PDF horario recibido: ${response.bodyBytes.length} bytes");
        return response.bodyBytes;
      } else {
        print("[ERROR][OBTENER PDF HORARIO] ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("[ERROR][OBTENER PDF HORARIO] $e");
      return null;
    }
  }

  /// Eliminar PDF de horario
  Future<bool> eliminarPdfHorario(int sedeId, String tipo) async {
    try {
      final url = Uri.parse("$baseUrl/pdf-horarios/eliminar/$sedeId/$tipo");
      final headers = await _headers(json: false);
      final res = await http.delete(url, headers: headers);
      
      print("[ELIMINAR PDF HORARIO] ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      print("[ERROR][ELIMINAR PDF HORARIO] $e");
      return false;
    }
  }

  /// Subir PDF de horario con 4 parámetros
  Future<bool> subirPdfHorarioCompleto(int sedeId, String tipo, Uint8List bytes, String fileName) async {
    try {
      final url = Uri.parse("$baseUrl/pdf-horarios/subir/$sedeId/$tipo");
      final request = http.MultipartRequest("POST", url);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );
      
      final response = await request.send();
      print("[SUBIR PDF HORARIO] ${response.statusCode}");
      
      return response.statusCode == 200;
    } catch (e) {
      print("[ERROR][SUBIR PDF HORARIO] $e");
      return false;
    }
  }

  // ==========================================
  // CROQUIS
  // ==========================================

  /// Subir croquis de aula (solo admin)
  Future<bool> subirCroquisAula(int aulaId, String filePath) async {
    try {
      final url = Uri.parse("$baseUrl/croquis/aula/$aulaId/croquis");
      final request = http.MultipartRequest("POST", url);
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send();
      print("[SUBIR CROQUIS AULA] ${response.statusCode}");
      
      return response.statusCode == 200;
    } catch (e) {
      print("[ERROR][SUBIR CROQUIS AULA] $e");
      return false;
    }
  }

  /// Subir croquis de sala (solo admin)
  Future<bool> subirCroquisSala(int salaId, String filePath) async {
    try {
      final url = Uri.parse("$baseUrl/croquis/sala/$salaId/croquis");
      final request = http.MultipartRequest("POST", url);
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send();
      print("[SUBIR CROQUIS SALA] ${response.statusCode}");
      
      return response.statusCode == 200;
    } catch (e) {
      print("[ERROR][SUBIR CROQUIS SALA] $e");
      return false;
    }
  }

  /// Obtener croquis de aula
  Future<String?> obtenerCroquisAula(int aulaId) async {
    try {
      final url = Uri.parse("$baseUrl/croquis/aula/$aulaId/croquis");
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['croquis_url'];
      }
      return null;
    } catch (e) {
      print("[ERROR][OBTENER CROQUIS AULA] $e");
      return null;
    }
  }

  /// Obtener croquis de sala
  Future<String?> obtenerCroquisSala(int salaId) async {
    try {
      final url = Uri.parse("$baseUrl/croquis/sala/$salaId/croquis");
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['croquis_url'];
      }
      return null;
    } catch (e) {
      print("[ERROR][OBTENER CROQUIS SALA] $e");
      return null;
    }
  }

  /// Subir croquis de sala para Flutter Web usando bytes
  Future<bool> subirCroquisSalaWeb(int salaId, Uint8List bytes, String fileName) async {
    try {
      final url = Uri.parse("$baseUrl/croquis/sala/$salaId/croquis");
      final request = http.MultipartRequest("POST", url);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType('image', fileName.split('.').last),
        ),
      );
      
      final response = await request.send();
      print("[SUBIR CROQUIS SALA WEB] ${response.statusCode}");
      
      return response.statusCode == 200;
    } catch (e) {
      print("[ERROR][SUBIR CROQUIS SALA WEB] $e");
      return false;
    }
  }

  /// 🔹 LISTAR PLAZAS POR SEDE
  Future<List<dynamic>> listarPlazasPorSede(int sedeId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/plazas/sede/$sedeId'),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Error al listar plazas');
    }
  }

  /// 🔹 SUBIR CROQUIS PLAZA
  Future<bool> subirCroquisPlazaWeb(
    int plazaId,
    List<int> bytes,
    String filename,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/plazas/$plazaId/croquis'),
    );

    request.headers.addAll(await _headers(json: false));
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final response = await request.send();
    return response.statusCode == 200;
  }

  /// 🔹 OBTENER CROQUIS PLAZA
  Future<String?> obtenerCroquisPlaza(int plazaId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/plazas/$plazaId/croquis'),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['croquis_url'];
    }
    return null;
  } 
  /// 🔹 CREAR PLAZA
  Future<bool> crearPlaza(String nombre, int sedeId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/plazas/'),
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'sede_id': sedeId,
      }),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// 🔹 EDITAR PLAZA (CORREGIDO)
  Future<bool> editarPlaza(
    int plazaId,
    String nombre,
    int sedeId,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/plazas/$plazaId'),
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'sede_id': sedeId, // ✅ OBLIGATORIO
      }),
    );

    return res.statusCode == 200;
  }


  /// 🔹 ELIMINAR PLAZA
  Future<bool> eliminarPlaza(int plazaId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/plazas/$plazaId'),
      headers: await _headers(),
    );

    return res.statusCode == 200;
  }
  Future<List<String>> obtenerCroquisDocente(int docenteId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/docentes/$docenteId/croquis'),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((e) => e['croquis_url'] as String).toList();
    } else {
      throw Exception('Error al obtener croquis');
    }
  }

// ==============================
// PUBLIC STORAGE ACCESS (WEB + MOBILE)
// ==============================

Future<String?> readStorage(String key) async {
  return await _storageRead(key: key);
}

Future<void> writeStorage(String key, String value) async {
  await _storageWrite(key: key, value: value);
}

Future<void> clearStorage() async {
  await _storageDeleteAll();
}

}