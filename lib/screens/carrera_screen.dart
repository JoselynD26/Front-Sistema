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

  final TextEditingController _nombreController = TextEditingController();
  List<int> sedeSeleccionadas = [];

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
                (c["sede_ids"] ?? []).contains(widget.idSede)) // filtrar por sede actual
            .toList();
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error cargando carreras")));
    }
  }

  Future<void> _cargarSedes() async {
    try {
      sedes = await _apiService.listarSedes();
      setState(() {});
    } catch (e) {
      print("Error cargando sedes: $e");
    }
  }

  Future<void> _eliminarCarrera(int id) async {
    final ok = await _apiService.eliminarCarrera(id);
    if (ok) {
      _cargarCarreras();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Carrera eliminada")));
    }
  }

  void _abrirFormulario({Map<String, dynamic>? carrera}) {
    if (carrera != null) {
      _nombreController.text = carrera["nombre"];
      sedeSeleccionadas = List<int>.from(carrera["sede_ids"]);
    } else {
      _nombreController.clear();
      sedeSeleccionadas = [widget.idSede];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(carrera == null ? "Nueva Carrera" : "Editar Carrera"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: "Nombre"),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: sedes.map((s) {
                      final id = s["id"];
                      final seleccionado = sedeSeleccionadas.contains(id);
                      return FilterChip(
                        label: Text(s["nombre"]),
                        selected: seleccionado,
                        onSelected: (v) {
                          setStateDialog(() {
                            if (v) {
                              sedeSeleccionadas.add(id);
                            } else {
                              sedeSeleccionadas.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    final body = {
                      "nombre": _nombreController.text.trim(),
                      "sede_ids": sedeSeleccionadas,
                    };

                    bool ok;
                    if (carrera == null) {
                      ok = await _apiService.crearCarrera(body);
                    } else {
                      ok = await _apiService.actualizarCarrera(carrera["id"], body);
                    }

                    if (ok) {
                      Navigator.pop(context);
                      _cargarCarreras();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error al guardar")),
                      );
                    }
                  },
                  child: const Text("Guardar"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carreras")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Nombre")),
                  DataColumn(label: Text("Sedes")),
                  DataColumn(label: Text("Acciones")),
                ],
                rows: carreras.map((carrera) {
                  return DataRow(cells: [
                    DataCell(Text(carrera["id"].toString())),
                    DataCell(Text(carrera["nombre"])),
                    DataCell(Text((carrera["sede_ids"] as List).join(", "))),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _abrirFormulario(carrera: carrera),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarCarrera(carrera["id"]),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
