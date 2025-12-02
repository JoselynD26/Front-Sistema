import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

class _EscritorioFormState extends State<EscritorioForm> {
  final _codigoController = TextEditingController();
  final _salaController = TextEditingController();
  final _carreraController = TextEditingController();

  String estado = "libre";
  String jornada = "matutina";

  int? docenteSeleccionado;
  List<dynamic> docentesDisponibles = [];

  final apiService = ApiService();
  bool cargando = false;
  String? mensaje;

  @override
  void initState() {
    super.initState();
    if (widget.escritorio != null) {
      _codigoController.text = widget.escritorio!['codigo'];
      estado = widget.escritorio!['estado'];
      jornada = widget.escritorio!['jornada'];
      _salaController.text = widget.escritorio!['sala_id'].toString();
      _carreraController.text = widget.escritorio!['carrera_id'].toString();
      docenteSeleccionado = widget.escritorio!['docente_id'];
    }
    _cargarDocentes();
  }

  Future<void> _cargarDocentes() async {
    try {
      final data = await apiService.listarDocentes(widget.idSede);
      setState(() {
        docentesDisponibles = data;

        // ✅ Validar que el docente seleccionado esté en la lista
        if (!docentesDisponibles.any((d) => d["id"] == docenteSeleccionado)) {
          docenteSeleccionado = null;
        }
      });
    } catch (e) {
      print("Error cargando docentes: $e");
    }
  }

  Future<void> _guardar() async {
    if (_codigoController.text.trim().isEmpty ||
        _salaController.text.trim().isEmpty ||
        _carreraController.text.trim().isEmpty) {
      setState(() => mensaje = "Todos los campos son obligatorios");
      return;
    }

    int? salaId = int.tryParse(_salaController.text);
    int? carreraId = int.tryParse(_carreraController.text);

    if (salaId == null || carreraId == null) {
      setState(() => mensaje = "IDs deben ser números válidos");
      return;
    }

    setState(() => cargando = true);

    final datos = {
      "codigo": _codigoController.text.trim(),
      "estado": estado,
      "jornada": jornada,
      "sala_id": salaId,
      "carrera_id": carreraId,
      "docente_id": docenteSeleccionado,
    };

    bool success;
    if (widget.escritorio == null) {
      success = await apiService.crearEscritorio(datos);
    } else {
      success = await apiService.actualizarEscritorio(widget.escritorio!['id'], datos);
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
        title: Text(widget.escritorio == null ? "Nuevo Escritorio" : "Editar Escritorio"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _codigoController,
              decoration: const InputDecoration(labelText: "Código"),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: estado,
              items: ["libre", "ocupado"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => estado = value!),
              decoration: const InputDecoration(labelText: "Estado"),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: jornada,
              items: ["matutina", "vespertina", "nocturna"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => jornada = value!),
              decoration: const InputDecoration(labelText: "Jornada"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _salaController,
              decoration: const InputDecoration(labelText: "Sala ID"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _carreraController,
              decoration: const InputDecoration(labelText: "Carrera ID"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: docentesDisponibles.any((d) => d["id"] == docenteSeleccionado)
                  ? docenteSeleccionado
                  : null,
              items: docentesDisponibles.map((docente) {
                final nombreCompleto = "${docente["nombres"]} ${docente["apellidos"]}".trim();
                return DropdownMenuItem<int>(
                  value: docente["id"],
                  child: Text(nombreCompleto),
                );
              }).toList(),
              onChanged: (value) => setState(() => docenteSeleccionado = value),
              decoration: const InputDecoration(labelText: "Docente"),
            ),
            const SizedBox(height: 20),
            if (cargando) const Center(child: CircularProgressIndicator()),
            if (mensaje != null)
              Center(
                child: Text(
                  mensaje!,
                  style: const TextStyle(color: Colors.red),
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