import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DocentesScreen extends StatefulWidget {
  final int idSede;
  const DocentesScreen({super.key, required this.idSede});

  @override
  _DocentesScreenState createState() => _DocentesScreenState();
}

class _DocentesScreenState extends State<DocentesScreen> {
  final _apiService = ApiService();
  List<dynamic> docentes = [];
  List<int> docentesSinCuenta = [];
  bool cargando = true;

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
        docentesSinCuenta = sinCuenta.map<int>((d) => d["id"]).toList();
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
    final ok = await _apiService.eliminarDocente(id);
    if (ok) {
      _cargarDocentes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Docente eliminado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar docente")),
      );
    }
  }

  // ✅ FORMULARIO PARA CREAR / EDITAR DOCENTE
  void _abrirFormulario({Map<String, dynamic>? docente}) {
    if (docente != null) {
      _cedulaController.text = docente["cedula"] ?? "";
      _correoController.text = docente["correo"] ?? "";
      _apellidosController.text = docente["apellidos"] ?? "";
      _nombresController.text = docente["nombres"] ?? "";
      _regimen = docente["regimen"];
      _observacion = docente["observacion"];
    } else {
      _cedulaController.clear();
      _correoController.clear();
      _apellidosController.clear();
      _nombresController.clear();
      _regimen = null;
      _observacion = null;
    }

    showDialog(
      context: context,
      builder: (_) {
        bool guardando = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(docente == null ? "Nuevo Docente" : "Editar Docente"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: _cedulaController, decoration: const InputDecoration(labelText: "Cédula")),
                    TextField(controller: _correoController, decoration: const InputDecoration(labelText: "Correo")),
                    TextField(controller: _apellidosController, decoration: const InputDecoration(labelText: "Apellidos")),
                    TextField(controller: _nombresController, decoration: const InputDecoration(labelText: "Nombres")),
                    DropdownButtonFormField<String>(
                      value: _regimen,
                      items: const [
                        DropdownMenuItem(value: "LOES", child: Text("LOES")),
                        DropdownMenuItem(value: "Codigo de trabajo", child: Text("Código de trabajo")),
                      ],
                      onChanged: (val) => setStateDialog(() => _regimen = val),
                      decoration: const InputDecoration(labelText: "Régimen"),
                    ),
                    DropdownButtonFormField<String>(
                      value: _observacion,
                      items: const [
                        DropdownMenuItem(value: "Medio tiempo", child: Text("Medio tiempo")),
                        DropdownMenuItem(value: "Tiempo completo", child: Text("Tiempo completo")),
                      ],
                      onChanged: (val) => setStateDialog(() => _observacion = val),
                      decoration: const InputDecoration(labelText: "Observación"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final datos = {
                            "cedula": _cedulaController.text.trim(),
                            "correo": _correoController.text.trim(),
                            "apellidos": _apellidosController.text.trim(),
                            "nombres": _nombresController.text.trim(),
                            "regimen": _regimen,
                            "observacion": _observacion,
                            "sede_id": widget.idSede,
                          };

                          setStateDialog(() => guardando = true);

                          bool success;
                          if (docente == null) {
                            success = await _apiService.crearDocente(datos);
                          } else {
                            success = await _apiService.actualizarDocente(docente["id"], datos);
                          }

                          setStateDialog(() => guardando = false);

                          if (success) {
                            _cargarDocentes();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al guardar docente")),
                            );
                          }
                        },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
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
            return AlertDialog(
              title: Text("Crear cuenta para ${docente["nombres"]}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _correo, decoration: const InputDecoration(labelText: "Correo")),

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
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
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
                  child: const Text("Crear cuenta"),
                ),
              ],
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
            return AlertDialog(
              title: Text("Cambiar contraseña de ${docente["nombres"]}"),
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
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
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
                  child: const Text("Actualizar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Docentes")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : DataTable(
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Cédula")),
                DataColumn(label: Text("Nombres")),
                DataColumn(label: Text("Apellidos")),
                DataColumn(label: Text("Correo")),
                DataColumn(label: Text("Acciones")),
              ],
              rows: docentes.map((docente) {
                final tieneCuenta = !docentesSinCuenta.contains(docente["id"]);

                return DataRow(cells: [
                  DataCell(Text(docente["id"].toString())),
                  DataCell(Text(docente["cedula"] ?? "")),
                  DataCell(Text(docente["nombres"] ?? "")),
                  DataCell(Text(docente["apellidos"] ?? "")),
                  DataCell(Text(docente["correo"] ?? "")),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _abrirFormulario(docente: docente),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarDocente(docente["id"]),
                      ),

                      if (tieneCuenta) ...[
                        const Icon(Icons.verified_user, color: Colors.green),
                        IconButton(
                          icon: const Icon(Icons.lock_reset, color: Colors.purple),
                          tooltip: "Cambiar contraseña",
                          onPressed: () => _abrirFormularioContrasena(docente),
                        ),
                      ] else
                        IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.blue),
                          tooltip: "Crear cuenta docente",
                          onPressed: () => _abrirFormularioCuenta(docente),
                        ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}