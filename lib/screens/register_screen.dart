import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _codigoController = TextEditingController();
  final _apiService = ApiService();
  bool cargando = false;
  bool codigoEnviado = false;
  String? error;
  String? mensaje;

  Future<void> _solicitarCodigo() async {
    if (_correoController.text.trim().isEmpty || _nombresController.text.trim().isEmpty) {
      setState(() => error = "Email y nombres son requeridos");
      return;
    }

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final url = Uri.parse("${_apiService.baseUrl}/solicitar-codigo-admin/?email=${Uri.encodeComponent(_correoController.text.trim())}&nombres=${Uri.encodeComponent(_nombresController.text.trim())}");
      final response = await http.post(url);

      setState(() => cargando = false);

      if (response.statusCode == 200) {
        setState(() {
          codigoEnviado = true;
          mensaje = "Solicitud enviada. Los administradores recibirán un código de autorización. Contáctalos para obtenerlo.";
        });
      } else {
        setState(() => error = "Error al enviar código. Intenta nuevamente.");
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = "Error de conexión. Intenta nuevamente.";
      });
    }
  }

  Future<void> _register() async {
    if (_nombresController.text.trim().isEmpty ||
        _apellidosController.text.trim().isEmpty ||
        _correoController.text.trim().isEmpty ||
        _contrasenaController.text.trim().isEmpty ||
        _codigoController.text.trim().isEmpty) {
      setState(() => error = "Todos los campos son requeridos");
      return;
    }

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final url = Uri.parse("${_apiService.baseUrl}/registro-admin/?correo=${Uri.encodeComponent(_correoController.text.trim())}&contrasena=${Uri.encodeComponent(_contrasenaController.text.trim())}&nombres=${Uri.encodeComponent(_nombresController.text.trim())}&apellidos=${Uri.encodeComponent(_apellidosController.text.trim())}&codigo_verificacion=${Uri.encodeComponent(_codigoController.text.trim())}");
      final response = await http.post(url);

      setState(() => cargando = false);

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuenta de administrador creada exitosamente")),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() => error = data["detail"] ?? "Error al registrar administrador");
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = "Error de conexión. Intenta nuevamente.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebRegister(context);
    }
    return _buildMobileRegister(context);
  }

  Widget _buildWebRegister(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFFFF6B35)],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.all(32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 64,
                      color: Color(0xFF1E3A8A),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sistema de gestión Yavirac\nRegistro de\nAdministrador',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Requiere autorización de un administrador',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nombresController,
                      decoration: const InputDecoration(
                        labelText: "Nombres",
                        prefixIcon: Icon(Icons.person),
                      ),
                      enabled: !codigoEnviado,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apellidosController,
                      decoration: const InputDecoration(
                        labelText: "Apellidos",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      enabled: !codigoEnviado,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _correoController,
                      decoration: const InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !codigoEnviado,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contrasenaController,
                      decoration: const InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    if (!codigoEnviado) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: cargando ? null : _solicitarCodigo,
                          child: cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Solicitar Código",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: "Código de autorización",
                          prefixIcon: Icon(Icons.verified_user),
                          hintText: "Código proporcionado por un administrador",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: cargando ? null : _register,
                          child: cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Crear Cuenta",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            codigoEnviado = false;
                            _codigoController.clear();
                            mensaje = null;
                            error = null;
                          });
                        },
                        child: const Text("Solicitar nuevo código"),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (mensaje != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mensaje!,
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      ),
                      child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileRegister(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Administrador")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nombresController,
                decoration: const InputDecoration(
                  labelText: "Nombres",
                  border: OutlineInputBorder(),
                ),
                enabled: !codigoEnviado,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apellidosController,
                decoration: const InputDecoration(
                  labelText: "Apellidos",
                  border: OutlineInputBorder(),
                ),
                enabled: !codigoEnviado,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: "Correo",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !codigoEnviado,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contrasenaController,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (!codigoEnviado) ...[
                ElevatedButton(
                  onPressed: cargando ? null : _solicitarCodigo,
                  child: Text(cargando ? "Enviando..." : "Solicitar Código"),
                ),
              ] else ...[
                TextField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: "Código de autorización",
                    border: OutlineInputBorder(),
                    hintText: "Código proporcionado por un administrador",
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: cargando ? null : _register,
                  child: Text(cargando ? "Registrando..." : "Registrar"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      codigoEnviado = false;
                      _codigoController.clear();
                      mensaje = null;
                      error = null;
                    });
                  },
                  child: const Text("Solicitar nuevo código"),
                ),
              ],
              const SizedBox(height: 20),
              if (mensaje != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(mensaje!, style: const TextStyle(color: Colors.green)),
                ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                ),
                child: const Text("¿Ya tienes cuenta? Inicia sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}