import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MateriasScreen extends StatefulWidget {
  final int idSede;
  const MateriasScreen({super.key, required this.idSede});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> materias = [];
  List<dynamic> carrerasDisponibles = [];
  List<dynamic> docentesDisponibles = [];

  bool cargando = true;

  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();

  List<int> carrerasSeleccionadas = [];
  List<int> docentesSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    try {
      final materiasData =
          await _apiService.listarMateriasPorSede(widget.idSede);
      carrerasDisponibles = await _apiService.listarCarreras();
      docentesDisponibles =
          await _apiService.listarDocentesPorSede(widget.idSede);

      setState(() {
        materias = materiasData;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  // =======================
  // 🗑️ ELIMINAR
  // =======================
  Future<void> _eliminarMateria(int id) async {
    final ok = await _apiService.eliminarMateria(id);
    if (ok) _cargarTodo();
  }

  // =======================
  // 🟢 FORMULARIO
  // =======================
  void _abrirFormulario({Map<String, dynamic>? materia}) {
    if (materia != null) {
      _nombreController.text = materia["nombre"] ?? "";
      _codigoController.text = materia["codigo"] ?? "";

      // 🔥 AQUI ESTA LA CLAVE
      carrerasSeleccionadas = List<int>.from(
        (materia["carreras"] ?? []).map((c) => c["id"]),
      );

      docentesSeleccionados = List<int>.from(
        (materia["docentes"] ?? []).map((d) => d["id"]),
      );
    } else {
      _nombreController.clear();
      _codigoController.clear();
      carrerasSeleccionadas = [];
      docentesSeleccionados = [];
    }

    showDialog(
      context: context,
      builder: (_) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                  materia == null ? "Nueva Materia" : "Editar Materia"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration:
                          const InputDecoration(labelText: "Nombre"),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codigoController,
                      decoration:
                          const InputDecoration(labelText: "Código"),
                    ),

                    const SizedBox(height: 16),
                    const Text("Carreras",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _dropdownCarreras(setStateDialog),
                    _chipsCarreras(setStateDialog),

                    const SizedBox(height: 16),
                    const Text("Docentes",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _dropdownDocentes(setStateDialog),
                    _chipsDocentes(setStateDialog),
                  ],
                ),
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
                          if (carrerasSeleccionadas.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Selecciona al menos una carrera"),
                              ),
                            );
                            return;
                          }

                          final datos = {
                            "nombre": _nombreController.text.trim(),
                            "codigo": _codigoController.text.trim(),
                            "carrera_ids": carrerasSeleccionadas,
                            "docente_ids": docentesSeleccionados,
                            "sede_ids": [widget.idSede],
                          };

                          setStateDialog(() => guardando = true);

                          bool ok;
                          if (materia == null) {
                            ok = await _apiService.crearMateria(datos);
                          } else {
                            ok = await _apiService.actualizarMateria(
                                materia["id"], datos);
                          }

                          setStateDialog(() => guardando = false);

                          if (ok) {
                            _cargarTodo();
                            Navigator.pop(context);
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

  // =======================
  // DROPDOWNS + CHIPS
  // =======================
  Widget _dropdownCarreras(void Function(void Function()) setStateDialog) {
    return DropdownButtonFormField<int>(
      hint: const Text("Seleccionar carrera"),
      items: carrerasDisponibles
          .map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                value: c["id"],
                child: Text(c["nombre"]),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null && !carrerasSeleccionadas.contains(v)) {
          setStateDialog(() => carrerasSeleccionadas.add(v));
        }
      },
    );
  }

  Widget _dropdownDocentes(void Function(void Function()) setStateDialog) {
    return DropdownButtonFormField<int>(
      hint: const Text("Seleccionar docente"),
      items: docentesDisponibles
          .map<DropdownMenuItem<int>>((d) => DropdownMenuItem<int>(
                value: d["id"],
                child: Text("${d["nombres"]} ${d["apellidos"]}"),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null && !docentesSeleccionados.contains(v)) {
          setStateDialog(() => docentesSeleccionados.add(v));
        }
      },
    );
  }

  Widget _chipsCarreras(void Function(void Function()) setStateDialog) {
    return Wrap(
      spacing: 6,
      children: carrerasSeleccionadas.map((id) {
        final c =
            carrerasDisponibles.firstWhere((x) => x["id"] == id);
        return Chip(
          label: Text(c["nombre"]),
          onDeleted: () =>
              setStateDialog(() => carrerasSeleccionadas.remove(id)),
        );
      }).toList(),
    );
  }

  Widget _chipsDocentes(void Function(void Function()) setStateDialog) {
    return Wrap(
      spacing: 6,
      children: docentesSeleccionados.map((id) {
        final d =
            docentesDisponibles.firstWhere((x) => x["id"] == id);
        return Chip(
          label: Text("${d["nombres"]} ${d["apellidos"]}"),
          onDeleted: () =>
              setStateDialog(() => docentesSeleccionados.remove(id)),
        );
      }).toList(),
    );
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Materias")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Código")),
                  DataColumn(label: Text("Materia")),
                  DataColumn(label: Text("Carreras")),
                  DataColumn(label: Text("Docentes")),
                  DataColumn(label: Text("Acciones")),
                ],
                rows: materias.map((m) {
                  return DataRow(cells: [
                    DataCell(Text(m["codigo"] ?? "")),
                    DataCell(Text(m["nombre"] ?? "")),
                    DataCell(Text(
                      (m["carreras"] as List)
                          .map((c) => c["nombre"])
                          .join(", "),
                    )),
                    DataCell(Text(
                      (m["docentes"] as List)
                          .map((d) =>
                              "${d["nombres"]} ${d["apellidos"]}")
                          .join(", "),
                    )),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _abrirFormulario(materia: m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarMateria(m["id"]),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
