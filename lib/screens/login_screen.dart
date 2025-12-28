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
      final email = await _apiService.storage.read(key: "email");
      
      debugPrint("LOGIN_SCREEN: Just logged in!");
      debugPrint(" - Rol: $rol");
      debugPrint(" - Nombres: $nombres");
      debugPrint(" - Apellidos: $apellidos");
      debugPrint(" - Email: $email");
      debugPrint(" - DocenteId: $docenteId");
      
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
        body: Row(
          children: [
            // Left Panel - Branding
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -50,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'YAVIRAC',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sistema de Gestión Académica',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right Panel - Login Form
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenido de nuevo',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa tus credenciales para acceder',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 48),
                        TextField(
                          controller: _correoController,
                          decoration: const InputDecoration(
                            labelText: "Correo electrónico",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _contrasenaController,
                          decoration: InputDecoration(
                            labelText: "Contraseña",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                              activeColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (value) {
                                safeSetState(() {
                                  _recordarCredenciales = value ?? false;
                                });
                              },
                            ),
                            const Text("Recordar credenciales"),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[100]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    error!,
                                    style: const TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: cargando ? null : _login,
                            child: cargando
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
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
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterScreen()),
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: "¿No tienes cuenta? ",
                                style: TextStyle(color: Colors.grey[600]),
                                children: [
                                  TextSpan(
                                    text: "Regístrate aquí",
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Text(
                            "Desarrollado por Joselyn Dicao, María Ortiz y Raul Hidalgo",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
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
          ],
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
