import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import '../widgets/custom_dialog.dart';
import 'docente_form_screen.dart';
import 'docente_excel_import_screen.dart';

class DocentesScreen extends StatefulWidget {
  final int idSede;
  const DocentesScreen({super.key, required this.idSede});

  @override
  _DocentesScreenState createState() => _DocentesScreenState();
}

class _DocentesScreenState extends State<DocentesScreen> {
  final _apiService = ApiService();
  List<dynamic> docentes = [];
  List<dynamic> filteredDocentes = [];
  List<int> docentesSinCuenta = [];
  bool cargando = true;
  final _searchController = TextEditingController();

  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _nombresController = TextEditingController();
  String? _regimen;
  String? _observacion;

  @override
  void initState() {
    super.initState();
    _cargarDocentes();
  }

  Future<void> _cargarDocentes() async {
    try {
      final data = await _apiService.listarDocentesPorSede(widget.idSede);
      final sinCuenta = await _apiService.listarDocentesSinCuenta();

      setState(() {
        docentes = data;
        
        // Orden alfabético por Apellido (trim para ignorar espacios)
        docentes.sort((a, b) {
           final apeA = (a["apellidos"] ?? "").toString().trim().toLowerCase();
           final apeB = (b["apellidos"] ?? "").toString().trim().toLowerCase();
           final cmp = apeA.compareTo(apeB);
           if (cmp != 0) return cmp;
           
           final nomA = (a["nombres"] ?? "").toString().trim().toLowerCase();
           final nomB = (b["nombres"] ?? "").toString().trim().toLowerCase();
           return nomA.compareTo(nomB);
        });
        
        docentesSinCuenta = sinCuenta.map<int>((d) => d["id"]).toList();
        
        // Filtrar directamente aquí para evitar doble setState y asegurar consistencia
        final query = _searchController.text.toLowerCase().trim();
        if (query.isEmpty) {
          filteredDocentes = List.from(docentes);
        } else {
          filteredDocentes = docentes.where((d) {
            final nom = (d["nombres"] ?? "").toString().toLowerCase();
            final ape = (d["apellidos"] ?? "").toString().toLowerCase();
            final ced = (d["cedula"] ?? "").toString().toLowerCase();
            return nom.contains(query) || ape.contains(query) || ced.contains(query);
          }).toList();
        }
        
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar docentes")),
      );
    }
  }

  Future<void> _eliminarDocente(int id) async {
    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: "Eliminar Docente",
        description: "¿Estás seguro de eliminar a este docente? Se perderán sus vinculaciones con materias y horarios.",
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

          final ok = await _apiService.eliminarDocente(id).catchError((_) => false);
          
          if (mounted) {
            Navigator.pop(context); // Close loading (using stable context)

            if (ok) {
              _cargarDocentes();
              showDialog(
                context: context,
                builder: (successContext) => CustomDialog(
                  title: "¡Éxito!",
                  description: "El docente ha sido eliminado correctamente.",
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
                  description: "No se pudo eliminar al docente. Verifica si tiene horarios activos.",
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

  void _filterDocentes() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        filteredDocentes = List.from(docentes);
      } else {
        filteredDocentes = docentes.where((d) {
          final nom = (d["nombres"] ?? "").toString().toLowerCase();
          final ape = (d["apellidos"] ?? "").toString().toLowerCase();
          final ced = (d["cedula"] ?? "").toString().toLowerCase();
          return nom.contains(query) || ape.contains(query) || ced.contains(query);
        }).toList();
      }
    });
  }

  // ✅ FORMULARIO PARA CREAR / EDITAR DOCENTE
  void _abrirFormulario({Map<String, dynamic>? docente}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocenteFormScreen(
          idSede: widget.idSede,
          docente: docente,
        ),
      ),
    );

    if (result == true) {
      _cargarDocentes();
      _cargarDocentes();
      showDialog(
        context: context,
        builder: (_) => CustomDialog(
          title: "¡Éxito!",
          description: docente == null ? "El docente ha sido registrado correctamente." : "Los datos del docente han sido actualizados.",
          type: DialogType.success,
          onConfirm: () => Navigator.pop(context),
          confirmText: "Aceptar",
        )
      );
    }
  }

