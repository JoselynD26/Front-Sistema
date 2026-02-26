import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';
import '../widgets/custom_dialog.dart';
import '../utils/app_colors.dart';

class CursoFormScreen extends StatefulWidget {
  final int idSede;
  final Map<String, dynamic>? curso;

  const CursoFormScreen({
    super.key,
    required this.idSede,
    this.curso,
  });

  @override
  State<CursoFormScreen> createState() => _CursoFormScreenState();
}

class _CursoFormScreenState extends State<CursoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  final _nombreController = TextEditingController();
  final _nivelController = TextEditingController();
  final _paraleloController = TextEditingController();
  
  String _jornadaSeleccionada = "Matutina";
  int? _carreraSeleccionada;
  List<dynamic> carrerasDisponibles = [];

  bool cargando = true;
  bool guardando = false;
  final Color _primaryColor = AppColors.bluePrimary; // Amber 500 equivalent

  @override
  void initState() {
    super.initState();
    if (widget.curso != null) {
      _nombreController.text = widget.curso!["nombre"] ?? "";
      _nivelController.text = widget.curso!["nivel"] ?? "";
      _paraleloController.text = widget.curso!["paralelo"] ?? "";
      _jornadaSeleccionada = widget.curso!["jornada"] ?? "Matutina";
      _carreraSeleccionada = widget.curso!["carrera_id"];
    }
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      final data = await _apiService.listarCarreras();
      setState(() {
        carrerasDisponibles = data.where((c) => 
          (c["sede_ids"] as List).contains(widget.idSede)
        ).toList();
        cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione una carrera"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => guardando = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingCtx) => CustomDialog(
        title: widget.curso == null ? "Creando Curso..." : "Actualizando...",
        description: "Por favor espera un momento",
        type: DialogType.info,
        isLoading: true,
      ),
    );

    final datos = {
      "nombre": _nombreController.text.trim(),
      "nivel": _nivelController.text.trim(),
      "paralelo": _paraleloController.text.trim(),
      "carrera_id": _carreraSeleccionada,
      "jornada": _jornadaSeleccionada,
      "id_sede": widget.idSede,
    };

    try {
      bool success;
      if (widget.curso == null) {
        success = await _apiService.crearCurso(datos);
      } else {
        success = await _apiService.actualizarCurso(widget.curso!["id"], datos);
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog safely
        
        if (success) {
          showDialog(
            context: context,
            builder: (successCtx) => CustomDialog(
              title: "¡Éxito!",
              description: widget.curso == null 
                ? "El curso ha sido creado correctamente" 
                : "El curso ha sido actualizado correctamente",
              type: DialogType.success,
              confirmText: "Aceptar",
              onConfirm: () {
                Navigator.pop(successCtx); // Close success dialog
                Navigator.pop(context, true); // Return to list
              },
            ),
          );
        } else {
          setState(() => guardando = false);
          showDialog(
            context: context,
            builder: (errorCtx) => const CustomDialog(
              title: "Error",
              description: "No se pudo guardar el curso. Intenta nuevamente.",
              type: DialogType.error,
              confirmText: "Aceptar",
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog safely
        setState(() => guardando = false);
        showDialog(
          context: context,
          builder: (errorCtx) => CustomDialog(
            title: "Error",
            description: "Ocurrió un error inesperado: $e",
            type: DialogType.error,
            confirmText: "Aceptar",
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.curso != null;

    return AdminFormLayout(
      title: esEdicion ? "Editar Curso" : "Nuevo Curso",
      subtitle: "Configure el nivel, paralelo y carrera para este nuevo grupo de estudiantes.",
      icon: Icons.class_rounded,
      primaryColor: _primaryColor,
      isLoading: cargando || guardando,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: premiumInputDecoration(
                  label: "Nombre del Curso",
                  hint: "Ej. Quinto Semestre",
                  icon: Icons.title_rounded,
                  primaryColor: _primaryColor,
                ),
                validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        TextFormField(
                          controller: _nivelController,
                          decoration: premiumInputDecoration(
                            label: "Nivel",
                            hint: "Ej. 5",
                            icon: Icons.layers_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _paraleloController,
                          decoration: premiumInputDecoration(
                            label: "Paralelo",
                            hint: "Ej. A",
                            icon: Icons.grid_view_rounded,
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
                          controller: _nivelController,
                          decoration: premiumInputDecoration(
                            label: "Nivel",
                            hint: "Ej. 5",
                            icon: Icons.layers_rounded,
                            primaryColor: _primaryColor,
                          ),
                          validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _paraleloController,
                          decoration: premiumInputDecoration(
                            label: "Paralelo",
                            hint: "Ej. A",
                            icon: Icons.grid_view_rounded,
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
              DropdownButtonFormField<int>(
                value: _carreraSeleccionada,
                items: carrerasDisponibles.map((carrera) => 
                  DropdownMenuItem<int>(
                    value: carrera["id"],
                    child: Text(carrera["nombre"]),
                  )
                ).toList(),
                onChanged: (value) => setState(() => _carreraSeleccionada = value),
                decoration: premiumInputDecoration(
                  label: "Carrera",
                  hint: "Seleccione...",
                  icon: Icons.school_rounded,
                  primaryColor: _primaryColor,
                ),
                validator: (v) => v == null ? "Requerido" : null,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _jornadaSeleccionada,
                items: const [
                  DropdownMenuItem(value: "Matutina", child: Text("Matutina")),
                  DropdownMenuItem(value: "Vespertina", child: Text("Vespertina")),
                  DropdownMenuItem(value: "Nocturna", child: Text("Nocturna")),
                ],
                onChanged: (value) => setState(() => _jornadaSeleccionada = value!),
                decoration: premiumInputDecoration(
                  label: "Jornada",
                  hint: "Seleccione...",
                  icon: Icons.wb_sunny_rounded,
                  primaryColor: _primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
      actions: [
        ElevatedButton(
          onPressed: (cargando || guardando) ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: _primaryColor.withOpacity(0.4),
          ),
          child: Text(
            esEdicion ? "GUARDAR CAMBIOS" : "CREAR CURSO",
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
