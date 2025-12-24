import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CarrerasScreen extends StatefulWidget {
  final int idSede;
  const CarrerasScreen({super.key, required this.idSede});

  @override
  State<CarrerasScreen> createState() => _CarrerasScreenState();
}

class _CarrerasScreenState extends State<CarrerasScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> carreras = [];
  List<dynamic> sedes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSedes();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      final data = await _apiService.listarCarreras();
      setState(() {
        carreras = data
            .where((c) =>
                (c["sede_ids"] ?? []).contains(widget.idSede))
            .toList();
        cargando = false;
      });
    } catch (_) {
      setState(() => cargando = false);
    }
  }

  Future<void> _cargarSedes() async {
    sedes = await _apiService.listarSedes();
    setState(() {});
  }

  Future<void> _eliminarCarrera(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar carrera"),
        content: const Text("¿Estás seguro de eliminar esta carrera?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _apiService.eliminarCarrera(id);
      _cargarCarreras();
    }
  }

  void _abrirFormulario({Map<String, dynamic>? carrera}) {
    final nombreController =
        TextEditingController(text: carrera?["nombre"] ?? "");
    final codigoController =
        TextEditingController(text: carrera?["codigo"] ?? "");

    List<int> sedesSeleccionadas =
        List<int>.from(carrera?["sede_ids"] ?? [widget.idSede]);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(carrera == null ? "Nueva Carrera" : "Editar Carrera"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: "Código",
                    prefixIcon: Icon(Icons.code),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sedes",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: sedes.map((s) {
                    final id = s["id"];
                    return FilterChip(
                      label: Text(s["nombre"]),
                      selected: sedesSeleccionadas.contains(id),
                      onSelected: (v) {
                        setStateDialog(() {
                          v
                              ? sedesSeleccionadas.add(id)
                              : sedesSeleccionadas.remove(id);
                        });
                      },
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Guardar"),
              onPressed: () async {
                final body = {
                  "nombre": nombreController.text.trim(),
                  "codigo": codigoController.text.trim().isEmpty
                      ? "AUTO"
                      : codigoController.text.trim(),
                  "sede_ids": sedesSeleccionadas,
                };

                carrera == null
                    ? await _apiService.crearCarrera(body)
                    : await _apiService.actualizarCarrera(
                        carrera["id"], body);

                Navigator.pop(context);
                _cargarCarreras();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carreras"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Nueva Carrera"),
        onPressed: () => _abrirFormulario(),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : carreras.isEmpty
              ? const Center(child: Text("No hay carreras registradas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: carreras.length,
                  itemBuilder: (context, i) {
                    final c = carreras[i];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(c["nombre"][0]),
                        ),
                        title: Text(
                          c["nombre"],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Código: ${c["codigo"] ?? "AUTO"}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.orange),
                              onPressed: () =>
                                  _abrirFormulario(carrera: c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  _eliminarCarrera(c["id"]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
