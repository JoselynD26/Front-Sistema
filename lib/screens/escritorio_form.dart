import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';
import '../widgets/custom_dialog.dart';
import '../utils/mouse_tracker_fix.dart';

class EscritorioForm extends StatefulWidget {
  final Map? escritorio;
  final int idSede;
  final Function? onSave;

  const EscritorioForm({
    super.key,
    this.escritorio,
    required this.idSede,
    this.onSave,
  });

  @override
  _EscritorioFormState createState() => _EscritorioFormState();
}

class _EscritorioFormState extends State<EscritorioForm> with SafeStateMixin {
  final _codigoController = TextEditingController();
  String estado = "libre";
  String jornada = "matutina";
  int? salaSeleccionada;
  int? carreraSeleccionada;
  int? docenteSeleccionado;
  List<dynamic> salasDisponibles = [];
  List<dynamic> carrerasDisponibles = [];
  List<dynamic> docentesDisponibles = [];
  List<dynamic> materias = [];
  Map<int, Set<int>> docenteCarrerasMap = {}; // DocenteID -> Set<CarreraID>
  final apiService = ApiService();
  bool cargando = false;
  final Color _primaryColor = const Color(0xFF06B6D4); // Cyan 500

  @override
  void initState() {
    super.initState();
    if (widget.escritorio != null) {
      _codigoController.text = widget.escritorio!['codigo'];
      estado = widget.escritorio!['estado'];
      jornada = widget.escritorio!['jornada'];
      salaSeleccionada = widget.escritorio!['sala_id'];
      carreraSeleccionada = widget.escritorio!['carrera_id'];
      docenteSeleccionado = widget.escritorio!['docente_id'];
    }
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final salas = await apiService.listarSalasPorSede(widget.idSede);
      final carreras = await apiService.listarCarreras();
      final docentes = await apiService.listarDocentes(widget.idSede);
      final materiasData = await apiService.listarMateriasPorSede(widget.idSede);

      // Map Docente ID -> Carrera IDs based on assigned Materias
      Map<int, Set<int>> tempMap = {};
      for (var materia in materiasData) {
        // Assuming materia has 'docente_id' and 'carrera_id'
        // Need to check API response structure or adapt if needed.
        // If 'docente_id' is null (not assigned), skip.
        if (materia['docente_id'] != null && materia['carrera_id'] != null) {
          int docId = materia['docente_id'];
          int carId = materia['carrera_id'];
          tempMap.putIfAbsent(docId, () => {}).add(carId);
        }
      }

      safeSetState(() {
        salasDisponibles = salas;
        docentesDisponibles = docentes;
        materias = materiasData;
        docenteCarrerasMap = tempMap;
        
        // Filter carreras for current sede
        carrerasDisponibles = carreras.where((c) => 
          (c["sede_ids"] as List).contains(widget.idSede)
        ).toList();
        
        // Initial filtering if editing and docente is selected
        if (docenteSeleccionado != null) {
          _filtrarCarrerasPorDocente(docenteSeleccionado!);
        }
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  void _filtrarCarrerasPorDocente(int docenteId) {
    if (docenteCarrerasMap.containsKey(docenteId)) {
        final allowedCarreras = docenteCarrerasMap[docenteId]!;
        // Assuming we want to RESTRICT to only these careers?
        // Or just prioritize/highlight? The requirement says "valide segun el profe la carrera"
        // Let's filter the list `carrerasDisponibles` shown in dropdown? 
        // Or better, let's keep a separate `carrerasFiltradas` list for the dropdown.
        
        // WAIT: if I modify available options, I might invalidate current selection if it mismatches.
        // Let's implement logic: 
        // Identify valid careers for this doc.
        // If current selection is invalid, clear it.
        // If only one valid career, auto-select it.
        
        final carrerasDelProfe = carrerasDisponibles.where((c) => allowedCarreras.contains(c["id"])).toList();
        
        if (carrerasDelProfe.isNotEmpty) {
            // Check if current selection resembles one of these
            if (carreraSeleccionada != null && !allowedCarreras.contains(carreraSeleccionada)) {
                carreraSeleccionada = null; // Clear invalid selection
            }
            
            // If only one, auto-select
            if (carrerasDelProfe.length == 1) {
                carreraSeleccionada = carrerasDelProfe.first["id"];
            }
        }
    }
    // If map doesn't contain docente (no materias assigned), maybe allow all? 
    // Usually safe to allow all if we don't know better.
  }
  
  List<dynamic> _getCarrerasParaMostrar() {
     if (docenteSeleccionado != null && docenteCarrerasMap.containsKey(docenteSeleccionado)) {
         final allowed = docenteCarrerasMap[docenteSeleccionado];
         final filtradas = carrerasDisponibles.where((c) => allowed!.contains(c["id"])).toList();
         if (filtradas.isNotEmpty) return filtradas;
     }
     return carrerasDisponibles;
  }

  Future<void> _guardar() async {
    if (_codigoController.text.trim().isEmpty || salaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos obligatorios")),
      );
      return;
    }

    safeSetState(() => cargando = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: widget.escritorio == null ? "Creando Escritorio..." : "Actualizando...",
        description: "Por favor espera un momento",
        type: DialogType.info,
        isLoading: true,
      ),
    );

    final datos = {
      "codigo": _codigoController.text.trim(),
      "estado": estado,
      "jornada": jornada,
      "sala_id": salaSeleccionada,
      "carrera_id": carreraSeleccionada,
      "docente_id": docenteSeleccionado,
    };

    try {
      bool success;
      if (widget.escritorio == null) {
        success = await apiService.crearEscritorio(datos);
      } else {
        success = await apiService.actualizarEscritorio(widget.escritorio!['id'], datos);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (success) {
          showDialog(
            context: context,
            builder: (context) => CustomDialog(
              title: "¡Éxito!",
              description: widget.escritorio == null 
                ? "El escritorio ha sido creado correctamente" 
                : "El escritorio ha sido actualizado correctamente",
              type: DialogType.success,
              confirmText: "Aceptar",
              onConfirm: () {
                Navigator.pop(context); // Close success dialog
                if (widget.onSave != null) widget.onSave!();
                Navigator.pop(context); // Return to list
              },
            ),
          );
        } else {
          safeSetState(() => cargando = false);
          showDialog(
            context: context,
            builder: (context) => const CustomDialog(
              title: "Error",
              description: "No se pudo guardar el escritorio. Intenta nuevamente.",
              type: DialogType.error,
              confirmText: "Aceptar",
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        safeSetState(() => cargando = false);
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
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
    final bool isEdit = widget.escritorio != null;

    return AdminFormLayout(
      title: isEdit ? "Editar Escritorio" : "Nuevo Escritorio",
      subtitle: "Asigne códigos y configure la disponibilidad de los espacios de trabajo.",
      icon: Icons.desk_rounded,
      primaryColor: _primaryColor,
      isLoading: cargando,
      children: [
        Column(
          children: [
            TextField(
              controller: _codigoController,
              decoration: premiumInputDecoration(
                label: "Código del Escritorio",
                hint: "Ej. ESC-001",
                icon: Icons.qr_code_rounded,
                primaryColor: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: estado,
                        isExpanded: true,
                        items: ["libre", "ocupado"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (value) => safeSetState(() => estado = value!),
                        decoration: premiumInputDecoration(
                          label: "Estado",
                          hint: "Seleccione...",
                          icon: Icons.info_outline_rounded,
                          primaryColor: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: jornada,
                        isExpanded: true,
                        items: ["matutina", "vespertina", "nocturna"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (value) => safeSetState(() => jornada = value!),
                        decoration: premiumInputDecoration(
                          label: "Jornada",
                          hint: "Seleccione...",
                          icon: Icons.schedule_rounded,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: estado,
                        isExpanded: true,
                        items: ["libre", "ocupado"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (value) => safeSetState(() => estado = value!),
                        decoration: premiumInputDecoration(
                          label: "Estado",
                          hint: "Seleccione...",
                          icon: Icons.info_outline_rounded,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: jornada,
                        isExpanded: true,
                        items: ["matutina", "vespertina", "nocturna"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (value) => safeSetState(() => jornada = value!),
                        decoration: premiumInputDecoration(
                          label: "Jornada",
                          hint: "Seleccione...",
                          icon: Icons.schedule_rounded,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: docenteSeleccionado,
              isExpanded: true,
              items: docentesDisponibles.map((docente) => DropdownMenuItem<int>(value: docente["id"], child: Text("${docente["apellidos"]} ${docente["nombres"]}"))).toList(),
              onChanged: (value) {
                safeSetState(() {
                    docenteSeleccionado = value;
                    if (value != null) _filtrarCarrerasPorDocente(value);
                });
              },
              decoration: premiumInputDecoration(
                label: "Docente (Opcional)",
                hint: "Seleccione el docente...",
                icon: Icons.person_rounded,
                primaryColor: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: carreraSeleccionada,
              isExpanded: true,
              items: _getCarrerasParaMostrar().map((carrera) => DropdownMenuItem<int>(value: carrera["id"], child: Text(carrera["nombre"]))).toList(),
              onChanged: (value) => safeSetState(() => carreraSeleccionada = value),
              decoration: premiumInputDecoration(
                label: "Carrera Asignada",
                hint: "Seleccione la carrera...",
                icon: Icons.school_rounded,
                primaryColor: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: salaSeleccionada,
              isExpanded: true,
              items: salasDisponibles.map((sala) => DropdownMenuItem<int>(value: sala["id"], child: Text(sala["nombre"]))).toList(),
              onChanged: (value) => safeSetState(() => salaSeleccionada = value),
              decoration: premiumInputDecoration(
                label: "Sala Destino",
                hint: "Seleccione la sala...",
                icon: Icons.meeting_room_rounded,
                primaryColor: _primaryColor,
              ),
            ),
          ],
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
            isEdit ? "GUARDAR CAMBIOS" : "CREAR ESCRITORIO",
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