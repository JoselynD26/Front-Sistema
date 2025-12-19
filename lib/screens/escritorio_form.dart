import 'package:flutter/material.dart';
import '../services/api_service.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.escritorio == null ? "Nuevo Escritorio" : "Editar Escritorio")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: "Código"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: estado,
                items: ["libre", "ocupado"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => safeSetState(() => estado = value!),
                decoration: const InputDecoration(labelText: "Estado"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: jornada,
                items: ["matutina", "vespertina", "nocturna"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => safeSetState(() => jornada = value!),
                decoration: const InputDecoration(labelText: "Jornada"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: salaSeleccionada,
                items: salasDisponibles.map((sala) => DropdownMenuItem<int>(value: sala["id"], child: Text(sala["nombre"]))).toList(),
                onChanged: (value) => safeSetState(() => salaSeleccionada = value),
                decoration: const InputDecoration(labelText: "Sala"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: carreraSeleccionada,
                items: carrerasDisponibles.map((carrera) => DropdownMenuItem<int>(value: carrera["id"], child: Text(carrera["nombre"]))).toList(),
                onChanged: (value) => safeSetState(() => carreraSeleccionada = value),
                decoration: const InputDecoration(labelText: "Carrera"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: docenteSeleccionado,
                items: docentesDisponibles.map((docente) => DropdownMenuItem<int>(value: docente["id"], child: Text("${docente["nombres"]} ${docente["apellidos"]}"))).toList(),
                onChanged: (value) => safeSetState(() => docenteSeleccionado = value),
                decoration: const InputDecoration(labelText: "Docente (Opcional)"),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: cargando ? null : _guardar,
                      child: cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Guardar"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}