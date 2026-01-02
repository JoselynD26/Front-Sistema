import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import '../widgets/custom_dialog.dart';
import 'carrera_form.dart';

class CarrerasScreen extends StatefulWidget {
  final int idSede;
  const CarrerasScreen({super.key, required this.idSede});

  @override
  State<CarrerasScreen> createState() => _CarrerasScreenState();
}

class _CarrerasScreenState extends State<CarrerasScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> carreras = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      final data = await _apiService.listarCarreras();
      setState(() {
        carreras = data
            .where((c) =>
                (c["sede_ids"] ?? []).contains(widget.idSede))
            .toList();
        
        // Orden alfabético por nombre
        carreras.sort((a, b) => (a["nombre"] ?? "").toString().toLowerCase().compareTo((b["nombre"] ?? "").toString().toLowerCase()));

        cargando = false;
      });
    } catch (_) {
      setState(() => cargando = false);
    }
  }

  Future<void> _eliminarCarrera(int id) async {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: "Eliminar Carrera",
        description: "¿Estás seguro de eliminar esta carrera? Esto podría afectar a los cursos y materias vinculados.",
        type: DialogType.warning,
        confirmText: "Eliminar",
        showCancel: true,
        onConfirm: () async {
          Navigator.pop(dialogContext); // Cerrar confirmación

          // Mostrar carga
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

          final ok = await _apiService.eliminarCarrera(id).catchError((_) => false);
          
          if (mounted) {
            Navigator.pop(context); // Cerrar carga (estable)

            if (ok) {
              _cargarCarreras();
              showDialog(
                context: context,
                builder: (successContext) => CustomDialog(
                  title: "¡Éxito!",
                  description: "La carrera ha sido eliminada correctamente.",
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
                  description: "No se pudo eliminar la carrera. Verifica si tiene dependencias.",
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

  void _abrirFormulario({Map<String, dynamic>? carrera}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarreraFormScreen(
          idSede: widget.idSede,
          carrera: carrera,
        ),
      ),
    );

    if (result == true) {
      _cargarCarreras();
      _cargarCarreras();
      showDialog(
        context: context,
        builder: (_) => CustomDialog(
          title: "¡Éxito!",
          description: carrera == null ? "La carrera ha sido creada correctamente." : "La carrera ha sido actualizada correctamente.",
          type: DialogType.success,
          onConfirm: () => Navigator.pop(context),
          confirmText: "Aceptar",
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Carreras",
      subtitle: "Gestiona las carreras de esta sede",
      idSede: widget.idSede,
      onAdd: () => _abrirFormulario(),
      child: AdminTable(
        isLoading: cargando,
        columns: const [
          DataColumn(label: Text("Código")),
          DataColumn(label: Text("Nombre")),
          DataColumn(label: Text("Acciones")),
        ],
        rows: carreras.map((c) {
          return DataRow(cells: [
            DataCell(Text(c["codigo"] ?? "AUTO", style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(c["nombre"])),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _abrirFormulario(carrera: c),
                    tooltip: "Editar",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarCarrera(c["id"]),
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
