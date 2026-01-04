import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/mouse_tracker_fix.dart';
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
  final _confirmPasswordController = TextEditingController();
  final _codigoController = TextEditingController();
  final _apiService = ApiService();
  bool cargando = false;
  bool codigoEnviado = false;
  String? error;
  String? mensaje;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _solicitarCodigo() async {
    final emailInput = _correoController.text;
    
    if (emailInput.contains(" ")) {
      setState(() => error = "El correo no debe contener espacios");
      return;
    }

    if (emailInput.trim().isEmpty || _nombresController.text.trim().isEmpty) {
      setState(() => error = "Email y nombres son requeridos");
      return;
    }

    if (_contrasenaController.text.trim().isEmpty) { 
       setState(() => error = "La contraseña es requerida");
       return;
    }

    // Password validation
    if (_contrasenaController.text != _confirmPasswordController.text) {
       setState(() => error = "Las contraseñas no coinciden");
       return;
    }
    if (_contrasenaController.text.length < 6) {
       setState(() => error = "La contraseña debe tener al menos 6 caracteres");
       return;
    }

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final url = Uri.parse("${_apiService.baseUrl}/solicitar-codigo-admin/?email=${Uri.encodeComponent(_correoController.text.trim())}&nombres=${Uri.encodeComponent(_nombresController.text.trim())}");
      print("DEBUG [REGISTRO]: Solicitando código a $url");
      final response = await http.post(url).timeout(const Duration(seconds: 90));

      setState(() => cargando = false);

      if (response.statusCode == 200) {
        setState(() {
          codigoEnviado = true;
          mensaje = "Solicitud enviada. Los administradores recibirán un código de autorización. Contáctalos para obtenerlo.";
        });
      } else {
        String msg = "Error al enviar código. Intenta nuevamente.";
        try {
          final data = jsonDecode(response.body);
          if (data["detail"] != null) msg = data["detail"];
        } catch(_) {}
        setState(() => error = msg);
      }
    } catch (e) {
      print("DEBUG [REGISTRO ERROR]: $e");
      String errorMsg = "Error de conexión. Intenta nuevamente.";
      if (e.toString().contains("Timeout") || e.toString().contains("timed out")) {
        errorMsg = "El servidor está despertando (Cold Start). Esto puede tardar hasta 1-2 minutos la primera vez. Por favor, espera un momento y presiona 'Continuar' de nuevo.";
      }
      setState(() {
        cargando = false;
        error = errorMsg;
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
      final response = await http.post(url).timeout(const Duration(seconds: 90));

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
      print("DEBUG [REGISTRO ERROR]: $e");
      String errorMsg = "Error de conexión. Intenta nuevamente.";
      if (e.toString().contains("Timeout") || e.toString().contains("timed out")) {
        errorMsg = "El servidor está despertando. Por favor reintenta en unos segundos.";
      }
      setState(() {
        cargando = false;
        error = errorMsg;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb && width >= 800) {
      return _buildWebRegister(context);
    }
    return _buildMobileRegister(context);
  }

  Widget _buildWebRegister(BuildContext context) {
    return MouseTrackerFix(
      child: Scaffold(
        body: Row(
          children: [
          // Left Panel: Branding
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0C2461), // Darker Deep Blue
                    Color(0xFF1E3A8A), // Brand Blue
                    Color(0xFF4A69BD), // Lighter "Premium" Blue
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_rounded, size: 80, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 24),
                    const Text(
                      "Yavirac",
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 4,
                      width: 60,
                      color: const Color(0xFFFF6B35),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Sistema de Gestión Académica",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right Panel: Form
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _buildFormContent(),
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

  Widget _buildMobileRegister(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Handle via Stack background
      body: Stack(
        children: [
          // Global Gradient Background using Container
          Container(
             decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0C2461), 
                    Color(0xFF1E3A8A), 
                    Color(0xFF4A69BD), 
                  ],
                ),
             ),
          ),
          // Header Branding
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
             padding: const EdgeInsets.only(left: 24, right: 24, top: 48),
             alignment: Alignment.topCenter,
             child: Column(
               children: [
                  Icon(Icons.school_rounded, size: 48, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(height: 16),
                  const Text(
                    "Yavirac",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Gestión Académica",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
               ],
             ),
            ),
          ),
          
          // Form Sheet
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: _buildFormContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          !codigoEnviado ? "Crear una cuenta" : "Verificar Email",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          !codigoEnviado 
             ? "Ingresa tus datos para registrarte como administrador." 
             : "Ingresa el código que hemos enviado a tu administrador.",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: !codigoEnviado ? _buildStep1() : _buildStep2(),
        ),

        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("¿Ya tienes cuenta? ", style: TextStyle(color: Colors.grey[600])),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
              child: const Text(
                "Inicia sesión",
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
           children: [
             Expanded(child: _buildInput(controller: _nombresController, label: "Nombres", icon: Icons.person_outline)),
             const SizedBox(width: 16),
             Expanded(child: _buildInput(controller: _apellidosController, label: "Apellidos", icon: Icons.person_outlined)),
           ]
        ),
        const SizedBox(height: 16),
        _buildInput(controller: _correoController, label: "Correo Institucional", icon: Icons.email_outlined, type: TextInputType.emailAddress),
        const SizedBox(height: 16),
        
        _buildInput(
          controller: _contrasenaController, 
          label: "Contraseña", 
          icon: Icons.lock_outline, 
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        
        const SizedBox(height: 16),

        _buildInput(
          controller: _confirmPasswordController, 
          label: "Confirmar contraseña", 
          icon: Icons.lock_outline, 
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        
        const SizedBox(height: 16),
        if (error != null) _buildErrorBanner(),
        const SizedBox(height: 8),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: cargando ? null : _solicitarCodigo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: cargando 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Continuar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50], 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(mensaje ?? "Código enviado.", style: TextStyle(color: Colors.green[800], fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInput(controller: _codigoController, label: "Código de Verificación", icon: Icons.security, type: TextInputType.number),
        
        const SizedBox(height: 24),
        if (error != null) _buildErrorBanner(),
        const SizedBox(height: 8),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: cargando ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: cargando 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Registrarme", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
               setState(() {
                 codigoEnviado = false;
                 mensaje = null;
                 error = null;
               });
            },
            child: const Text("Volver atrás"),
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false, 
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? type
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: type,
          enabled: !cargando,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: "Ingresa tu $label",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[400]),
                  onPressed: onToggleVisibility,
                )
              : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Text(error!, style: TextStyle(color: Colors.red[800], fontSize: 13), textAlign: TextAlign.center),
    );
  }
}
