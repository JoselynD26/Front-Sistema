import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';

class CarreraFormScreen extends StatefulWidget {
  final int idSede;
  final Map<String, dynamic>? carrera;

  const CarreraFormScreen({
    super.key,
    required this.idSede,
    this.carrera,
  });

  @override
  State<CarreraFormScreen> createState() => _CarreraFormScreenState();
}

class _CarreraFormScreenState extends State<CarreraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  late TextEditingController _nombreCtrl;
  late TextEditingController _codigoCtrl;
  bool cargando = false;
  final Color _primaryColor = const Color(0xFFF59E0B); // Amber 500 equivalent

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.carrera?["nombre"] ?? "");
    _codigoCtrl = TextEditingController(text: widget.carrera?["codigo"] ?? "");
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    final datos = {
      "nombre": _nombreCtrl.text.trim(),
      "codigo": _codigoCtrl.text.trim().isEmpty ? "AUTO" : _codigoCtrl.text.trim(),
      "sede_ids": [widget.idSede],
    };

    try {
      bool success;
      if (widget.carrera == null) {
        success = await _apiService.crearCarrera(datos);
      } else {
        success = await _apiService.actualizarCarrera(widget.carrera!["id"], datos);
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() => cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al guardar carrera"), backgroundColor: Colors.redAccent),
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
    final esEdicion = widget.carrera != null;

    return AdminFormLayout(
      title: esEdicion ? "Editar Carrera" : "Nueva Carrera",
      subtitle: "Defina los programas académicos de la sede para organizar la oferta educativa.",
      icon: Icons.school_rounded,
      primaryColor: _primaryColor,
      isLoading: cargando,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: premiumInputDecoration(
                  label: "Nombre de la Carrera",
                  hint: "Ej. Ingeniería de Software",
                  icon: Icons.menu_book_rounded,
                  primaryColor: _primaryColor,
                ),
                validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codigoCtrl,
                decoration: premiumInputDecoration(
                  label: "Código (Opcional)",
                  hint: "Dejar vacío para generación automática",
                  icon: Icons.code_rounded,
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
            esEdicion ? "GUARDAR CAMBIOS" : "CREAR CARRERA",
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