  // ✅ FORMULARIO PARA CREAR CUENTA DOCENTE (CON MOSTRAR/OCULTAR)
  void _abrirFormularioCuenta(Map<String, dynamic> docente) {
    final _correo = TextEditingController(text: docente["correo"] ?? "");
    final _clave = TextEditingController();
    final _confirmacion = TextEditingController();

    bool guardando = false;
    bool mostrarClave = false;
    bool mostrarConfirmacion = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return CustomDialog(
              title: "Crear cuenta para ${docente["nombres"]}",
              type: DialogType.info,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _correo, decoration: const InputDecoration(labelText: "Correo")),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clave,
                    obscureText: !mostrarClave,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      suffixIcon: IconButton(
                        icon: Icon(mostrarClave ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => mostrarClave = !mostrarClave),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmacion,
                    obscureText: !mostrarConfirmacion,
                    decoration: InputDecoration(
                      labelText: "Confirmar contraseña",
                      suffixIcon: IconButton(
                        icon: Icon(mostrarConfirmacion ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => mostrarConfirmacion = !mostrarConfirmacion),
                      ),
                    ),
                  ),
                ],
              ),
              confirmText: "Crear cuenta",
              cancelText: "Cancelar",
              showCancel: true,
              isLoading: guardando,
              onCancel: () => Navigator.pop(context),
              onConfirm: () async {
                  if (_clave.text != _confirmacion.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Las contraseñas no coinciden")),
                    );
                    return;
                  }

                  final datos = {
                    "nombres": docente["nombres"],
                    "apellidos": docente["apellidos"],
                    "correo": _correo.text.trim(),
                    "contrasena": _clave.text.trim(),
                    "rol": "docente",
                    "id_docente": docente["id"],
                  };

                  setStateDialog(() => guardando = true);
                  final ok = await _apiService.crearCuentaDocente(datos);
                  setStateDialog(() => guardando = false);

                  if (ok) {
                    Navigator.pop(context);
                    _cargarDocentes();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cuenta creada con éxito")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Error al crear cuenta")),
                    );
                  }
                },
            );
          },
        );
      },
    );
  }

  // ✅ FORMULARIO PARA CAMBIAR CONTRASEÑA (CON MOSTRAR/OCULTAR)
  void _abrirFormularioContrasena(Map<String, dynamic> docente) {
    final _nueva = TextEditingController();
    final _confirmacion = TextEditingController();

    bool guardando = false;
    bool mostrarNueva = false;
    bool mostrarConfirmacion = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return CustomDialog(
              title: "Cambiar contraseña de ${docente["nombres"]}",
              type: DialogType.info,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                    controller: _nueva,
                    obscureText: !mostrarNueva,
                    decoration: InputDecoration(
                      labelText: "Nueva contraseña",
                      suffixIcon: IconButton(
                        icon: Icon(mostrarNueva ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => mostrarNueva = !mostrarNueva),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmacion,
                    obscureText: !mostrarConfirmacion,
                    decoration: InputDecoration(
                      labelText: "Confirmar contraseña",
                      suffixIcon: IconButton(
                        icon: Icon(mostrarConfirmacion ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => mostrarConfirmacion = !mostrarConfirmacion),
                      ),
                    ),
                  ),
                ],
              ),
              confirmText: "Actualizar",
              cancelText: "Cancelar",
              showCancel: true,
              isLoading: guardando,
              onCancel: () => Navigator.pop(context),
              onConfirm: () async {
                  if (_nueva.text != _confirmacion.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Las contraseñas no coinciden")),
                    );
                    return;
                  }

                  setStateDialog(() => guardando = true);
                  final ok = await _apiService.actualizarContrasenaDocente(
                    docente["id"],
                    _nueva.text.trim(),
                  );
                  setStateDialog(() => guardando = false);

                  if (ok) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Contraseña actualizada")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Error al actualizar contraseña")),
                    );
                  }
                },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Docentes (${docentes.length})",
      subtitle: "Administración de personal docente",
      idSede: widget.idSede,
      onAdd: () => _abrirFormulario(),
      filters: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterDocentes(),
                  decoration: InputDecoration(
                    hintText: "Buscar por nombre, apellido o cédula...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocenteExcelImportScreen(idSede: widget.idSede),
                    ),
                  ).then((_) => _cargarDocentes());
                },
                icon: const Icon(Icons.upload_file),
                label: const Text("Importar Excel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
      child: AdminTable(
        isLoading: cargando,
        columns: const [
          DataColumn(label: Text("Cédula")),
          DataColumn(label: Text("Apellidos y Nombres")),
          DataColumn(label: Text("Correo")),
          DataColumn(label: Text("Régimen")),
          DataColumn(label: Text("Dedicación")),
          DataColumn(label: Text("Cuenta")),
          DataColumn(label: Text("Acciones")),
        ],
        rows: (filteredDocentes ?? []).map((docente) {
          final tieneCuenta = !docentesSinCuenta.contains(docente["id"]);

          return DataRow(cells: [
            DataCell(Text(docente["cedula"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text("${docente["apellidos"] ?? ""} ${docente["nombres"] ?? ""}")),
            DataCell(Text(docente["correo"] ?? "")),
            DataCell(Text(docente["regimen"] ?? "-")),
            DataCell(Text(docente["observacion"] ?? "-")),
            DataCell(
              tieneCuenta 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Text("ACTIVA", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Text("PENDIENTE", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _abrirFormulario(docente: docente),
                  tooltip: "Editar",
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _eliminarDocente(docente["id"]),
                  tooltip: "Eliminar",
                ),
                const SizedBox(width: 8),
                if (tieneCuenta) 
                  IconButton(
                    icon: const Icon(Icons.lock_reset, color: Colors.purple),
                    tooltip: "Cambiar contraseña",
                    onPressed: () => _abrirFormularioContrasena(docente),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.person_add_alt, color: Colors.deepPurple),
                    tooltip: "Crear cuenta docente",
                    onPressed: () => _abrirFormularioCuenta(docente),
                  ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}