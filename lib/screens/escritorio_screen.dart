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

  void _abrirFormulario({Map<String, dynamic>? escritorio}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EscritorioForm(
          idSede: widget.idSede,
          escritorio: escritorio,
          onSave: _cargarEscritorios,
        ),
      ),
    );
    _cargarEscritorios();
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Escritorios",
      subtitle: "Gestión de espacios de trabajo y escritorios",
      onAdd: () => _abrirFormulario(),
      idSede: widget.idSede,
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