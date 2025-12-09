import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  Future<void> _guardarSede() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    try {
      await _apiService.crearSede({
        "nombre": nombreCtrl.text,
        "ubicacion": ubicacionCtrl.text,
      });

      Navigator.pop(context, true); // <- indica que se guardó
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al crear sede: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Sede")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ubicacionCtrl,
                decoration: const InputDecoration(labelText: "Ubicación"),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: cargando ? null : _guardarSede,
                child: cargando
                    ? const CircularProgressIndicator()
                    : const Text("Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
