import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';
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

      safeSetState(() {
        salasDisponibles = salas;
        carrerasDisponibles = carreras.where((c) => 
          (c["sede_ids"] as List).contains(widget.idSede)
        ).toList();
        docentesDisponibles = docentes;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _guardar() async {
    if (_codigoController.text.trim().isEmpty || salaSeleccionada == null || carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos obligatorios")),
      );
      return;
    }

    safeSetState(() => cargando = true);

    final datos = {
      "codigo": _codigoController.text.trim(),
      "estado": estado,
      "jornada": jornada,
      "sala_id": salaSeleccionada,
      "carrera_id": carreraSeleccionada,
      "docente_id": docenteSeleccionado,
    };

    bool success;
    if (widget.escritorio == null) {
      success = await apiService.crearEscritorio(datos);
    } else {
      success = await apiService.actualizarEscritorio(widget.escritorio!['id'], datos);
    }

    safeSetState(() => cargando = false);

    if (success) {
      if (widget.onSave != null) widget.onSave!();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar escritorio")),
      );
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: estado,
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
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: salaSeleccionada,
              items: salasDisponibles.map((sala) => DropdownMenuItem<int>(value: sala["id"], child: Text(sala["nombre"]))).toList(),
              onChanged: (value) => safeSetState(() => salaSeleccionada = value),
              decoration: premiumInputDecoration(
                label: "Sala Destino",
                hint: "Seleccione la sala...",
                icon: Icons.meeting_room_rounded,
                primaryColor: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: carreraSeleccionada,
              items: carrerasDisponibles.map((carrera) => DropdownMenuItem<int>(value: carrera["id"], child: Text(carrera["nombre"]))).toList(),
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
              value: docenteSeleccionado,
              items: docentesDisponibles.map((docente) => DropdownMenuItem<int>(value: docente["id"], child: Text("${docente["apellidos"]} ${docente["nombres"]}"))).toList(),
              onChanged: (value) => safeSetState(() => docenteSeleccionado = value),
              decoration: premiumInputDecoration(
                label: "Docente (Opcional)",
                hint: "Seleccione el docente...",
                icon: Icons.person_rounded,
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