import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';
import '../widgets/custom_dialog.dart';
import '../utils/app_colors.dart';

class FormSedeScreen extends StatefulWidget {
  final Map<String, dynamic>? sede;
  const FormSedeScreen({super.key, this.sede});

  @override
  State<FormSedeScreen> createState() => _FormSedeScreenState();
}

class _FormSedeScreenState extends State<FormSedeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController ubicacionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.sede != null) {
      nombreCtrl.text = widget.sede!['nombre'];
      ubicacionCtrl.text = widget.sede!['ubicacion'] ?? '';
    }
  }

  bool cargando = false;
 final Color _primaryColor = AppColors.bluePrimary;

  Future<void> _guardarSede() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: widget.sede == null ? "Creando Sede..." : "Actualizando...",
        description: "Por favor espera un momento",
        type: DialogType.info,
        isLoading: true,
      ),
    );

    try {
      final datos = {
        "nombre": nombreCtrl.text.trim(),
        "ubicacion": ubicacionCtrl.text.trim(),
      };

      if (widget.sede == null) {
        await _apiService.crearSede(datos);
      } else {
        await _apiService.actualizarSede(widget.sede!['id'], datos);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
            title: "¡Éxito!",
            description: widget.sede == null 
              ? "La sede ha sido creada correctamente" 
              : "La sede ha sido actualizada correctamente",
            type: DialogType.success,
            confirmText: "Aceptar",
            onConfirm: () {
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context, true); // Return to list
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        setState(() => cargando = false);
        
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
            title: "Error",
            description: "No se pudo procesar la solicitud: $e",
            type: DialogType.error,
            confirmText: "Aceptar",
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormLayout(
      title: widget.sede == null ? "Nueva Sede" : "Editar Sede",
      subtitle: "Ingrese la información básica de la sede universitaria para comenzar su gestión.",
      icon: Icons.business_rounded,
      primaryColor: _primaryColor,
      isLoading: cargando,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: premiumInputDecoration(
                  label: "Nombre de la Sede",
                  hint: "Ej. Campus Central",
                  icon: Icons.store_mall_directory_rounded,
                  primaryColor: _primaryColor,
                ),
                validator: (v) => v!.trim().isEmpty ? "Este campo es obligatorio" : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: ubicacionCtrl,
                decoration: premiumInputDecoration(
                  label: "Ubicación / Dirección",
                  hint: "Ej. Av. Universitaria 123",
                  icon: Icons.map_rounded,
                  primaryColor: _primaryColor,
                ),
                validator: (v) => v!.trim().isEmpty ? "Este campo es obligatorio" : null,
              ),
            ],
          ),
        ),
      ],
      actions: [
        ElevatedButton(
          onPressed: cargando ? null : _guardarSede,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: _primaryColor.withOpacity(0.4),
          ),
          child: Text(
            widget.sede == null ? "GUARDAR SEDE" : "ACTUALIZAR SEDE",
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
