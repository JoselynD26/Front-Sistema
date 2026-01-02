import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import '../widgets/custom_dialog.dart';
import '../utils/mouse_tracker_fix.dart';
import 'form_sede_screen.dart';

class SedesManagementScreen extends StatefulWidget {
  const SedesManagementScreen({super.key});

  @override
  _SedesManagementScreenState createState() => _SedesManagementScreenState();
}

class _SedesManagementScreenState extends State<SedesManagementScreen> with SafeStateMixin {
  final _apiService = ApiService();
  List<dynamic> sedes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSedes();
  }

  Future<void> _cargarSedes() async {
    try {
      final data = await _apiService.listarSedes();
      safeSetState(() {
        sedes = data;
        cargando = false;
      });
    } catch (e) {
      safeSetState(() => cargando = false);
    }
  }

  Future<void> _eliminarSede(int id) async {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: "Confirmar Eliminación",
        description: "¿Estás seguro de que deseas eliminar esta sede? Esta acción afectará a todos los recursos asociados.",
        type: DialogType.warning,
        confirmText: "Eliminar",
        showCancel: true,
        onConfirm: () async {
          Navigator.pop(dialogContext);
          
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const CustomDialog(
              title: "Eliminando...",
              description: "Por favor espera",
              type: DialogType.info,
              isLoading: true,
            ),
          );
          
          final ok = await _apiService.eliminarSede(id);
          
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            
            // Show result dialog
            showDialog(
              context: context,
              builder: (context) => CustomDialog(
                title: ok ? "¡Éxito!" : "Error",
                description: ok 
                  ? "La sede ha sido eliminada correctamente" 
                  : "No se pudo eliminar la sede. Intenta nuevamente.",
                type: ok ? DialogType.success : DialogType.error,
                confirmText: "Aceptar",
                onConfirm: () {
                  Navigator.pop(context);
                  if (ok) _cargarSedes();
                },
              ),
            );
          }
        },
      ),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? sede}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormSedeScreen(sede: sede),
      ),
    );
    if (result == true) {
      _cargarSedes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Gestión de Sedes",
      subtitle: "Administra las sedes y campus de la institución",
      onAdd: () => _abrirFormulario(),
      addLabel: "Nueva Sede",
      child: AdminTable(
        isLoading: cargando,
        columns: const [
          DataColumn(label: Text("Nombre")),
          DataColumn(label: Text("Ubicación")),
          DataColumn(label: Text("Acciones")),
        ],
        rows: sedes.map((s) {
          return DataRow(cells: [
            DataCell(Text(s["nombre"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(s["ubicacion"] ?? "Sin registro")),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _abrirFormulario(sede: s),
                    tooltip: "Editar",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarSede(s["id"]),
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
}
