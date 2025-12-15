// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Ajusta si usas otra IP en tu red (emulador vs dispositivo físico)
  final String baseUrl = "http://127.0.0.1:8000";
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // -------------------- AUTH --------------------
  Future<bool> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/login/");
    final body = jsonEncode({"correo": username, "contrasena": password});

    final response = await http.post(url, headers: {
      "Content-Type": "application/json",
    }, body: body);

    print("[LOGIN] ${response.statusCode} -> ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["access_token"];
      if (token != null) {
        await storage.write(key: "jwt", value: token);
        if (data.containsKey("rol")) {
          await storage.write(key: "rol", value: data["rol"].toString());
        }
        if (data.containsKey("id")) {
          await storage.write(key: "usuario_id", value: data["id"].toString());
        }
        if (data.containsKey("nombres")) {
          await storage.write(key: "nombres", value: data["nombres"].toString());
        }
        if (data.containsKey("apellidos")) {
          await storage.write(key: "apellidos", value: data["apellidos"].toString());
        }
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await storage.read(key: "jwt");
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
    final url = Uri.parse("$baseUrl/reservas/");
    final res = await http.get(url);
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> listarMisReservas() async {
    final url = Uri.parse("$baseUrl/reservas/mis/");
    final res = await http.get(url);
    return jsonDecode(res.body);
  }

  Future<bool> aprobarReserva(int id) async {
    final url = Uri.parse("$baseUrl/reservas/aprobar/$id");
    final res = await http.post(url);
    return res.statusCode == 200;
  }

  Future<bool> cancelarReserva(int id) async {
    final url = Uri.parse("$baseUrl/reservas/cancelar/$id");
    final res = await http.post(url);
    return res.statusCode == 200;
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
    if (r.statusCode == 200) return jsonDecode(r.body);
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
    final body = jsonEncode({"nueva": nueva});

    final r = await http.put(url, headers: headers, body: body);
    print("[USUARIO][RESET CONTRASEÑA] ${r.statusCode} -> ${r.body}");

    return _isSuccess(r.statusCode);
  }
  Future<List<dynamic>> listarSalasPorSede(int idSede) async {
    final url = Uri.parse("$baseUrl/salas/sede/$idSede");
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
    final url = Uri.parse("$baseUrl/salas/");
    final headers = await _headers();

    final r = await http.post(url, headers: headers, body: jsonEncode(datos));
    print("[SALAS][POST] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> actualizarSala(int id, Map<String, dynamic> datos) async {
    final url = Uri.parse("$baseUrl/salas/$id");
    final headers = await _headers();

    final r = await http.put(url, headers: headers, body: jsonEncode(datos));
    print("[SALAS][PUT] ${r.statusCode} -> ${r.body}");
    return _isSuccess(r.statusCode);
  }

  Future<bool> eliminarSala(int id) async {
    final url = Uri.parse("$baseUrl/salas/$id");
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

  // --------------------------------------------------
  // 🗓️ HORARIOS - CRUD
  // --------------------------------------------------

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
}  
