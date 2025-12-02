import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HorarioForm extends StatefulWidget {
  final Map? horario;
  final int idSede;
  final Function? onSave;

  const HorarioForm({
    super.key,
    this.horario,
    required this.idSede,
    this.onSave,
  });

  @override
  _HorarioFormState createState() => _HorarioFormState();
}

class _HorarioFormState extends State<HorarioForm> {
  final _fechaController = TextEditingController();
  final _horaController = TextEditingController();
  final _estadoController = TextEditingController(text: "activo");
  final _docenteController = TextEditingController();
  final _materiaController = TextEditingController();
  final _aulaController = TextEditingController();

  final apiService = ApiService();
  bool cargando = false;
  String? mensaje;

  @override
  void initState() {
    super.initState();
    if (widget.horario != null) {
      _fechaController.text = widget.horario!['fecha'] ?? "";
      _horaController.text = widget.horario!['hora'] ?? "";
      _estadoController.text = widget.horario!['estado'] ?? "activo";
      _docenteController.text = widget.horario!['id_docente']?.toString() ?? "";
      _materiaController.text = widget.horario!['id_materia']?.toString() ?? "";
      _aulaController.text = widget.horario!['id_aula']?.toString() ?? "";
    }
  }

  Future<void> _guardar() async {
    if (_fechaController.text.isEmpty || _horaController.text.isEmpty) {
      setState(() => mensaje = "Fecha y hora son obligatorias");
      return;
    }
    if (_docenteController.text.isEmpty ||
        _materiaController.text.isEmpty ||
        _aulaController.text.isEmpty) {
      setState(() => mensaje = "Docente, Materia y Aula son obligatorios");
      return;
    }

    setState(() => cargando = true);

    final datos = {
      "fecha": _fechaController.text.trim(),
      "hora": _horaController.text.trim(),
      "estado": _estadoController.text.trim(),
      "id_docente": int.tryParse(_docenteController.text) ?? 0,
      "id_materia": int.tryParse(_materiaController.text) ?? 0,
      "id_aula": int.tryParse(_aulaController.text) ?? 0,
      "id_sede": widget.idSede,
    };

    bool success;
    if (widget.horario == null) {
      success = await apiService.crearHorario(datos);
    } else {
      success = await apiService.actualizarHorario(widget.horario!['id'], datos);
    }

    setState(() {
      cargando = false;
      mensaje = success ? "Guardado con éxito" : "Error al guardar";
    });

    if (success && widget.onSave != null) {
      widget.onSave!();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.horario == null ? "Nuevo Horario" : "Editar Horario"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Sede ID: ${widget.idSede}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _fechaController,
              decoration: const InputDecoration(labelText: "Fecha (YYYY-MM-DD)"),
            ),
            TextField(
              controller: _horaController,
              decoration: const InputDecoration(labelText: "Hora (HH:MM)"),
            ),
            TextField(
              controller: _estadoController,
              decoration: const InputDecoration(labelText: "Estado"),
            ),
            TextField(
              controller: _docenteController,
              decoration: const InputDecoration(labelText: "ID Docente"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _materiaController,
              decoration: const InputDecoration(labelText: "ID Materia"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _aulaController,
              decoration: const InputDecoration(labelText: "ID Aula"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            if (cargando) const Center(child: CircularProgressIndicator()),
            if (mensaje != null)
              Center(
                child: Text(
                  mensaje!,
                  style: TextStyle(
                    color: mensaje == "Guardado con éxito" ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: cargando ? null : _guardar,
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}