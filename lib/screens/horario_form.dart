import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';

class HorarioForm extends StatefulWidget {
  final Map? horario;
  final int idSede;
  final Function? onSave;

  const HorarioForm({
    super.key,
    this.horario,
    required this.idSede,
    this.onSave,
  });

  @override
  _HorarioFormState createState() => _HorarioFormState();
}

class _HorarioFormState extends State<HorarioForm> {
  final _fechaController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();
  
  final apiService = ApiService();
  bool cargando = false;
  String? mensaje;
  
  List<dynamic> docentes = [];
  List<dynamic> materias = [];
  List<dynamic> aulas = [];
  List<dynamic> cursos = [];
  List<dynamic> carreras = [];
  List<dynamic> cursosFiltrados = [];
  List<dynamic> materiasFiltradas = [];
  
  int? carreraSeleccionada;
  int? docenteSeleccionado;
  int? materiaSeleccionada;
  int? aulaSeleccionada;
  int? cursoSeleccionado;
  String estado = "activo";

  final Color _primaryColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    if (widget.horario != null) {
      _fechaController.text = widget.horario!['fecha'] ?? "";
      _horaInicioController.text = widget.horario!['hora_inicio'] ?? widget.horario!['hora'] ?? "";
      _horaFinController.text = widget.horario!['hora_fin'] ?? "";
      estado = widget.horario!['estado'] ?? "activo";
      docenteSeleccionado = widget.horario!['id_docente'];
      materiaSeleccionada = widget.horario!['id_materia'];
      aulaSeleccionada = widget.horario!['id_aula'];
      cursoSeleccionado = widget.horario!['id_curso'];
    }
  }
  
  Future<void> _cargarDatos() async {
    try {
      final docentesData = await apiService.listarDocentesPorSede(widget.idSede);
      final materiasData = await apiService.listarMateriasPorSede(widget.idSede);
      final aulasData = await apiService.listarAulasPorSede(widget.idSede);
      final cursosData = await apiService.listarCursosPorSede(widget.idSede);
      final carrs = await apiService.listarCarreras();

      final Map<int, String> carrerasMap = {};
      for (var c in carrs) {
        if (c["id"] != null) carrerasMap[c["id"]] = c["nombre"] ?? "";
      }
      
      final Map<int, dynamic> uniqueDocs = {};
      for (var d in docentesData) {
        if (d['id'] != null) uniqueDocs[d['id']] = d;
      }
      final sortedDocs = uniqueDocs.values.toList();
      sortedDocs.sort((a, b) {
        final apeA = (a['apellidos'] ?? '').toString().trim().toLowerCase();
        final apeB = (b['apellidos'] ?? '').toString().trim().toLowerCase();
        final cmp = apeA.compareTo(apeB);
        if (cmp != 0) return cmp;
        
        final nomA = (a['nombres'] ?? '').toString().trim().toLowerCase();
        final nomB = (b['nombres'] ?? '').toString().trim().toLowerCase();
        return nomA.compareTo(nomB);
      });
      materiasData.sort((a, b) => (a['nombre'] ?? "").toString().toLowerCase().compareTo((b['nombre'] ?? "").toString().toLowerCase()));
      aulasData.sort((a, b) => (a['nombre'] ?? "").toString().toLowerCase().compareTo((b['nombre'] ?? "").toString().toLowerCase()));
      
      // Ordenar cursos por: Nivel → Jornada (Matutina, Vespertina, Nocturna) → Paralelo
      cursosData.sort((a, b) {
        final nomCarreraA = carrerasMap[a["carrera_id"]]?.toLowerCase() ?? "";
        final nomCarreraB = carrerasMap[b["carrera_id"]]?.toLowerCase() ?? "";
        final cmpCarrera = nomCarreraA.compareTo(nomCarreraB);
        if (cmpCarrera != 0) return cmpCarrera;

        final nivelA = (a["nivel"] ?? "").toString().toLowerCase();
        final nivelB = (b["nivel"] ?? "").toString().toLowerCase();
        final cmpNivel = nivelA.compareTo(nivelB);
        if (cmpNivel != 0) return cmpNivel;

        final jornadaA = (a["jornada"] ?? "").toString().toLowerCase();
        final jornadaB = (b["jornada"] ?? "").toString().toLowerCase();
        
        int getJornadaPrioridad(String jornada) {
          if (jornada.contains("matutina")) return 1;
          if (jornada.contains("vespertina")) return 2;
          if (jornada.contains("nocturna")) return 3;
          return 4;
        }
        
        final cmpJornada = getJornadaPrioridad(jornadaA).compareTo(getJornadaPrioridad(jornadaB));
        if (cmpJornada != 0) return cmpJornada;

        final paraleloA = (a["paralelo"] ?? "").toString().toLowerCase();
        final paraleloB = (b["paralelo"] ?? "").toString().toLowerCase();
        final cmpParalelo = paraleloA.compareTo(paraleloB);
        if (cmpParalelo != 0) return cmpParalelo;

        final nomA = (a["nombre"] ?? "").toString().toLowerCase();
        final nomB = (b["nombre"] ?? "").toString().toLowerCase();
        return nomA.compareTo(nomB);
      });

      for (var c in cursosData) {
        c['carrera_nombre'] = carrerasMap[c['carrera_id']] ?? "N/A";
      }

      setState(() {
        docentes = sortedDocs;
        materias = materiasData;
        aulas = aulasData;
        cursos = cursosData;
        carreras = carrs;
        cursosFiltrados = cursosData;
        materiasFiltradas = materiasData;
        cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => mensaje = "Error al cargar datos: $e");
    }
  }

  Future<void> _guardar() async {
    if (_fechaController.text.isEmpty || _horaInicioController.text.isEmpty || _horaFinController.text.isEmpty) {
      setState(() => mensaje = "Fecha, hora de inicio y hora de fin son obligatorias");
      return;
    }

    if (docenteSeleccionado == null ||
        materiaSeleccionada == null ||
        aulaSeleccionada == null ||
        cursoSeleccionado == null) {
      setState(() => mensaje = "Docente, Materia, Aula y Curso son obligatorios");
      return;
    }

    setState(() => cargando = true);

    final datos = {
      "fecha": _fechaController.text.trim(),
      "hora_inicio": _horaInicioController.text.trim(),
      "hora_fin": _horaFinController.text.trim(),
      "estado": estado,
      "id_docente": docenteSeleccionado!,
      "id_materia": materiaSeleccionada!,
      "id_aula": aulaSeleccionada!,
      "id_curso": cursoSeleccionado!,
      "id_sede": widget.idSede,
    };

    bool success;
    try {
      if (widget.horario == null) {
        success = await apiService.crearHorario(datos);
      } else {
        success = await apiService.actualizarHorario(widget.horario!['id'], datos);
      }

      if (mounted) {
        setState(() {
          cargando = false;
          mensaje = success ? "Guardado con éxito" : "Error al guardar";
        });

        if (success && widget.onSave != null) {
          widget.onSave!();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          cargando = false;
          mensaje = "Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.horario != null;

    return AdminFormLayout(
      title: esEdicion ? "Editar Horario" : "Nuevo Horario",
      subtitle: "Gestione los horarios de clases, docentes y disponibilidad de aulas.",
      icon: Icons.schedule_rounded,
      primaryColor: _primaryColor,
      isLoading: cargando,
      children: [
        Column(
          children: [
            if (mensaje != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: (mensaje == "Guardado con éxito" ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (mensaje == "Guardado con éxito" ? Colors.green : Colors.red).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      mensaje == "Guardado con éxito" ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: mensaje == "Guardado con éxito" ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mensaje!,
                        style: TextStyle(
                          color: mensaje == "Guardado con éxito" ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            InkWell(
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (fecha != null) {
                  setState(() {
                    _fechaController.text = fecha.toString().split(' ')[0];
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: premiumInputDecoration(
                  label: "Fecha de la Sesión",
                  hint: "Seleccionar fecha...",
                  icon: Icons.calendar_today_rounded,
                  primaryColor: _primaryColor,
                ),
                child: Text(
                  _fechaController.text.isEmpty ? "Seleccionar fecha..." : _fechaController.text,
                  style: TextStyle(
                    color: _fechaController.text.isEmpty ? Colors.grey.shade500 : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      TextField(
                        controller: _horaInicioController,
                        decoration: premiumInputDecoration(
                          label: "Hora Inicio",
                          hint: "HH:MM",
                          icon: Icons.access_time_rounded,
                          primaryColor: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _horaFinController,
                        decoration: premiumInputDecoration(
                          label: "Hora Fin",
                          hint: "HH:MM",
                          icon: Icons.access_time_filled_rounded,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _horaInicioController,
                        decoration: premiumInputDecoration(
                          label: "Hora Inicio",
                          hint: "HH:MM",
                          icon: Icons.access_time_rounded,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _horaFinController,
                        decoration: premiumInputDecoration(
                          label: "Hora Fin",
                          hint: "HH:MM",
                          icon: Icons.access_time_filled_rounded,
                          primaryColor: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: estado,
              items: const [
                DropdownMenuItem(value: "activo", child: Text("Activo")),
                DropdownMenuItem(value: "cancelado", child: Text("Cancelado")),
              ],
              onChanged: (value) => setState(() => estado = value!),
              decoration: premiumInputDecoration(
                label: "Estado del Horario",
                hint: "Seleccione estado...",
                icon: Icons.info_outline_rounded,
                primaryColor: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: docenteSeleccionado,
              items: docentes.map<DropdownMenuItem<int>>((docente) {
                return DropdownMenuItem<int>(
                  value: docente["id"],
                  child: Text("${docente["apellidos"]} ${docente["nombres"]}"),
                );
              }).toList(),
              onChanged: (value) => setState(() => docenteSeleccionado = value),
              decoration: premiumInputDecoration(
                label: "Docente Responsable",
                hint: "Seleccione docente...",
                icon: Icons.person_rounded,
                primaryColor: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Filtro por Carrera
            DropdownButtonFormField<int>(
              value: carreraSeleccionada,
              decoration: premiumInputDecoration(
                label: "Carrera (Filtro)",
                hint: "Seleccione carrera para filtrar cursos...",
                icon: Icons.school,
                primaryColor: _primaryColor,
              ),
              items: (carreras ?? []).map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
                value: c['id'],
                child: Text(c['nombre']),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  carreraSeleccionada = v;
                  cursoSeleccionado = null;
                  materiaSeleccionada = null;
                  
                  if (v == null) {
                    cursosFiltrados = cursos ?? [];
                    materiasFiltradas = materias ?? [];
                  } else {
                    cursosFiltrados = (cursos ?? []).where((c) => c['carrera_id'] == v).toList();
                    materiasFiltradas = (materias ?? []).where((m) {
                      final carreraIds = m['carrera_ids'] as List?;
                      if (carreraIds != null && carreraIds.contains(v)) return true;
                      
                      final carreras = m['carreras'] as List?;
                      if (carreras != null) {
                        return carreras.any((c) => c['id'] == v);
                      }
                      
                      return false;
                    }).toList();
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: cursoSeleccionado,
              items: (cursosFiltrados ?? []).map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c["id"],
                  child: Text("${c['nombre']} ${c['paralelo']??''} (${c['jornada']??''})"),
                );
              }).toList(),
              onChanged: (value) => setState(() => cursoSeleccionado = value),
              decoration: premiumInputDecoration(
                label: "Curso / Paralelo",
                hint: "Seleccione curso...",
                icon: Icons.class_rounded,
                primaryColor: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: materiaSeleccionada,
              items: (materiasFiltradas ?? []).map<DropdownMenuItem<int>>((materia) {
                return DropdownMenuItem<int>(
                  value: materia["id"],
                  child: Text(materia["nombre"]),
                );
              }).toList(),
              onChanged: (value) => setState(() => materiaSeleccionada = value),
              decoration: premiumInputDecoration(
                label: "Materia / Asignatura",
                hint: "Seleccione materia...",
                icon: Icons.book_rounded,
                primaryColor: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: aulaSeleccionada,
              items: aulas.map<DropdownMenuItem<int>>((aula) {
                return DropdownMenuItem<int>(
                  value: aula["id"],
                  child: Text("${aula["nombre"]} (Capacidad: ${aula["capacidad"]})"),
                );
              }).toList(),
              onChanged: (value) => setState(() => aulaSeleccionada = value),
              decoration: premiumInputDecoration(
                label: "Aula Asignada",
                hint: "Seleccione aula...",
                icon: Icons.meeting_room_rounded,
                primaryColor: _primaryColor,
              ),
            ),
          ],
        ),
      ],
      actions: [
        ElevatedButton(
          onPressed: cargando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: _primaryColor.withOpacity(0.4),
          ),
          child: Text(
            esEdicion ? "GUARDAR CAMBIOS" : "CREAR HORARIO",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text("Cancelar y volver"),
        ),
      ],
    );
  }
}