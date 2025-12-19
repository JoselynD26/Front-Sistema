import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/mouse_tracker_fix.dart';
import 'sede_screen.dart';
import 'register_screen.dart';
import 'profesor_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SafeStateMixin {
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _apiService = ApiService();
  bool cargando = false;
  String? error;
  bool _obscurePassword = true;
  bool _recordarCredenciales = false;

  Future<void> _login() async {
    safeSetState(() {
      cargando = true;
      error = null;
    });

    final success = await _apiService.login(
      _correoController.text.trim(),
      _contrasenaController.text.trim(),
    );

    safeSetState(() {
      cargando = false;
    });

    if (success) {
      final rol = await _apiService.storage.read(key: "rol");
      final nombres = await _apiService.storage.read(key: "nombres");
      final apellidos = await _apiService.storage.read(key: "apellidos");
      final docenteId = await _apiService.storage.read(key: "docente_id");
      
      print("DEBUG - Rol: $rol, Nombres: $nombres, Apellidos: $apellidos, DocenteId: $docenteId");
      
      if (rol == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SedeScreen()),
        );
      } else if (rol == "docente") {
        final nombreCompleto = (nombres != null && apellidos != null) 
            ? "$nombres $apellidos" 
            : "Profesor";
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfesorDashboard(
              docenteId: int.parse(docenteId ?? "0"),
              nombreProfesor: nombreCompleto,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SedeScreen()),
        );
      }
    } else {
      safeSetState(() {
        error = "Credenciales inválidas. Intenta nuevamente.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebLogin(context);
    }
    return _buildMobileLogin(context);
  }

  Widget _buildWebLogin(BuildContext context) {
    return MouseTrackerFix(
      child: Scaffold(
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
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.school,
                        size: 64,
                        color: Color(0xFF1E3A8A),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'YAVIRAC\nSistema de Gestión\nAcadémica',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _correoController,
                        decoration: const InputDecoration(
                          labelText: "Correo electrónico",
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contrasenaController,
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              safeSetState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _recordarCredenciales,
                            onChanged: (value) {
                              safeSetState(() {
                                _recordarCredenciales = value ?? false;
                              });
                            },
                          ),
                          const Text("Recordar credenciales"),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: cargando ? null : _login,
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
                                  "Iniciar Sesión",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        ),
                        child: const Text("¿No tienes cuenta? Regístrate aquí"),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Desarrolladoras: Joselyn Dicao y María Ortiz\nColaborador: Raul Hidalgo",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLogin(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: "Correo",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contrasenaController,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      safeSetState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _recordarCredenciales,
                    onChanged: (value) {
                      safeSetState(() {
                        _recordarCredenciales = value ?? false;
                      });
                    },
                  ),
                  const Text("Recordar credenciales"),
                ],
              ),
              const SizedBox(height: 20),
              if (cargando) const CircularProgressIndicator(),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: cargando ? null : _login,
                child: const Text("Ingresar"),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                ),
                child: const Text("¿No tienes cuenta? Regístrate"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
