import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import '../widgets/custom_dialog.dart';
import 'sala_form_screen.dart';

class SalasScreen extends StatefulWidget {
  final int idSede;
  const SalasScreen({super.key, required this.idSede});

  @override
  _SalasScreenState createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  final _apiService = ApiService();
  List<dynamic> salas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSalas();
  }

  Future<void> _cargarSalas() async {
    if (!mounted) return;
    try {
      final data = await _apiService.listarSalasPorSede(widget.idSede);
      if (mounted) {
        setState(() {
          salas = data;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al cargar salas")),
        );
      }
    }
  }

  Future<void> _eliminarSala(int id) async {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: "Eliminar Sala",
        description: "¿Estás seguro de eliminar esta sala? Esta acción no se puede deshacer.",
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

          final ok = await _apiService.eliminarSala(id).catchError((_) => false);
          
          if (mounted) {
            Navigator.pop(context); // Close loading

            if (ok) {
              _cargarSalas();
              showDialog(
                context: context,
                builder: (successContext) => CustomDialog(
                  title: "¡Éxito!",
                  description: "La sala ha sido eliminada correctamente.",
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
                  description: "No se pudo eliminar la sala. Verifica si tiene dependencias.",
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

  void _abrirFormulario({Map<String, dynamic>? sala}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SalaFormScreen(
          sala: sala,
          idSede: widget.idSede,
        ),
      ),
    );

    if (result == true) {
      _cargarSalas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Salas",
      subtitle: "Gestión de laboratorios y salas especiales",
      onAdd: () => _abrirFormulario(),
      idSede: widget.idSede,
      child: AdminTable(
        isLoading: cargando,
        columns: const [
          DataColumn(label: Text("Nombre")),
          DataColumn(label: Text("Acciones")),
        ],
        rows: salas.map((s) {
          return DataRow(cells: [
            DataCell(Text(s["nombre"], style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _abrirFormulario(sala: s),
                  tooltip: "Editar",
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _eliminarSala(s["id"]),
                  tooltip: "Eliminar",
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}