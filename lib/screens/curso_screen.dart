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

  final _nivelController = TextEditingController();
  final _paraleloController = TextEditingController();
  final _jornadaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarCursos();
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
      _nivelController.text = curso["nivel"] ?? "";
      _paraleloController.text = curso["paralelo"] ?? "";
      _jornadaController.text = curso["jornada"] ?? "";
    } else {
      _nivelController.clear();
      _paraleloController.clear();
      _jornadaController.clear();
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
                      controller: _nivelController,
                      decoration: const InputDecoration(labelText: "Nivel"),
                    ),
                    TextField(
                      controller: _paraleloController,
                      decoration: const InputDecoration(labelText: "Paralelo"),
                    ),
                    DropdownButtonFormField<String>(
                      value: _jornadaController.text.isNotEmpty
                          ? _jornadaController.text
                          : null,
                      items: const [
                        DropdownMenuItem(value: "Matutina", child: Text("Matutina")),
                        DropdownMenuItem(value: "Vespertina", child: Text("Vespertina")),
                        DropdownMenuItem(value: "Nocturna", child: Text("Nocturna")),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          _jornadaController.text = value ?? "";
                        });
                      },
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
                          final datos = {
                            "nivel": _nivelController.text.trim(),
                            "paralelo": _paraleloController.text.trim(),
                            "jornada": _jornadaController.text.trim(),
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
      appBar: AppBar(title: const Text("Cursos")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : DataTable(
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Nivel")),
                DataColumn(label: Text("Paralelo")),
                DataColumn(label: Text("Jornada")),
                DataColumn(label: Text("Acciones")),
              ],
              rows: cursos.map((curso) {
                return DataRow(cells: [
                  DataCell(Text(curso["id"].toString())),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}