
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
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
        
        // Reload WebLayout via navigation or let generic rebuild handle it
        // A simple way is to push replacement to self or dashboard logic
        // But since we are inside WebLayout usually, we might just update state.
        // For now, simpler to stay on screen.
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final isDocente = _rol.toLowerCase() == 'docente' || _rol.toLowerCase() == 'profesor';
                  final dIdStr = await _storage.read(key: "docente_id");
                  final n = await _storage.read(key: "nombres") ?? "Profesor";
                  final a = await _storage.read(key: "apellidos") ?? "";
                  
                  if (mounted) {
                    if (isDocente) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfesorDashboard(
                            docenteId: dIdStr != null ? int.parse(dIdStr) : 0,
                            nombreProfesor: "$n $a",
                          ),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => WebLayout(title: 'Sedes', child: const SedeScreen())),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text("Regresar al Dashboard"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: Colors.white,
            child: _isLoading
                ? const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Mi Perfil",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isEditing ? "Editando información..." : "Información de cuenta",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            _isEditing
                                ? Row(
                                    children: [
                                      TextButton(
                                        onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                                        child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _isSaving ? null : _guardarCambios,
                                        icon: _isSaving
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.save),
                                        label: Text(_isSaving ? "Guardando..." : "Guardar"),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                                      ),
                                    ],
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () => setState(() => _isEditing = true),
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Editar"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 32),
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  _nombresController.text.isNotEmpty ? _nombresController.text[0].toUpperCase() : "A",
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.black54),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildTextField("Nombres", _nombresController, Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField("Apellidos", _apellidosController, Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField("Correo Electrónico", _emailController, Icons.email_outlined),
                        const SizedBox(height: 16),
                        if (_isEditing) ...[
                          _buildTextField("Nueva Contraseña (Opcional)", _passwordController, Icons.lock_outline, isPassword: true),
                          const SizedBox(height: 8),
                          const Text(
                            "Dejar en blanco para mantener la contraseña actual",
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ] else
                          _buildStaticField("Rol de Usuario", _rol, Icons.security),
                      ],
                    ),
                  ),
          ),
        ],
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
