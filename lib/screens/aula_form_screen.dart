import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AulaFormScreen extends StatefulWidget {
  final int idSede;
  final Map<String, dynamic>? aula;
  final VoidCallback onSave;

  const AulaFormScreen({
    super.key,
    required this.idSede,
    this.aula,
    required this.onSave,
  });

  @override
  _AulaFormScreenState createState() => _AulaFormScreenState();
}

class _AulaFormScreenState extends State<AulaFormScreen> {
  final _apiService = ApiService();
  final _nombreController = TextEditingController();
  final _numeroController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool cargando = false;
  String? mensaje;

  @override
  void initState() {
    super.initState();
    if (widget.aula != null) {
      _nombreController.text = widget.aula!["nombre"] ?? "";
      _numeroController.text = widget.aula!["numero"] ?? "";
      _capacidadController.text = widget.aula!["capacidad"]?.toString() ?? "";
      _descripcionController.text = widget.aula!["descripcion"] ?? "";
    }
  }

  Future<void> _guardar() async {
    setState(() => cargando = true);

    final datos = {
      "nombre": _nombreController.text.trim(),
      "numero": _numeroController.text.trim(),
      "capacidad": int.tryParse(_capacidadController.text) ?? 0,
      "descripcion": _descripcionController.text.trim(),
      "id_sede": widget.idSede, // ✅ importante para que el backend acepte
    };

    bool success;
    if (widget.aula == null) {
      success = await _apiService.crearAula(datos);
    } else {
      success = await _apiService.actualizarAula(widget.aula!["id"], datos);
    }

    setState(() {
      cargando = false;
      mensaje = success ? "Guardado con éxito" : "Error al guardar";
    });

    if (success) {
      widget.onSave(); // ✅ refresca la tabla en AulasScreen
      Navigator.pop(context); // ✅ cierra el diálogo
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.aula == null ? "Nueva Aula" : "Editar Aula"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: _numeroController, decoration: const InputDecoration(labelText: "Número")),
            TextField(controller: _capacidadController, decoration: const InputDecoration(labelText: "Capacidad"), keyboardType: TextInputType.number),
            TextField(controller: _descripcionController, decoration: const InputDecoration(labelText: "Descripción")),
            const SizedBox(height: 16),
            if (mensaje != null) Text(mensaje!, style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: cargando ? null : _guardar, child: const Text("Guardar")),
      ],
    );
  }
}