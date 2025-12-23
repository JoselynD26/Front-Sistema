import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CursosScreen extends StatefulWidget {
  final int idSede;
  const CursosScreen({super.key, required this.idSede});

  @override
  _CursosScreenState createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  final _apiService = ApiService();
  List<dynamic> cursos = [];
  bool cargando = true;

  final _nombreController = TextEditingController();
  final _nivelController = TextEditingController();
  final _paraleloController = TextEditingController();
  String _jornadaSeleccionada = "Matutina";
  int? _carreraSeleccionada;
  List<dynamic> carrerasDisponibles = [];

  @override
  void initState() {
    super.initState();
    _cargarCursos();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      final data = await _apiService.listarCarreras();
      setState(() {
        carrerasDisponibles = data.where((c) => 
          (c["sede_ids"] as List).contains(widget.idSede)
        ).toList();
      });
    } catch (e) {
      print("Error cargando carreras: $e");
    }
  }

  Future<void> _cargarCursos() async {
    try {
      final data = await _apiService.listarCursosPorSede(widget.idSede);
      setState(() {
        cursos = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar cursos")),
      );
    }
  }

  Future<void> _eliminarCurso(int id) async {
    final ok = await _apiService.eliminarCurso(id);
    if (ok) {
      _cargarCursos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Curso eliminado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar curso")),
      );
    }
  }

  void _abrirFormulario({Map<String, dynamic>? curso}) {
    if (curso != null) {
      _nombreController.text = curso["nombre"] ?? "";
      _nivelController.text = curso["nivel"] ?? "";
      _paraleloController.text = curso["paralelo"] ?? "";
      _jornadaSeleccionada = curso["jornada"] ?? "Matutina";
      _carreraSeleccionada = curso["carrera_id"];
    } else {
      _nombreController.clear();
      _nivelController.clear();
      _paraleloController.clear();
      _jornadaSeleccionada = "Matutina";
      _carreraSeleccionada = null;
    }

    showDialog(
      context: context,
      builder: (_) {
        bool guardando = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(curso == null ? "Nuevo Curso" : "Editar Curso"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: "Nombre del Curso"),
                    ),
                    TextField(
                      controller: _nivelController,
                      decoration: const InputDecoration(labelText: "Nivel"),
                    ),
                    TextField(
                      controller: _paraleloController,
                      decoration: const InputDecoration(labelText: "Paralelo"),
                    ),
                    DropdownButtonFormField<int>(
                      value: _carreraSeleccionada,
                      items: carrerasDisponibles.map((carrera) => 
                        DropdownMenuItem<int>(
                          value: carrera["id"],
                          child: Text(carrera["nombre"]),
                        )
                      ).toList(),
                      onChanged: (value) => setStateDialog(() => _carreraSeleccionada = value),
                      decoration: const InputDecoration(labelText: "Carrera"),
                    ),
                    DropdownButtonFormField<String>(
                      value: _jornadaSeleccionada,
                      items: const [
                        DropdownMenuItem(value: "Matutina", child: Text("Matutina")),
                        DropdownMenuItem(value: "Vespertina", child: Text("Vespertina")),
                        DropdownMenuItem(value: "Nocturna", child: Text("Nocturna")),
                      ],
                      onChanged: (value) => setStateDialog(() => _jornadaSeleccionada = value!),
                      decoration: const InputDecoration(labelText: "Jornada"),
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
                          if (_nombreController.text.trim().isEmpty || _carreraSeleccionada == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Completa todos los campos obligatorios")),
                            );
                            return;
                          }

                          final datos = {
                            "nombre": _nombreController.text.trim(),
                            "nivel": _nivelController.text.trim(),
                            "paralelo": _paraleloController.text.trim(),
                            "carrera_id": _carreraSeleccionada,
                            "jornada": _jornadaSeleccionada,
                            "id_sede": widget.idSede,
                          };

                          setStateDialog(() => guardando = true);

                          bool success;
                          if (curso == null) {
                            success = await _apiService.crearCurso(datos);
                          } else {
                            success = await _apiService.actualizarCurso(curso["id"], datos);
                          }

                          setStateDialog(() => guardando = false);

                          if (success) {
                            _cargarCursos();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al guardar curso")),
                            );
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Guardar"),
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
      appBar: AppBar(title: const Text("Cursos")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Nombre")),
                  DataColumn(label: Text("Nivel")),
                  DataColumn(label: Text("Paralelo")),
                  DataColumn(label: Text("Jornada")),
                  DataColumn(label: Text("Acciones")),
                ],
                rows: cursos.map((curso) {
                  return DataRow(cells: [
                    DataCell(Text(curso["id"].toString())),
                    DataCell(Text(curso["nombre"] ?? "")),
                    DataCell(Text(curso["nivel"] ?? "")),
                    DataCell(Text(curso["paralelo"] ?? "")),
                    DataCell(Text(curso["jornada"] ?? "")),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _abrirFormulario(curso: curso),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarCurso(curso["id"]),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}