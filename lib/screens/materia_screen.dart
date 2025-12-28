import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import 'materia_form_screen.dart';

class MateriasScreen extends StatefulWidget {
  final int idSede;
  const MateriasScreen({super.key, required this.idSede});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> materias = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    try {
      final data = await _apiService.listarMateriasPorSede(widget.idSede);
      setState(() {
        materias = data;
        cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _eliminarMateria(int id) async {
    final ok = await _apiService.eliminarMateria(id);
    if (ok) _cargarTodo();
  }

  void _abrirFormulario({Map<String, dynamic>? materia}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MateriaFormScreen(
          idSede: widget.idSede,
          materia: materia,
        ),
      ),
    );

    if (result == true) {
      _cargarTodo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Materias",
      subtitle: "Asignación de materias, carreras y docentes",
      idSede: widget.idSede,
      onAdd: () => _abrirFormulario(),

      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildGroupedList(),
    );
  }

  Widget _buildGroupedList() {
    // 1. Agrupar materias por carrera
    Map<String, List<dynamic>> agrupadas = {};
    
    for (var m in materias) {
      List carreras = m["carreras"] ?? [];
      if (carreras.isEmpty) {
        agrupadas.putIfAbsent("Sin Carrera Asignada", () => []).add(m);
      } else {
        for (var c in carreras) {
          String nombreCarrera = c["nombre"];
          agrupadas.putIfAbsent(nombreCarrera, () => []).add(m);
        }
      }
    }

    if (agrupadas.isEmpty) {
       return const Center(child: Text("No hay materias registradas."));
    }

    // 2. Ordenar claves (Carreras) alfabéticamente
    final sortedKeys = agrupadas.keys.toList()..sort();

    // 3. Construir lista de expansiones
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: sortedKeys.map((carrera) {
        final listaMaterias = agrupadas[carrera]!;
        
        // Ordenar materias alfabéticamente dentro de la carrera
        listaMaterias.sort((a, b) => (a["nombre"] ?? "").toString().compareTo(b["nombre"] ?? ""));

        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              carrera,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            children: [
              AdminTable(
                isLoading: false,
                columns: const [
                  DataColumn(label: Text("Materia")),
                  // DataColumn(label: Text("Carreras")), // Ya no es necesario mostrar carreras aquí si clasificamos
                  DataColumn(label: Text("Docentes")),
                  DataColumn(label: Text("Acciones")),
                ],
                rows: listaMaterias.map((m) {
                  return DataRow(cells: [
                     DataCell(Text(m["nombre"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold))),
                     // DataCell(...), // Omitimos carrera
                     DataCell(SizedBox(
                      width: 250,
                      child: Text(
                        (m["docentes"] as List).map((d) => "${d["apellidos"]} ${d["nombres"]}").join(", "),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () => _abrirFormulario(materia: m),
                          tooltip: "Editar",
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _eliminarMateria(m["id"]),
                          tooltip: "Eliminar",
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
