import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';

class HorarioAulaForm extends StatefulWidget {
  final int idSede;
  final int aulaId;
  final String aulaNombre;
  final Map<String, dynamic>? horario; // Datos para edición
  final Function? onSave;

  const HorarioAulaForm({
    super.key,
    required this.idSede,
    required this.aulaId,
    required this.aulaNombre,
    this.horario,
    this.onSave,
  });

  @override
  State<HorarioAulaForm> createState() => _HorarioAulaFormState();
}

class _HorarioAulaFormState extends State<HorarioAulaForm> {
  final ApiService _apiService = ApiService();
  bool cargando = false;
  String? mensaje;

  // Listas de datos
  List<dynamic> docentes = [];
  List<dynamic> materias = [];
  List<dynamic> cursos = [];
  List<dynamic> carreras = [];
  List<dynamic> cursosFiltrados = [];
  List<dynamic> materiasFiltradas = [];

  // Selecciones
  int? carreraSeleccionada;
  int? docenteSeleccionado;
  int? materiaSeleccionada;
  int? cursoSeleccionado;
  List<String> diasSeleccionados = [];
  
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();

  final List<String> diasSemana = [
    "Lunes", "Martes", "Miércoles", "Jueves", "Viernes"
  ];

  final Color _primaryColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => cargando = true);
    try {
      final docs = await _apiService.listarDocentesPorSede(widget.idSede);
      final mats = await _apiService.listarMateriasPorSede(widget.idSede);
      final curs = await _apiService.listarCursosPorSede(widget.idSede);
      final carrs = await _apiService.listarCarreras();

      final Map<int, String> carrerasMap = {};
      for (var c in carrs) {
        if (c["id"] != null) carrerasMap[c["id"]] = c["nombre"] ?? "";
      }
      
      // Remove duplicates by ID and sort
      final Map<int, dynamic> uniqueDocs = {};
      for (var d in docs) {
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
      mats.sort((a, b) => (a['nombre'] ?? "").toString().toLowerCase().compareTo((b['nombre'] ?? "").toString().toLowerCase()));
      
      // Ordenar cursos por: Nivel → Jornada (Matutina, Vespertina, Nocturna) → Paralelo
      curs.sort((a, b) {
        final nomCarreraA = carrerasMap[a["carrera_id"]]?.toLowerCase() ?? "";
        final nomCarreraB = carrerasMap[b["carrera_id"]]?.toLowerCase() ?? "";
        final cmpCarrera = nomCarreraA.compareTo(nomCarreraB);
        if (cmpCarrera != 0) return cmpCarrera;

        // Comparar nivel
        final nivelA = (a["nivel"] ?? "").toString().toLowerCase();
        final nivelB = (b["nivel"] ?? "").toString().toLowerCase();
        final cmpNivel = nivelA.compareTo(nivelB);
        if (cmpNivel != 0) return cmpNivel;

        // Comparar jornada con orden personalizado
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

        // Comparar paralelo
        final paraleloA = (a["paralelo"] ?? "").toString().toLowerCase();
        final paraleloB = (b["paralelo"] ?? "").toString().toLowerCase();
        final cmpParalelo = paraleloA.compareTo(paraleloB);
        if (cmpParalelo != 0) return cmpParalelo;

        final nomA = (a["nombre"] ?? "").toString().toLowerCase();
        final nomB = (b["nombre"] ?? "").toString().toLowerCase();
        return nomA.compareTo(nomB);
      });
      
      // Añadir nombre de carrera al mapa local de cursos para mostrar en el dropdown
      for (var c in curs) {
        c['carrera_nombre'] = carrerasMap[c['carrera_id']] ?? "N/A";
      }

      if (mounted) {
        setState(() {
          docentes = sortedDocs;
          materias = mats;
          cursos = curs;
          carreras = carrs;
          cursosFiltrados = curs; // Inicialmente mostrar todos
          materiasFiltradas = mats; // Inicialmente mostrar todas
          
          if (widget.horario != null) {
            final h = widget.horario!;
            docenteSeleccionado = h["docente_id"] ?? h["id_docente"];
            cursoSeleccionado = h["curso_id"] ?? h["id_curso"];
            materiaSeleccionada = h["materia_id"] ?? h["id_materia"];
            if (h["dia"] != null) diasSeleccionados = [h["dia"]];
            _horaInicioController.text = h["hora_inicio"] ?? "";
            _horaFinController.text = h["hora_fin"] ?? "";
          }
          
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        mensaje = "Error al cargar listas: $e";
        cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (docenteSeleccionado == null || cursoSeleccionado == null || materiaSeleccionada == null || diasSeleccionados.isEmpty || _horaInicioController.text.isEmpty || _horaFinController.text.isEmpty) {
      setState(() => mensaje = "Todos los campos son obligatorios.");
      return;
    }

    setState(() => cargando = true);
    
    // 1. Obtener horarios existentes para esta aula para validar traslapes
    List<dynamic> existentes = [];
    try {
      final todos = await _apiService.listarHorariosPorSede(widget.idSede);
      existentes = todos.where((h) => h["id_aula"] == widget.aulaId).toList();
    } catch (e) {
      debugPrint("Error validando traslapes: $e");
    }

    int creados = 0;
    int fallidos = 0;
    List<String> errores = [];

    if (widget.horario != null) {
      // MODO EDICIÓN
      final ok = await _apiService.actualizarHorarioDocente(widget.horario!["id"], {
        'docente_id': docenteSeleccionado!,
        'curso_id': cursoSeleccionado!,
        'materia_id': materiaSeleccionada!,
        'aula_id': widget.aulaId,
        'dia': diasSeleccionados.first,
        'hora_inicio': _horaInicioController.text,
        'hora_fin': _horaFinController.text,
      });

      if (ok) {
        creados = 1;
      } else {
        fallidos = 1;
        mensaje = "Error al actualizar el horario.";
      }
    } else {
      // MODO CREACIÓN
      for (String dia in diasSeleccionados) {
        // 2. Validar traslape localmente
        final inicioNuevo = _horaInicioController.text;
        final finNuevo = _horaFinController.text;

        bool hayTraslape = existentes.any((h) {
          if (h["dia"] != dia) return false;
          final hInicio = h["hora_inicio"];
          final hFin = h["hora_fin"];
          
          // (Inicio1 < Fin2) AND (Fin1 > Inicio2) => Overlap
          return (inicioNuevo.compareTo(hFin) < 0) && (finNuevo.compareTo(hInicio) > 0);
        });

        if (hayTraslape) {
          fallidos++;
          errores.add("El día $dia ya tiene una clase en ese horario.");
          continue;
        }

        final ok = await _apiService.crearHorarioAdmin(
          docenteId: docenteSeleccionado!,
          cursoId: cursoSeleccionado!,
          materiaId: materiaSeleccionada!,
          aulaId: widget.aulaId,
          dia: dia,
          horaInicio: inicioNuevo,
          horaFin: finNuevo,
        );
        if (ok) creados++; else fallidos++;
      }
    }

    if (mounted) {
      setState(() {
        cargando = false;
        if (errores.isNotEmpty) {
           mensaje = errores.join("\n");
        } else if (fallidos == 0) {
          mensaje = widget.horario != null ? "Horario actualizado correctamente" : "Se registraron $creados horarios para el aula ${widget.aulaNombre}";
        } else {
          mensaje = "Ocurrió un error al procesar la solicitud.";
        }
      });

      if (creados > 0) {
        if (widget.onSave != null) widget.onSave!();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.horario != null ? "¡Horario actualizado!" : "¡Horarios agregados correctamente!"), 
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          )
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormLayout(
      title: widget.horario != null ? "Editar Horario" : "Horario: ${widget.aulaNombre}",
      subtitle: widget.horario != null ? "Modifica los detalles de la clase" : "Asignar clases recurrentes a esta aula",
      isLoading: cargando,
      icon: widget.horario != null ? Icons.edit_calendar : Icons.meeting_room_rounded,
      children: [
        if (mensaje != null) 
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: mensaje!.contains("registraron") ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: mensaje!.contains("registraron") ? Colors.green : Colors.red),
            ),
            child: Text(mensaje!, style: TextStyle(color: mensaje!.contains("registraron") ? Colors.green.shade700 : Colors.red.shade700)),
          ),
          
        DropdownButtonFormField<int>(
          value: docenteSeleccionado,
          decoration: premiumInputDecoration(label: "Docente", hint: "Seleccione docente...", icon: Icons.person, primaryColor: _primaryColor),
          items: docentes.map<DropdownMenuItem<int>>((d) => DropdownMenuItem(
            value: d['id'],
            child: Text("${d['apellidos']} ${d['nombres']}"),
          )).toList(),
          onChanged: (v) => setState(() => docenteSeleccionado = v),
        ),

        const SizedBox(height: 20),

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
              cursoSeleccionado = null; // Resetear curso al cambiar carrera
              materiaSeleccionada = null; // Resetear materia al cambiar carrera
              
              if (v == null) {
                cursosFiltrados = cursos ?? [];
                materiasFiltradas = materias ?? [];
              } else {
                cursosFiltrados = (cursos ?? []).where((c) => c['carrera_id'] == v).toList();
                // Filtrar materias - verificar tanto carrera_ids como carreras
                materiasFiltradas = (materias ?? []).where((m) {
                  // Intentar con carrera_ids primero
                  final carreraIds = m['carrera_ids'] as List?;
                  if (carreraIds != null && carreraIds.contains(v)) return true;
                  
                  // Intentar con carreras (array de objetos)
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

        const SizedBox(height: 20),

        DropdownButtonFormField<int>(
          value: cursoSeleccionado,
          decoration: premiumInputDecoration(label: "Curso", hint: "Seleccione curso...", icon: Icons.class_, primaryColor: _primaryColor),
          items: (cursosFiltrados ?? []).map<DropdownMenuItem<int>>((c) => DropdownMenuItem(
            value: c['id'],
            child: Text("${c['nombre']} ${c['paralelo']??''} (${c['jornada']??''})"),
          )).toList(),
          onChanged: (v) => setState(() => cursoSeleccionado = v),
        ),

        const SizedBox(height: 20),

        DropdownButtonFormField<int>(
          value: materiaSeleccionada,
          decoration: premiumInputDecoration(label: "Materia", hint: "Seleccione materia...", icon: Icons.book, primaryColor: _primaryColor),
          items: (materiasFiltradas ?? []).map<DropdownMenuItem<int>>((m) => DropdownMenuItem(
            value: m['id'],
            child: Text(m['nombre']),
          )).toList(),
          onChanged: (v) => setState(() => materiaSeleccionada = v),
        ),

        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text("Seleccione los días de ocupación:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: diasSemana.map((d) {
            final isSelected = diasSeleccionados.contains(d);
            return FilterChip(
              label: Text(d),
              selected: isSelected,
              selectedColor: _primaryColor.withOpacity(0.2),
              checkmarkColor: _primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? _primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    diasSeleccionados.add(d);
                  } else {
                    diasSeleccionados.remove(d);
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _horaInicioController,
                decoration: premiumInputDecoration(label: "Hora Inicio", hint: "07:00", icon: Icons.access_time, primaryColor: _primaryColor),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
                  if (picked != null) {
                    _horaInicioController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                  }
                },
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _horaFinController,
                decoration: premiumInputDecoration(label: "Hora Fin", hint: "09:00", icon: Icons.access_time_filled, primaryColor: _primaryColor),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                  if (picked != null) {
                    _horaFinController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                  }
                },
                readOnly: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        ElevatedButton.icon(
          onPressed: cargando ? null : _guardar,
          icon: Icon(widget.horario != null ? Icons.update : Icons.save),
          label: Text(widget.horario != null ? "ACTUALIZAR" : "GUARDAR HORARIO"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
      ],
    );
  }
}
