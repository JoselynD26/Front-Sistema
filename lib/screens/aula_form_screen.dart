import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';

class AulaFormScreen extends StatefulWidget {
  final int idSede;
  final Map<String, dynamic>? aula;

  const AulaFormScreen({
    super.key,
    required this.idSede,
    this.aula,
  });

  @override
  State<AulaFormScreen> createState() => _AulaFormScreenState();
}

class _AulaFormScreenState extends State<AulaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  late TextEditingController _nombreCtrl;
  late TextEditingController _numeroCtrl;
  late TextEditingController _capacidadCtrl;
  late TextEditingController _descripcionCtrl;

  bool cargando = false;
  final Color _primaryColor = const Color(0xFFF59E0B); // Amber 500

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.aula?["nombre"] ?? "");
    _numeroCtrl = TextEditingController(text: widget.aula?["numero"] ?? "");
    _capacidadCtrl = TextEditingController(text: widget.aula?["capacidad"]?.toString() ?? "");
    _descripcionCtrl = TextEditingController(text: widget.aula?["descripcion"] ?? "");
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _numeroCtrl.dispose();
    _capacidadCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    final datos = {
      "nombre": _nombreCtrl.text.trim(),
      "numero": _numeroCtrl.text.trim(),
      "capacidad": int.tryParse(_capacidadCtrl.text) ?? 0,
      "descripcion": _descripcionCtrl.text.trim(),
      "id_sede": widget.idSede,
    };

    bool success;
    try {
      if (widget.aula == null) {
        success = await _apiService.crearAula(datos);
      } else {
        success = await _apiService.actualizarAula(widget.aula!["id"], datos);
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() => cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al guardar aula"), backgroundColor: Colors.redAccent),
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
    final esEdicion = widget.aula != null;

    return AdminFormLayout(
      title: esEdicion ? "Editar Aula" : "Nueva Aula",
      subtitle: "Configure los detalles del espacio físico y capacidad para la gestión de horarios.",
      icon: Icons.meeting_room_rounded,
      primaryColor: _primaryColor,
      isLoading: cargando,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numeroCtrl,
                      decoration: premiumInputDecoration(
                        label: "Número / Código",
                        hint: "Ej. 101",
                        icon: Icons.pin_invoke,
                        primaryColor: _primaryColor,
                      ),
                      validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _capacidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: premiumInputDecoration(
                        label: "Capacidad",
                        hint: "Ej. 40",
                        icon: Icons.groups_rounded,
                        primaryColor: _primaryColor,
                      ),
                      validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreCtrl,
                decoration: premiumInputDecoration(
                  label: "Nombre (Opcional)",
                  hint: "Ej. Aula Magna",
                  icon: Icons.class_rounded,
                  primaryColor: _primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 3,
                decoration: premiumInputDecoration(
                  label: "Descripción",
                  hint: "Detalles adicionales sobre el aula...",
                  icon: Icons.description_rounded,
                  primaryColor: _primaryColor,
                ),
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
            esEdicion ? "GUARDAR CAMBIOS" : "CREAR AULA",
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