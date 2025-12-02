import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SalaForm extends StatefulWidget {
  final Map? sala;
  final int idSede;
  final Function? onSave;

  const SalaForm({
    super.key,
    this.sala,
    required this.idSede,
    this.onSave,
  });

  @override
  _SalaFormState createState() => _SalaFormState();
}

class _SalaFormState extends State<SalaForm> {
  final _nombreController = TextEditingController();
  final apiService = ApiService();
  bool cargando = false;
  String? mensaje;

  @override
  void initState() {
    super.initState();
    if (widget.sala != null) {
      _nombreController.text = widget.sala!['nombre'];
    }
  }

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty) {
      setState(() => mensaje = "El nombre es obligatorio");
      return;
    }

    setState(() => cargando = true);

    final datos = {
      "nombre": _nombreController.text.trim(),
      "sede_id": widget.idSede,
    };

    bool success;
    if (widget.sala == null) {
      success = await apiService.crearSala(datos);
    } else {
      success = await apiService.actualizarSala(widget.sala!['id'], datos);
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
        title: Text(widget.sala == null ? "Nueva Sala" : "Editar Sala"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Sede ID: ${widget.idSede}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: "Nombre de la Sala"),
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