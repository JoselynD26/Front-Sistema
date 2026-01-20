import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/mouse_tracker_fix.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import '../widgets/custom_dialog.dart';
import 'escritorio_form.dart';
import 'dynamic_croquis_screen.dart';

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
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: "Eliminar Escritorio",
        description: "¿Estás seguro de que deseas eliminar este escritorio? Esta acción no se puede deshacer.",
        type: DialogType.warning,
        confirmText: "Eliminar",
        showCancel: true,
        onConfirm: () async {
          Navigator.pop(dialogContext); // Close confirmation

          // Show loading dialog
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

          final ok = await _apiService.eliminarEscritorio(id).catchError((_) => false);
          
          if (mounted) {
            Navigator.pop(context); // Close loading (using stable context)

            if (ok) {
              _cargarEscritorios();
              showDialog(
                context: context,
                builder: (successContext) => CustomDialog(
                  title: "¡Éxito!",
                  description: "El escritorio ha sido eliminado correctamente.",
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
                  description: "No se pudo eliminar el escritorio.",
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

  void _mostrarSelectorSala() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final salas = await _apiService.listarSalasPorSede(widget.idSede);
      if (mounted) Navigator.pop(context); // Close loading

      if (!mounted) return;

      if (salas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay salas registradas en esta sede")));
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Ver Croquis de Sala"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: salas.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                final s = salas[i];
                return ListTile(
                  leading: Icon(Icons.meeting_room_outlined, color: Theme.of(context).primaryColor),
                  title: Text(s['nombre'] ?? "Sala sin nombre"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DynamicCroquisScreen(
                          salaId: s['id'],
                          salaNombre: s['nombre'] ?? "Sala",
                          idSede: widget.idSede,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            )
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al cargar listado de salas")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Escritorios",
      subtitle: "Gestión de espacios de trabajo y escritorios",
      onAdd: () => _abrirFormulario(),
      idSede: widget.idSede,
      actions: [
        ElevatedButton.icon(
          onPressed: _mostrarSelectorSala,
          icon: const Icon(Icons.map, size: 18),
          label: const Text("Ver Croquis"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
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
                    icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
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