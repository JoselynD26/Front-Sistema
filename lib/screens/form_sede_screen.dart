import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';

class FormSedeScreen extends StatefulWidget {
  const FormSedeScreen({super.key});

  @override
  State<FormSedeScreen> createState() => _FormSedeScreenState();
}

class _FormSedeScreenState extends State<FormSedeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController ubicacionCtrl = TextEditingController();

  bool cargando = false;
  final Color _primaryColor = const Color(0xFF6366F1);

  Future<void> _guardarSede() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    try {
      await _apiService.crearSede({
        "nombre": nombreCtrl.text.trim(),
        "ubicacion": ubicacionCtrl.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al crear sede: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormLayout(
      title: "Nueva Sede",
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
          child: const Text(
            "GUARDAR SEDE",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
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
