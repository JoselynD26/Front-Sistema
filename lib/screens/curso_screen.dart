import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import 'curso_form_screen.dart';

class CursosScreen extends StatefulWidget {
  final int idSede;
  const CursosScreen({super.key, required this.idSede});

  @override
  _CursosScreenState createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  final _apiService = ApiService();
  List<dynamic> cursos = [];
  Map<int, String> carrerasMap = {};
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCursos();
  }

  Future<void> _cargarCursos() async {
    try {
      final res = await Future.wait([
        _apiService.listarCursosPorSede(widget.idSede),
        _apiService.listarCarreras(),
      ]);
      
      final data = res[0] as List;
      final carrs = res[1] as List;

      final Map<int, String> cMap = {};
      for (var c in carrs) {
        if (c["id"] != null) cMap[c["id"]] = c["nombre"] ?? "N/A";
      }

      setState(() {
        cursos = data;
        carrerasMap = cMap;
        
        // Orden: Carrera → Nivel → Jornada (Matutina, Vespertina, Nocturna) → Paralelo → Nombre
        cursos.sort((a, b) {
          final nomCarreraA = carrerasMap[a["carrera_id"]]?.toLowerCase() ?? "";
          final nomCarreraB = carrerasMap[b["carrera_id"]]?.toLowerCase() ?? "";
          final cmpCarrera = nomCarreraA.compareTo(nomCarreraB);
          if (cmpCarrera != 0) return cmpCarrera;

          // Comparar nivel
          final nivelA = (a["nivel"] ?? "").toString().toLowerCase();
          final nivelB = (b["nivel"] ?? "").toString().toLowerCase();
          final cmpNivel = nivelA.compareTo(nivelB);
          if (cmpNivel != 0) return cmpNivel;

          // Comparar jornada con orden personalizado
          final jornadaA = (a["jornada"] ?? "").toString().toLowerCase();
          final jornadaB = (b["jornada"] ?? "").toString().toLowerCase();
          
          int getJornadaPrioridad(String jornada) {
            if (jornada.contains("matutina")) return 1;
            if (jornada.contains("vespertina")) return 2;
            if (jornada.contains("nocturna")) return 3;
            return 4; // Otras jornadas al final
          }
          
          final cmpJornada = getJornadaPrioridad(jornadaA).compareTo(getJornadaPrioridad(jornadaB));
          if (cmpJornada != 0) return cmpJornada;

          // Comparar paralelo (A, B, C, etc.)
          final paraleloA = (a["paralelo"] ?? "").toString().toLowerCase();
          final paraleloB = (b["paralelo"] ?? "").toString().toLowerCase();
          final cmpParalelo = paraleloA.compareTo(paraleloB);
          if (cmpParalelo != 0) return cmpParalelo;

          // Finalmente por nombre
          final nomA = (a["nombre"] ?? "").toString().toLowerCase();
          final nomB = (b["nombre"] ?? "").toString().toLowerCase();
          return nomA.compareTo(nomB);
        });

        cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _eliminarCurso(int id) async {
    final ok = await _apiService.eliminarCurso(id);
    if (ok) {
      _cargarCursos();
    }
  }

  void _abrirFormulario({Map<String, dynamic>? curso}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CursoFormScreen(
          idSede: widget.idSede,
          curso: curso,
        ),
      ),
    );

    if (result == true) {
      _cargarCursos();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar cursos por carrera
    Map<String, List<dynamic>> cursosPorCarrera = {};
    for (var curso in cursos) {
      final carreraNombre = carrerasMap[curso["carrera_id"]] ?? "Sin Carrera";
      if (!cursosPorCarrera.containsKey(carreraNombre)) {
        cursosPorCarrera[carreraNombre] = [];
      }
      cursosPorCarrera[carreraNombre]!.add(curso);
    }

    // Ordenar las carreras alfabéticamente
    final carrerasOrdenadas = cursosPorCarrera.keys.toList()..sort();

    return AdminCRUDLayout(
      title: "Cursos",
      subtitle: "Gestión de paralelos y niveles",
      idSede: widget.idSede,
      onAdd: () => _abrirFormulario(),
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : cursos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "No hay cursos registrados",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: carrerasOrdenadas.length,
                  itemBuilder: (context, index) {
                    final carreraNombre = carrerasOrdenadas[index];
                    final cursosDeCarrera = cursosPorCarrera[carreraNombre]!;

                    // Agrupar cursos de esta carrera por nivel
                    Map<String, List<dynamic>> cursosPorNivel = {};
                    for (var curso in cursosDeCarrera) {
                      final nivel = curso["nivel"] ?? "Sin Nivel";
                      if (!cursosPorNivel.containsKey(nivel)) {
                        cursosPorNivel[nivel] = [];
                      }
                      cursosPorNivel[nivel]!.add(curso);
                    }

                    // Ordenar niveles (1ro, 2do, 3ro, etc.)
                    final nivelesOrdenados = cursosPorNivel.keys.toList()..sort();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.school, color: Colors.indigo, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    carreraNombre,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  Text(
                                    "${cursosDeCarrera.length} curso${cursosDeCarrera.length != 1 ? 's' : ''}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: nivelesOrdenados.map((nivel) {
                          final cursosDelNivel = cursosPorNivel[nivel]!;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header del nivel
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.grade, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        nivel,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "(${cursosDelNivel.length} paralelo${cursosDelNivel.length != 1 ? 's' : ''})",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Tabla de cursos del nivel
                                AdminTable(
                                  isLoading: false,
                                  columns: const [
                                    DataColumn(label: Text("Nombre")),
                                    DataColumn(label: Text("Paralelo")),
                                    DataColumn(label: Text("Jornada")),
                                    DataColumn(label: Text("Acciones")),
                                  ],
                                  rows: cursosDelNivel.map((curso) {
                                    return DataRow(cells: [
                                      DataCell(Text(curso["nombre"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(curso["paralelo"] ?? "")),
                                      DataCell(Text(curso["jornada"] ?? "")),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                            onPressed: () => _abrirFormulario(curso: curso),
                                            tooltip: "Editar",
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _eliminarCurso(curso["id"]),
                                            tooltip: "Eliminar",
                                          ),
                                        ],
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
