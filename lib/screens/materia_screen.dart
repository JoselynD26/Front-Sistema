import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MateriasScreen extends StatefulWidget {
  final int idSede;
  const MateriasScreen({super.key, required this.idSede});

  @override
  _MateriasScreenState createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  final _apiService = ApiService();

  List<dynamic> materias = [];
  bool cargando = true;

  final _nombreController = TextEditingController();

  List<dynamic> carrerasDisponibles = [];
  List<dynamic> sedesDisponibles = [];
  List<dynamic> docentesDisponibles = [];

  List<int> carrerasSeleccionadas = [];
  List<int> sedesSeleccionadas = [];
  List<int> docentesSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _cargarMaterias();
    _cargarOpciones();
  }

  Future<void> _cargarMaterias() async {
    try {
      final data = await _apiService.listarMateriasPorSede(widget.idSede);
      setState(() {
        materias = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar materias")),
      );
    }
  }

  Future<void> _cargarOpciones() async {
    carrerasDisponibles = await _apiService.listarCarreras();
    sedesDisponibles = await _apiService.listarSedes();
    docentesDisponibles = await _apiService.listarDocentesPorSede(widget.idSede);
    setState(() {});
  }

  Future<void> _eliminarMateria(int id) async {
    final ok = await _apiService.eliminarMateria(id);
    if (ok) {
      _cargarMaterias();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Materia eliminada")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error al eliminar")));
    }
  }

  void _abrirFormulario({Map<String, dynamic>? materia}) {
    if (materia != null) {
      _nombreController.text = materia["nombre"] ?? "";
      carrerasSeleccionadas = List<int>.from(materia["carrera_ids"] ?? []);
      sedesSeleccionadas = List<int>.from(materia["sede_ids"] ?? []);
      docentesSeleccionados = List<int>.from(materia["docente_ids"] ?? []);
    } else {
      _nombreController.clear();
      carrerasSeleccionadas = [];
      sedesSeleccionadas = [widget.idSede];
      docentesSeleccionados = [];
    }

    showDialog(
      context: context,
      builder: (_) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(materia == null ? "Nueva Materia" : "Editar Materia"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: "Nombre"),
                    ),

                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Carreras",
                      carrerasDisponibles,
                      carrerasSeleccionadas,
                      setStateDialog,
                    ),
                    _buildChips(
                      carrerasDisponibles,
                      carrerasSeleccionadas,
                      setStateDialog,
                    ),

                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Sedes",
                      sedesDisponibles,
                      sedesSeleccionadas,
                      setStateDialog,
                    ),
                    _buildChips(
                      sedesDisponibles,
                      sedesSeleccionadas,
                      setStateDialog,
                    ),

                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Docentes",
                      docentesDisponibles,
                      docentesSeleccionados,
                      setStateDialog,
                    ),
                    _buildChips(
                      docentesDisponibles,
                      docentesSeleccionados,
                      setStateDialog,
                    ),
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
                          final datos = {
                            "nombre": _nombreController.text.trim(),
                            "carrera_ids": carrerasSeleccionadas,
                            "sede_ids": sedesSeleccionadas,
                            "docente_ids": docentesSeleccionados,
                          };

                          setStateDialog(() => guardando = true);

                          bool success;
                          if (materia == null) {
                            success = await _apiService.crearMateria(datos);
                          } else {
                            success = await _apiService.actualizarMateria(
                                materia["id"], datos);
                          }

                          setStateDialog(() => guardando = false);

                          if (success) {
                            _cargarMaterias();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Error al guardar materia")),
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

  // -----------------------
  // COMPONENTES
  // -----------------------

  Widget _buildDropdown(
    String label,
    List<dynamic> opciones,
    List<int> seleccionados,
    void Function(void Function()) setStateDialog,
  ) {
    return DropdownButtonFormField<int>(
      value: null,
      items: opciones.map<DropdownMenuItem<int>>((o) {
        String displayText;
        if (o.containsKey("nombres") && o.containsKey("apellidos")) {
          // Es un docente
          displayText = "${o["nombres"]} ${o["apellidos"]}";
        } else {
          // Es carrera o sede
          displayText = o["nombre"] ?? "Sin nombre";
        }
        return DropdownMenuItem<int>(
          value: o["id"],
          child: Text(displayText),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null && !seleccionados.contains(value)) {
          setStateDialog(() => seleccionados.add(value));
        }
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildChips(
    List<dynamic> opciones,
    List<int> seleccionados,
    void Function(void Function()) setStateDialog,
  ) {
    return Wrap(
      spacing: 6,
      children: seleccionados.map((id) {
        final item = opciones.firstWhere(
          (o) => o["id"] == id,
          orElse: () => {"id": id, "nombre": "Desconocido"},
        );

        String displayText;
        if (item.containsKey("nombres") && item.containsKey("apellidos")) {
          // Es un docente
          displayText = "${item["nombres"]} ${item["apellidos"]}";
        } else {
          // Es carrera o sede
          displayText = item["nombre"] ?? "Sin nombre";
        }
        
        return Chip(
          label: Text(displayText),
          onDeleted: () => setStateDialog(() => seleccionados.remove(id)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Materias")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : DataTable(
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Nombre")),
                DataColumn(label: Text("Acciones")),
              ],
              rows: materias.map((materia) {
                return DataRow(cells: [
                  DataCell(Text(materia["id"].toString())),
                  DataCell(Text(materia["nombre"] ?? "")),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _abrirFormulario(materia: materia),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarMateria(materia["id"]),
                        ),
                      ],
                    ),
                  ),
                ]);
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _abrirFormulario(),
      ),
    );
  }
}
