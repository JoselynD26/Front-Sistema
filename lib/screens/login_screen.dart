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
    final emailInput = _correoController.text;
    if (emailInput.contains(" ")) {
      safeSetState(() {
        error = "El correo no debe contener espacios";
      });
      return;
    }

    safeSetState(() {
      cargando = true;
      error = null;
    });

    final success = await _apiService.login(
      emailInput.trim(),
      _contrasenaController.text.trim(),
    );

    safeSetState(() {
      cargando = false;
    });

    if (success) {
      final rol = await _apiService.readStorage("rol");
      final nombres = await _apiService.readStorage("nombres");
      final apellidos = await _apiService.readStorage("apellidos");
      final docenteId = await _apiService.readStorage("docente_id");
      final email = await _apiService.readStorage("email");
      
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
    final width = MediaQuery.of(context).size.width;
    // Show Desktop layout only on Web with sufficient width
    if (kIsWeb && width >= 800) {
      return _buildWebLogin(context);
    }
    // Mobile layout for mobile devices OR small web screens
    return _buildMobileLogin(context);
  }

  Widget _buildWebLogin(BuildContext context) {
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
                      Container(height: 4, width: 60, color: const Color(0xFFFF6B35)), // Orange Accent
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
                      constraints: const BoxConstraints(maxWidth: 400),
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

  Widget _buildMobileLogin(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
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
        const Text(
          "Bienvenido",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Ingresa tus credenciales para acceder.",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        // Email
        _buildInput(
          controller: _correoController,
          label: "Correo Electrónico",
          icon: Icons.email_outlined,
          type: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),

        // Password
        _buildInput(
          controller: _contrasenaController,
          label: "Contraseña",
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        
        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _mostrarDialogoRecuperacion(context),
            child: const Text(
              "¿Olvidaste tu contraseña?",
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        
        // Checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _recordarCredenciales,
                activeColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (value) {
                  setState(() {
                    _recordarCredenciales = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Text("Recordar credenciales", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ],
        ),

        const SizedBox(height: 32),

        if (error != null)
           Container(
             padding: const EdgeInsets.all(12),
             margin: const EdgeInsets.only(bottom: 16),
             decoration: BoxDecoration(
               color: Colors.red[50],
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.red[100]!),
             ),
             child: Text(error!, style: TextStyle(color: Colors.red[800], fontSize: 13), textAlign: TextAlign.center),
           ),

        // Login Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: cargando ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35), // Orange Action
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: cargando 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Ingresar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 32),
        
        // Footer: Register link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("¿No tienes cuenta? ", style: TextStyle(color: Colors.grey[600])),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              ),
              child: const Text(
                "Regístrate aquí",
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        Text(
          "Desarrollado por Joselyn Dicao y María Ortiz",
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          textAlign: TextAlign.center,
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
    TextInputType? type,
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
          onSubmitted: (_) => _login(),
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

  void _mostrarDialogoRecuperacion(BuildContext context) {
    final _correoController = TextEditingController();
    bool enviando = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              backgroundColor: const Color(0xffEEEEEE), // Slightly grey to contrast with white cards
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with Gradient
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                        gradient: LinearGradient(
                          colors: [Color(0xFF0C2461), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Recuperar Acceso",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            "Ingresa tu correo electrónico institucional para recibir una contraseña temporal.",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Styled Input
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50], 
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset:const Offset(0,2))
                              ]
                            ),
                            child: TextField(
                              controller: _correoController,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: "ejemplo@yavirac.edu.ec",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1E3A8A)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                filled: true,
                                fillColor: Colors.transparent, 
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    foregroundColor: Colors.grey[600],
                                  ),
                                  child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: enviando ? null : () async {
                                    if (_correoController.text.isEmpty || !_correoController.text.contains("@")) {
                                       // Simple verification
                                       return; 
                                    }
                                    setStateDialog(() => enviando = true);
                                    final success = await _apiService.solicitarRecuperacion(_correoController.text.trim());
                                    setStateDialog(() => enviando = false);
                                    
                                    if (mounted) {
                                      Navigator.pop(dialogContext); // Close dialog
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(children: const [
                                              Icon(Icons.check_circle_rounded, color: Colors.white), 
                                              SizedBox(width: 8), 
                                              Text("Correo enviado con éxito")
                                            ]),
                                            backgroundColor: Colors.green[700],
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          )
                                        );
                                      } else {
                                         ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(children: const [
                                              Icon(Icons.error_outline_rounded, color: Colors.white), 
                                              SizedBox(width: 8), 
                                              Text("No se encontró el usuario")
                                            ]),
                                            backgroundColor: Colors.red[700],
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          )
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: enviando 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text("Enviar Instrucciones", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
