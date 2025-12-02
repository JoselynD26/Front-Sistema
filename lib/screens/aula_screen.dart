import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AulasScreen extends StatefulWidget {
  final int idSede;
  const AulasScreen({super.key, required this.idSede});

  @override
  _AulasScreenState createState() => _AulasScreenState();
}

class _AulasScreenState extends State<AulasScreen> {
  final _apiService = ApiService();
  List<dynamic> aulas = [];
  bool cargando = true;

  // Controladores del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _capacidadController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarAulas();
  }

  Future<void> _cargarAulas() async {
    try {
      final data = await _apiService.listarAulasPorSede(widget.idSede);
      setState(() {
        aulas = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar aulas")),
      );
    }
  }

  Future<void> _eliminarAula(int id) async {
    final ok = await _apiService.eliminarAula(id);
    if (ok) {
      _cargarAulas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aula eliminada")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar aula")),
      );
    }
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar Aula"),
        content: const Text("¿Estás seguro de eliminar esta aula?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarAula(id);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? aula}) {
    // Precargar datos si es edición
    if (aula != null) {
      _nombreController.text = aula["nombre"] ?? "";
      _numeroController.text = aula["numero"] ?? "";
      _capacidadController.text = aula["capacidad"]?.toString() ?? "";
      _descripcionController.text = aula["descripcion"] ?? "";
    } else {
      _nombreController.clear();
      _numeroController.clear();
      _capacidadController.clear();
      _descripcionController.clear();
    }

    showDialog(
      context: context,
      builder: (_) {
        bool guardando = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(aula == null ? "Nueva Aula" : "Editar Aula"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: "Nombre"),
                    ),
                    TextField(
                      controller: _numeroController,
                      decoration: const InputDecoration(labelText: "Número"),
                    ),
                    TextField(
                      controller: _capacidadController,
                      decoration: const InputDecoration(labelText: "Capacidad"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(labelText: "Descripción"),
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
                          final nombre = _nombreController.text.trim();
                          final numero = _numeroController.text.trim();
                          final capacidadText = _capacidadController.text.trim();

                          if (nombre.isEmpty || numero.isEmpty || capacidadText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Completa todos los campos")),
                            );
                            return;
                          }

                          final capacidad = int.tryParse(capacidadText);
                          if (capacidad == null || capacidad <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Capacidad debe ser un número válido")),
                            );
                            return;
                          }

                          setStateDialog(() => guardando = true);

                          final datos = {
                            "nombre": nombre,
                            "numero": numero,
                            "capacidad": capacidad,
                            "descripcion": _descripcionController.text.trim(),
                            "id_sede": widget.idSede,
                          };

                          bool success;
                          if (aula == null) {
                            success = await _apiService.crearAula(datos);
                          } else {
                            success = await _apiService.actualizarAula(aula["id"], datos);
                          }

                          setStateDialog(() => guardando = false);

                          if (success) {
                            _cargarAulas();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al guardar aula")),
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
      appBar: AppBar(title: const Text("Aulas")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Número")),
                  DataColumn(label: Text("Nombre")),
                  DataColumn(label: Text("Capacidad")),
                  DataColumn(label: Text("Descripción")),
                  DataColumn(label: Text("Acciones")),
                ],
                rows: aulas.map((aula) {
                  return DataRow(cells: [
                    DataCell(Text(aula["id"].toString())),
                    DataCell(Text(aula["numero"] ?? "")),
                    DataCell(Text(aula["nombre"] ?? "")),
                    DataCell(Text(aula["capacidad"].toString())),
                    DataCell(Text(aula["descripcion"] ?? "")),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _abrirFormulario(aula: aula),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmarEliminar(aula["id"]),
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue, // ✅ visible
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}