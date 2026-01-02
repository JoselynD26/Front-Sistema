import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';

class DocenteFormScreen extends StatefulWidget {
  final int idSede;
  final Map<String, dynamic>? docente;

  const DocenteFormScreen({
    super.key,
    required this.idSede,
    this.docente,
  });

  @override
  State<DocenteFormScreen> createState() => _DocenteFormScreenState();
}

class _DocenteFormScreenState extends State<DocenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  late TextEditingController _cedulaCtrl;
  late TextEditingController _nombresCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _correoCtrl;
  String? _regimen;
  String? _observacion;

  bool cargando = false;
  final Color _primaryColor = const Color(0xFF8B5CF6); // Violet 500

  @override
  void initState() {
    super.initState();
    _cedulaCtrl = TextEditingController(text: widget.docente?["cedula"] ?? "");
    _nombresCtrl = TextEditingController(text: widget.docente?["nombres"] ?? "");
    _apellidosCtrl = TextEditingController(text: widget.docente?["apellidos"] ?? "");
    _correoCtrl = TextEditingController(text: widget.docente?["correo"] ?? "");
    _regimen = widget.docente?["regimen"];
    _observacion = widget.docente?["observacion"];
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    final datos = {
      "cedula": _cedulaCtrl.text.trim(),
      "correo": _correoCtrl.text.trim(),
      "apellidos": _apellidosCtrl.text.trim(),
      "nombres": _nombresCtrl.text.trim(),
      "regimen": _regimen,
      "observacion": _observacion,
      "sede_id": widget.idSede,
    };

    try {
      bool success;
      if (widget.docente == null) {
        success = await _apiService.crearDocente(datos);
      } else {
        success = await _apiService.actualizarDocente(widget.docente!["id"], datos);
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() => cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al guardar docente"), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.docente != null;

    return AdminFormLayout(
      title: esEdicion ? "Editar Docente" : "Nuevo Docente",
      subtitle: "Registre la información del personal docente y configure su régimen laboral.",
      icon: Icons.person_rounded,
      primaryColor: _primaryColor,
      isLoading: cargando,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        TextFormField(
                          controller: _cedulaCtrl,
                          decoration: premiumInputDecoration(
                            label: "Cédula",
                            hint: "ID Ciudadano",
                            icon: Icons.badge_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _correoCtrl,
                          decoration: premiumInputDecoration(
                            label: "Correo",
                            hint: "ejemplo@yavirac.edu.ec",
                            icon: Icons.email_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cedulaCtrl,
                          decoration: premiumInputDecoration(
                            label: "Cédula",
                            hint: "ID Ciudadano",
                            icon: Icons.badge_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _correoCtrl,
                          decoration: premiumInputDecoration(
                            label: "Correo",
                            hint: "ejemplo@yavirac.edu.ec",
                            icon: Icons.email_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        TextFormField(
                          controller: _nombresCtrl,
                          decoration: premiumInputDecoration(
                            label: "Nombres",
                            hint: "Ej. Juan Pablo",
                            icon: Icons.person_outline_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _apellidosCtrl,
                          decoration: premiumInputDecoration(
                            label: "Apellidos",
                            hint: "Ej. Pérez García",
                            icon: Icons.person_outline_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nombresCtrl,
                          decoration: premiumInputDecoration(
                            label: "Nombres",
                            hint: "Ej. Juan Pablo",
                            icon: Icons.person_outline_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _apellidosCtrl,
                          decoration: premiumInputDecoration(
                            label: "Apellidos",
                            hint: "Ej. Pérez García",
                            icon: Icons.person_outline_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _regimen,
                          items: const [
                            DropdownMenuItem(value: "LOES", child: Text("LOES")),
                            DropdownMenuItem(value: "Codigo de trabajo", child: Text("Código de trabajo")),
                          ],
                          onChanged: (val) => setState(() => _regimen = val),
                          decoration: premiumInputDecoration(
                            label: "Régimen",
                            hint: "Seleccione...",
                            icon: Icons.gavel_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v == null ? "Requerido" : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _observacion,
                          items: const [
                            DropdownMenuItem(value: "Medio tiempo", child: Text("Medio tiempo")),
                            DropdownMenuItem(value: "Tiempo completo", child: Text("Tiempo completo")),
                          ],
                          onChanged: (val) => setState(() => _observacion = val),
                          decoration: premiumInputDecoration(
                            label: "Dedicación",
                            hint: "Seleccione...",
                            icon: Icons.access_time_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v == null ? "Requerido" : null,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _regimen,
                          items: const [
                            DropdownMenuItem(value: "LOES", child: Text("LOES")),
                            DropdownMenuItem(value: "Codigo de trabajo", child: Text("Código de trabajo")),
                          ],
                          onChanged: (val) => setState(() => _regimen = val),
                          decoration: premiumInputDecoration(
                            label: "Régimen",
                            hint: "Seleccione...",
                            icon: Icons.gavel_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v == null ? "Requerido" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _observacion,
                          items: const [
                            DropdownMenuItem(value: "Medio tiempo", child: Text("Medio tiempo")),
                            DropdownMenuItem(value: "Tiempo completo", child: Text("Tiempo completo")),
                          ],
                          onChanged: (val) => setState(() => _observacion = val),
                          decoration: premiumInputDecoration(
                            label: "Dedicación",
                            hint: "Seleccione...",
                            icon: Icons.access_time_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v == null ? "Requerido" : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
      actions: [
        ElevatedButton(
          onPressed: cargando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: _primaryColor.withOpacity(0.4),
          ),
          child: Text(
            esEdicion ? "GUARDAR CAMBIOS" : "REGISTRAR DOCENTE",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text("Cancelar y volver"),
        ),
      ],
    );
  }
}
