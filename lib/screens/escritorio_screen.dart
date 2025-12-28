import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/mouse_tracker_fix.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import 'escritorio_form.dart';

class EscritoriosScreen extends StatefulWidget {
  final int idSede;
  const EscritoriosScreen({super.key, required this.idSede});

  @override
  _EscritoriosScreenState createState() => _EscritoriosScreenState();
}

class _EscritoriosScreenState extends State<EscritoriosScreen> with SafeStateMixin {
  final _apiService = ApiService();
  List<dynamic> escritorios = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEscritorios();
  }

  Future<void> _cargarEscritorios() async {
    try {
      final data = await _apiService.listarEscritoriosPorSede(widget.idSede);
      safeSetState(() {
        escritorios = data;
        cargando = false;
      });
    } catch (e) {
      safeSetState(() => cargando = false);
    }
  }

  Future<void> _eliminarEscritorio(int id) async {
    final ok = await _apiService.eliminarEscritorio(id);
    if (ok) _cargarEscritorios();
  }

  void _abrirFormulario({Map<String, dynamic>? escritorio}) {
    final codigoController = TextEditingController();
    String estado = "libre";
    String jornada = "matutina";
    int? salaSeleccionada;
    int? carreraSeleccionada;
    int? docenteSeleccionado;
    List<dynamic> salasDisponibles = [];
    List<dynamic> carrerasDisponibles = [];
    List<dynamic> docentesDisponibles = [];

    if (escritorio != null) {
      codigoController.text = escritorio["codigo"];
      estado = escritorio["estado"];
      jornada = escritorio["jornada"];
      salaSeleccionada = escritorio["sala_id"];
      carreraSeleccionada = escritorio["carrera_id"];
      docenteSeleccionado = escritorio["docente_id"];
    }

    showDialog(
      context: context,
      builder: (_) {
        bool guardando = false;
        bool cargandoDatos = true;
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (cargandoDatos) {
              _cargarDatosFormulario().then((datos) {
                setStateDialog(() {
                  salasDisponibles = datos['salas'] ?? [];
                  carrerasDisponibles = datos['carreras'] ?? [];
                  docentesDisponibles = datos['docentes'] ?? [];
                  cargandoDatos = false;
                });
              });
            }

            return AlertDialog(
              title: Text(escritorio == null ? "Nuevo Escritorio" : "Editar Escritorio"),
              content: cargandoDatos
                  ? const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: codigoController,
                            decoration: const InputDecoration(labelText: "Código"),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: estado,
                            items: ["libre", "ocupado"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (value) => setStateDialog(() => estado = value!),
                            decoration: const InputDecoration(labelText: "Estado"),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: jornada,
                            items: ["matutina", "vespertina", "nocturna"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (value) => setStateDialog(() => jornada = value!),
                            decoration: const InputDecoration(labelText: "Jornada"),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: salaSeleccionada,
                            items: salasDisponibles.map((sala) => DropdownMenuItem<int>(value: sala["id"], child: Text(sala["nombre"]))).toList(),
                            onChanged: (value) => setStateDialog(() => salaSeleccionada = value),
                            decoration: const InputDecoration(labelText: "Sala"),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: carreraSeleccionada,
                            items: carrerasDisponibles.map((carrera) => DropdownMenuItem<int>(value: carrera["id"], child: Text(carrera["nombre"]))).toList(),
                            onChanged: (value) => setStateDialog(() => carreraSeleccionada = value),
                            decoration: const InputDecoration(labelText: "Carrera"),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: docenteSeleccionado,
                            items: docentesDisponibles.map((docente) => DropdownMenuItem<int>(value: docente["id"], child: Text("${docente["apellidos"]} ${docente["nombres"]}"))).toList(),
                            onChanged: (value) => setStateDialog(() => docenteSeleccionado = value),
                            decoration: const InputDecoration(labelText: "Docente (Opcional)"),
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
                  onPressed: guardando || cargandoDatos
                      ? null
                      : () async {
                          if (codigoController.text.trim().isEmpty || salaSeleccionada == null || carreraSeleccionada == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Completa todos los campos obligatorios")),
                            );
                            return;
                          }

                          setStateDialog(() => guardando = true);

                          final datos = {
                            "codigo": codigoController.text.trim(),
                            "estado": estado,
                            "jornada": jornada,
                            "sala_id": salaSeleccionada,
                            "carrera_id": carreraSeleccionada,
                            "docente_id": docenteSeleccionado,
                          };

                          bool success;
                          if (escritorio == null) {
                            success = await _apiService.crearEscritorio(datos);
                          } else {
                            success = await _apiService.actualizarEscritorio(escritorio["id"], datos);
                          }

                          setStateDialog(() => guardando = false);

                          if (success) {
                            _cargarEscritorios();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al guardar escritorio")),
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

  Future<Map<String, List<dynamic>>> _cargarDatosFormulario() async {
    try {
      final salas = await _apiService.listarSalasPorSede(widget.idSede);
      final carreras = await _apiService.listarCarreras();
      final docentes = await _apiService.listarDocentes(widget.idSede);
      
      return {
        'salas': salas,
        'carreras': carreras.where((c) => (c["sede_ids"] as List).contains(widget.idSede)).toList(),
        'docentes': docentes,
      };
    } catch (e) {
      return {'salas': [], 'carreras': [], 'docentes': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Escritorios",
      subtitle: "Gestión de espacios de trabajo y escritorios",
      onAdd: () => _abrirFormulario(),
      child: AdminTable(
        isLoading: cargando,
        columns: const [
          DataColumn(label: Text("Código")),
          DataColumn(label: Text("Estado")),
          DataColumn(label: Text("Jornada")),
          DataColumn(label: Text("Sala")),
          DataColumn(label: Text("Carrera")),
          DataColumn(label: Text("Docente")),
          DataColumn(label: Text("Acciones")),
        ],
        rows: escritorios.map((e) {
          return DataRow(cells: [
            DataCell(Text(e["codigo"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(_buildEstadoChip(e["estado"])),
            DataCell(Text(e["jornada"] ?? "")),
            DataCell(Text(e["sala_nombre"] ?? "Sin sala")),
            DataCell(Text(e["carrera_nombre"] ?? "Sin carrera")),
            DataCell(Text(e["docente_nombre"] ?? "Sin docente")),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _abrirFormulario(escritorio: e),
                    tooltip: "Editar",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarEscritorio(e["id"]),
                    tooltip: "Eliminar",
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildEstadoChip(String? estado) {
    Color color = Colors.grey;
    if (estado == "libre") color = Colors.green;
    if (estado == "ocupado") color = Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        estado?.toUpperCase() ?? "N/A",
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}