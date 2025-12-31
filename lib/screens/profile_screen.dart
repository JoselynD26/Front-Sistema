import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../utils/mouse_tracker_fix.dart';
import '../widgets/web_layout.dart';
import '../screens/sede_screen.dart';
import 'profesor_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Controllers
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Optional

  String _rol = "Cargando...";
  int? _userId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final names = await _storage.read(key: "nombres") ?? "";
    final lastNames = await _storage.read(key: "apellidos") ?? "";
    final email = await _storage.read(key: "email") ?? "";
    final rol = await _storage.read(key: "rol") ?? "Sin rol";
    final userIdStr = await _storage.read(key: "usuario_id");

    setState(() {
      _nombresController.text = names;
      _apellidosController.text = lastNames;
      _emailController.text = email;
      _rol = rol.toUpperCase();
      _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
      _isLoading = false;
    });
  }

  Future<void> _guardarCambios() async {
    if (_userId == null) return;

    setState(() => _isSaving = true);

    final data = {
      "nombres": _nombresController.text.trim(),
      "apellidos": _apellidosController.text.trim(),
      "correo": _emailController.text.trim(),
      // Add password only if user typed something
      if (_passwordController.text.isNotEmpty) "contrasena": _passwordController.text,
    };

    final exito = await _api.actualizarUsuario(_userId!, data);

    if (exito) {
      // Update local storage
      await _storage.write(key: "nombres", value: data["nombres"]);
      await _storage.write(key: "apellidos", value: data["apellidos"]);
      await _storage.write(key: "email", value: data["correo"]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado correctamente"), backgroundColor: Colors.green),
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _passwordController.clear();
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar perfil"), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MouseTrackerFix(
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Slate 100
        body: Stack(
        children: [
          // 🔹 1. HERO HEADER (GRADIENT BACKGROUND)
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0F172A), Colors.blue.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔹 2. DECORATIVE ELEMENTS
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // 🔹 3. MAIN CONTENT (Moved behind the button in code, but button needs to be on TOP visually -> Button last in list)
          // Wait, 'Main Content' goes first if we want button on top.
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 140, 20, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // PROFILE AVATAR
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade700,
                        child: Text(
                          _nombresController.text.isNotEmpty ? _nombresController.text[0].toUpperCase() : "A",
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CARD
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            // HEADER TEXT
                            Text(
                              "${_nombresController.text} ${_apellidosController.text}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Text(
                                _rol.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 32),

                            // ACTIONS ROW
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_isEditing) ...[
                                  TextButton(
                                    onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                                    child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _guardarCambios,
                                    icon: _isSaving
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.check_rounded, size: 18),
                                    label: Text(_isSaving ? "Guardando..." : "Guardar Cambios"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ] else
                                  TextButton.icon(
                                    onPressed: () => setState(() => _isEditing = true),
                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                    label: const Text("Editar Perfil"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.indigo.shade600,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // FORM FIELDS
                            _buildTextField("Nombres", _nombresController, Icons.person_rounded),
                            const SizedBox(height: 20),
                            _buildTextField("Apellidos", _apellidosController, Icons.person_outline_rounded),
                            const SizedBox(height: 20),
                            _buildTextField("Correo Electrónico", _emailController, Icons.email_rounded),
                            const SizedBox(height: 20),
                            if (_isEditing) ...[
                              _buildTextField("Nueva Contraseña", _passwordController, Icons.lock_rounded, isPassword: true),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Déjalo en blanco si no deseas cambiar tu contraseña.",
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              _buildStaticField("Rol de Usuario", _rol, Icons.security_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "© 2024 Gestión Académica",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔹 4. BACK BUTTON (Moved to LAST to be clickable on top)
          Positioned(
            top: 40,
            left: 20,
            child: SafeArea(
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final isDocente = _rol.toLowerCase() == 'docente' || _rol.toLowerCase() == 'profesor';
                  final dIdStr = await _storage.read(key: "docente_id");
                  final n = await _storage.read(key: "nombres") ?? "Profesor";
                  final a = await _storage.read(key: "apellidos") ?? "";
                  
                  if (!mounted) return;

                  if (isDocente) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => ProfesorDashboard(
                          docenteId: dIdStr != null ? int.parse(dIdStr) : 0,
                          nombreProfesor: "$n $a",
                        ),
                      ),
                      (route) => false,
                    );
                  } else {
                    // Redirigir a Selección de Sede con el título correcto
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const SedeScreen()
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.indigo),
                label: const Text("Volver al Dashboard", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white,
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    if (!_isEditing) {
      if (isPassword) return const SizedBox.shrink(); // Hide password field in view mode
      return _buildStaticField(label, controller.text, icon);
    }

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildStaticField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
