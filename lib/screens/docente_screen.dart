import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DocentesScreen extends StatefulWidget {
  final int idSede;
  const DocentesScreen({super.key, required this.idSede});

  @override
  _DocentesScreenState createState() => _DocentesScreenState();
}

class _DocentesScreenState extends State<DocentesScreen> {
  final _apiService = ApiService();
  List<dynamic> docentes = [];
  bool cargando = true;

  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _nombresController = TextEditingController();
  String? _regimen;
  String? _observacion;

  @override
  void initState() {
    super.initState();
    _cargarDocentes();
  }

  Future<void> _cargarDocentes() async {
    try {
      final data = await _apiService.listarDocentesPorSede(widget.idSede);
      setState(() {
        docentes = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar docentes")),
      );
    }
  }

  Future<void> _eliminarDocente(int id) async {
    final ok = await _apiService.eliminarDocente(id);
    if (ok) {
      _cargarDocentes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Docente eliminado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar docente")),
      );
    }
  }

  void _abrirFormulario({Map<String, dynamic>? docente}) {
    if (docente != null) {
      _cedulaController.text = docente["cedula"] ?? "";
      _correoController.text = docente["correo"] ?? "";
      _apellidosController.text = docente["apellidos"] ?? "";
      _nombresController.text = docente["nombres"] ?? "";
      _regimen = docente["regimen"];
      _observacion = docente["observacion"];
    } else {
      _cedulaController.clear();
      _correoController.clear();
      _apellidosController.clear();
      _nombresController.clear();
      _regimen = null;
      _observacion = null;
    }

    showDialog(
      context: context,
      builder: (_) {
        bool guardando = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(docente == null ? "Nuevo Docente" : "Editar Docente"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _cedulaController,
                      decoration: const InputDecoration(labelText: "Cédula"),
                    ),
                    TextField(
                      controller: _correoController,
                      decoration: const InputDecoration(labelText: "Correo"),
                    ),
                    TextField(
                      controller: _apellidosController,
                      decoration: const InputDecoration(labelText: "Apellidos"),
                    ),
                    TextField(
                      controller: _nombresController,
                      decoration: const InputDecoration(labelText: "Nombres"),
                    ),
                    DropdownButtonFormField<String>(
                      value: _regimen,
                      items: const [
                        DropdownMenuItem(value: "LOES", child: Text("LOES")),
                        DropdownMenuItem(
                            value: "Codigo de trabajo",
                            child: Text("Código de trabajo")),
                      ],
                      onChanged: (val) => setStateDialog(() => _regimen = val),
                      decoration: const InputDecoration(labelText: "Régimen"),
                    ),
                    DropdownButtonFormField<String>(
                      value: _observacion,
                      items: const [
                        DropdownMenuItem(
                            value: "Medio tiempo", child: Text("Medio tiempo")),
                        DropdownMenuItem(
                            value: "Tiempo completo",
                            child: Text("Tiempo completo")),
                      ],
                      onChanged: (val) =>
                          setStateDialog(() => _observacion = val),
                      decoration:
                          const InputDecoration(labelText: "Observación"),
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
                            "cedula": _cedulaController.text.trim(),
                            "correo": _correoController.text.trim(),
                            "apellidos": _apellidosController.text.trim(),
                            "nombres": _nombresController.text.trim(),
                            "regimen": _regimen,
                            "observacion": _observacion,
                            "sede_id": widget.idSede, // ✅ importante
                          };

                          setStateDialog(() => guardando = true);

                          bool success;
                          if (docente == null) {
                            success = await _apiService.crearDocente(datos);
                          } else {
                            success = await _apiService.actualizarDocente(
                                docente["id"], datos);
                          }

                          setStateDialog(() => guardando = false);

                          if (success) {
                            _cargarDocentes();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Error al guardar docente")),
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
      appBar: AppBar(title: const Text("Docentes")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : DataTable(
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Cédula")),
                DataColumn(label: Text("Nombres")),
                DataColumn(label: Text("Apellidos")),
                DataColumn(label: Text("Correo")),
                DataColumn(label: Text("Acciones")),
              ],
              rows: docentes.map((docente) {
                return DataRow(cells: [
                  DataCell(Text(docente["id"].toString())),
                  DataCell(Text(docente["cedula"] ?? "")),
                  DataCell(Text(docente["nombres"] ?? "")),
                  DataCell(Text(docente["apellidos"] ?? "")),
                  DataCell(Text(docente["correo"] ?? "")),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _abrirFormulario(docente: docente),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarDocente(docente["id"]),
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