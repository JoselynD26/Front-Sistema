import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import '../widgets/custom_dialog.dart';
import 'materia_form_screen.dart';
import 'materia_excel_import_screen.dart';

class MateriasScreen extends StatefulWidget {
  final int idSede;
  const MateriasScreen({super.key, required this.idSede});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> materias = [];
  List<dynamic> filteredMaterias = [];
  bool cargando = true;
  final TextEditingController _searchController = TextEditingController();

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
        filteredMaterias = data;
        cargando = false;
      });
      _filtrarMaterias();
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _eliminarMateria(int id) async {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: "Eliminar Materia",
        description: "¿Estás seguro de eliminar esta materia? Esta acción no se puede deshacer.",
        type: DialogType.warning,
        confirmText: "Eliminar",
        showCancel: true,
        onConfirm: () async {
          Navigator.pop(dialogContext); // Close confirmation

          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (loadingContext) => const CustomDialog(
              title: "Eliminando...",
              description: "Por favor espera",
              type: DialogType.info,
              isLoading: true,
            ),
          );

          final ok = await _apiService.eliminarMateria(id).catchError((_) => false);
          
          if (mounted) {
            Navigator.pop(context); // Close loading

            if (ok) {
              _cargarTodo();
              showDialog(
                context: context,
                builder: (successContext) => CustomDialog(
                  title: "¡Éxito!",
                  description: "La materia ha sido eliminada correctamente.",
                  type: DialogType.success,
                  confirmText: "Aceptar",
                  onConfirm: () => Navigator.pop(successContext),
                ),
              );
            } else {
              showDialog(
                context: context,
                builder: (errorContext) => const CustomDialog(
                  title: "Error",
                  description: "No se pudo eliminar la materia.",
                  type: DialogType.error,
                  confirmText: "Aceptar",
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _filtrarMaterias() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => filteredMaterias = List.from(materias));
      return;
    }

    setState(() {
      filteredMaterias = materias.where((m) {
        final nombreMateria = (m["nombre"] ?? "").toString().toLowerCase();
        
        // Buscar en docentes asignados
        bool matchDocente = false;
        if (m["docentes"] != null && m["docentes"] is List) {
          for (var d in m["docentes"]) {
            final nombreCompleto = "${d["nombres"]} ${d["apellidos"]}".toLowerCase();
            if (nombreCompleto.contains(query)) {
              matchDocente = true;
              break;
            }
          }
        }

        return nombreMateria.contains(query) || matchDocente;
      }).toList();
    });
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
      filters: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _filtrarMaterias(),
            decoration: InputDecoration(
              hintText: "Buscar por materia o profesor...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MateriaExcelImportScreen(idSede: widget.idSede)),
            );
            _cargarTodo();
          },
          icon: const Icon(Icons.upload_file),
          label: const Text("Importar Excel"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFEC4899),
            side: const BorderSide(color: Color(0xFFEC4899)),
          ),
        ),
      ],
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildGroupedList(),
    );
  }

  Widget _buildGroupedList() {
    // 1. Agrupar materias (filtradas) por carrera
    Map<String, List<dynamic>> agrupadas = {};
    
    for (var m in filteredMaterias) {
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
                     DataCell(Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: (m["docentes"] as List).map((d) => Text(
                          "- ${d["apellidos"]} ${d["nombres"]}",
                          style: const TextStyle(fontSize: 13),
                        )).toList(),
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
