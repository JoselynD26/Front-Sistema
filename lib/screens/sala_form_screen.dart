import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';
import '../utils/app_colors.dart';

class SalaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? sala;
  final int idSede;

  const SalaFormScreen({
    super.key,
    this.sala,
    required this.idSede,
  });

  @override
  State<SalaFormScreen> createState() => _SalaFormScreenState();
}

class _SalaFormScreenState extends State<SalaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _capacidadController = TextEditingController();
  
  final _apiService = ApiService();
  bool _isLoading = false;
  final Color _primaryColor = AppColors.bluePrimary;// Amber 500 equivalent

  @override
  void initState() {
    super.initState();
    if (widget.sala != null) {
      _nombreController.text = widget.sala!['nombre'] ?? '';
      _capacidadController.text = (widget.sala!['capacidad'] ?? '20').toString();
    } else {
      _capacidadController.text = '20';
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final datos = {
      "nombre": _nombreController.text.trim(),
      "capacidad": int.tryParse(_capacidadController.text) ?? 20,
      "sede_id": widget.idSede,
    };

    bool success;
    try {
      if (widget.sala == null) {
        success = await _apiService.crearSala(datos);
      } else {
        success = await _apiService.actualizarSala(widget.sala!['id'], datos);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sala guardada correctamente"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error al guardar la sala"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.sala != null;

    return AdminFormLayout(
      title: isEdit ? "Editar Sala" : "Nueva Sala",
      subtitle: "Configure los detalles de la sala y su capacidad para la gestión de recursos.",
      icon: Icons.meeting_room_rounded,
      primaryColor: _primaryColor,
      isLoading: _isLoading,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: premiumInputDecoration(
                  label: "Nombre de la Sala",
                  hint: "Ej. Laboratorio A",
                  icon: Icons.label_outlined,
                  primaryColor: _primaryColor,
                ),
                validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _capacidadController,
                keyboardType: TextInputType.number,
                decoration: premiumInputDecoration(
                  label: "Capacidad",
                  hint: "Ej. 20",
                  icon: Icons.people_outline,
                  primaryColor: _primaryColor,
                ),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
            ],
          ),
        ),
      ],
      actions: [
        ElevatedButton(
          onPressed: _isLoading ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: _primaryColor.withOpacity(0.4),
          ),
          child: Text(
            isEdit ? "GUARDAR CAMBIOS" : "CREAR SALA",
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
