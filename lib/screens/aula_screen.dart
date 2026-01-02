import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import '../widgets/custom_dialog.dart';
import 'aula_form_screen.dart';
import 'horario_aula_excel_import_screen.dart';
import 'horario_aula_screen.dart';

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
        // Orden alfabético por Número, luego Nombre
        aulas.sort((a, b) {
          final numA = (a["numero"] ?? "").toString().toLowerCase();
          final numB = (b["numero"] ?? "").toString().toLowerCase();
          final cmp = numA.compareTo(numB);
          if (cmp != 0) return cmp;
          return (a["nombre"] ?? "").toString().toLowerCase().compareTo((b["nombre"] ?? "").toString().toLowerCase());
        });
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
    // Show confirmation
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: "Eliminar Aula",
        description: "¿Estás seguro de eliminar esta aula? Se perderán sus horarios vinculados.",
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

          final ok = await _apiService.eliminarAula(id).catchError((_) => false);
          
          if (mounted) {
            Navigator.pop(context); // Close loading

            if (ok) {
              _cargarAulas();
              showDialog(
                context: context,
                builder: (successContext) => CustomDialog(
                  title: "¡Éxito!",
                  description: "El aula ha sido eliminada correctamente.",
                  type: DialogType.success,
                  confirmText: "Aceptar",
                  onConfirm: () => Navigator.pop(successContext),
                ),
              );
            } else {
              showDialog(
                context: this.context,
                builder: (errorContext) => const CustomDialog(
                  title: "Error",
                  description: "No se pudo eliminar el aula. Verifica si tiene recursos asociados.",
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

  void _abrirFormulario({Map<String, dynamic>? aula}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AulaFormScreen(
          idSede: widget.idSede,
          aula: aula,
        ),
      ),
    );

    if (result == true) {
      _cargarAulas();
      showDialog(
        context: context,
        builder: (_) => CustomDialog(
          title: "¡Éxito!",
          description: aula == null ? "El aula ha sido creada correctamente." : "El aula ha sido actualizada correctamente.",
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
      title: "Aulas",
      subtitle: "Administra las aulas físicas de la sede",
      idSede: widget.idSede,
      onAdd: () => _abrirFormulario(),
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HorarioAulaExcelImportScreen(idSede: widget.idSede)),
            );
          },
          icon: const Icon(Icons.file_upload),
          label: const Text("Importar Excel"),
          style: ElevatedButton.styleFrom(
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
             backgroundColor: Colors.indigo.shade50,
             foregroundColor: Colors.indigo,
             side: BorderSide(color: Colors.indigo.shade200)
          ),
        ),
      ],
      child: AdminTable(
        isLoading: cargando,
        columns: const [
          DataColumn(label: Text("Número")),
          DataColumn(label: Text("Nombre")),
          DataColumn(label: Text("Capacidad")),
          DataColumn(label: Text("Descripción")),
          DataColumn(label: Text("Acciones")),
        ],
        rows: aulas.map((aula) {
          return DataRow(cells: [
            DataCell(Text(aula["numero"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(aula["nombre"] ?? "")),
            DataCell(Text(aula["capacidad"].toString())),
            DataCell(Text(aula["descripcion"] ?? "")),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   IconButton(
                    icon: const Icon(Icons.calendar_month, color: Colors.indigo),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HorarioAulaScreen(
                            idSede: widget.idSede,
                            aulaId: aula["id"],
                            aulaNombre: aula["nombre"] ?? "",
                          ),
                        ),
                      );
                    },
                    tooltip: "Gestionar Horario",
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _abrirFormulario(aula: aula),
                    tooltip: "Editar",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarAula(aula["id"]),
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