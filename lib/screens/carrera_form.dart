import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CarrerasScreen extends StatefulWidget {
  final int idSede;
  const CarrerasScreen({super.key, required this.idSede});

  @override
  _CarrerasScreenState createState() => _CarrerasScreenState();
}

class _CarrerasScreenState extends State<CarrerasScreen> {
  final _apiService = ApiService();
  List<dynamic> carreras = [];
  bool cargando = true;

  final _nombreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      // ✅ si tu backend ya tiene endpoint por sede, úsalo:
      // final data = await _apiService.listarCarrerasPorSede(widget.idSede);
      final data = await _apiService.listarCarreras();
      setState(() {
        // filtrar por sede si backend devuelve todas
        carreras = data.where((c) => c["id_sede"] == widget.idSede).toList();
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar carreras")),
      );
    }
  }

  Future<void> _eliminarCarrera(int id) async {
    final ok = await _apiService.eliminarCarrera(id);
    if (ok) {
      _cargarCarreras();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carrera eliminada")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar carrera")),
      );
    }
  }

  void _abrirFormulario({Map<String, dynamic>? carrera}) {
    if (carrera != null) {
      _nombreController.text = carrera["nombre"] ?? "";
    } else {
      _nombreController.clear();
    }

    showDialog(
      context: context,
      builder: (_) {
        bool guardando = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(carrera == null ? "Nueva Carrera" : "Editar Carrera"),
              content: TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final datos = {
                            "nombre": _nombreController.text.trim(),
                            "id_sede": widget.idSede, // ✅ importante
                          };

                          setStateDialog(() => guardando = true);

                          bool success;
                          if (carrera == null) {
                            success = await _apiService.crearCarrera(datos);
                          } else {
                            success = await _apiService.actualizarCarrera(carrera["id"], datos);
                          }

                          setStateDialog(() => guardando = false);

                          if (success) {
                            _cargarCarreras();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al guardar carrera")),
                            );
                          }
                        },
                  child: const Text("Guardar"),
                ),
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
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : DataTable(
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Nombre")),
                DataColumn(label: Text("Acciones")),
              ],
              rows: carreras.map((carrera) {
                return DataRow(cells: [
                  DataCell(Text(carrera["id"].toString())),
                  DataCell(Text(carrera["nombre"] ?? "")),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}