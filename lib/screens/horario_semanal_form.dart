import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';
import '../widgets/conflict_dialog.dart';

class HorarioSemanalForm extends StatefulWidget {
  final int idSede;
  final Function? onSave;

  const HorarioSemanalForm({
    super.key,
    required this.idSede,
    this.onSave,
  });

  @override
  State<HorarioSemanalForm> createState() => _HorarioSemanalFormState();
}

class _HorarioSemanalFormState extends State<HorarioSemanalForm> {
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
  List<dynamic> aulas = [];

  // Selecciones
  int? carreraSeleccionada;
  int? docenteSeleccionado;
  int? materiaSeleccionada;
  int? cursoSeleccionado;
  int? aulaSeleccionada;
  List<String> diasSeleccionados = []; // Cambiado a Lista
  
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();

  final List<String> diasSemana = [
    "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"
  ];

  final Color _primaryColor = const Color(0xFFF59E0B); // Amber 500 equivalent

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
      final auls = await _apiService.listarAulasPorSede(widget.idSede);
      final carrs = await _apiService.listarCarreras();

      final Map<int, String> carrerasMap = {};
      for (var c in carrs) {
        if (c["id"] != null) carrerasMap[c["id"]] = c["nombre"] ?? "";
      }
      
      // Ordenar alfabéticamente para facilitar búsqueda
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

      for (var c in curs) {
        c['carrera_nombre'] = carrerasMap[c['carrera_id']] ?? "N/A";
      }

      auls.sort((a, b) => (a['nombre'] ?? "").toString().toLowerCase().compareTo((b['nombre'] ?? "").toString().toLowerCase()));

      if (mounted) {
        setState(() {
          docentes = sortedDocs;
          materias = mats;
          cursos = curs;
          carreras = carrs;
          cursosFiltrados = curs;
          materiasFiltradas = mats;
          aulas = auls;
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

  // --- HELPERS PARA VALIDACIÓN ---
  int _parseHora(String h) {
    if (h.isEmpty) return 0;
    try {
      final parts = h.split(":");
      final val = int.parse(parts[0]) * 100 + int.parse(parts[1]);
      return val;
    } catch (_) {
      return 0;
    }
  }

  String _normalize(String s) {
    return s.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }
  // -------------------------------

  Future<void> _guardar() async {
    setState(() => cargando = true);
    
    // 1. Cargar horario actual del docente para validar
    List<dynamic> horarioActual = [];
    try {
       final res = await _apiService.obtenerHorarioDocente(docenteSeleccionado!);
       if (res is List) {
          horarioActual = res;
       }
    } catch (e) {
       print("Error loading schedule for validation: $e");
    }

    int creados = 0;
    int fallidos = 0;
    
    // VALIDACIÓN PREVIA PARA CADA DÍA
    for (String dia in (diasSeleccionados ?? [])) {
        bool proceed = true;

        // Check conflicto
        final inicioNuevo = _parseHora(_horaInicioController.text);
        final finNuevo = _parseHora(_horaFinController.text);

        final conflictivo = horarioActual.firstWhere((h) {
             final hDia = h['dia']?.toString() ?? "";
             final start = _parseHora(h['hora_inicio'] ?? "");
             final end = _parseHora(h['hora_fin'] ?? "");
             
             if (_normalize(hDia) != _normalize(dia)) return false;
             
             // Solapamiento
             return (inicioNuevo < end && finNuevo > start);
        }, orElse: () => null);

        if (conflictivo != null) {
            // MOSTRAR DIÁLOGO
            final confirm = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => ConflictDialog(
                aulaNombre: conflictivo['aula_nombre'] ?? "Aula Desconocida",
                horario: "${conflictivo['hora_inicio']} - ${conflictivo['hora_fin']}",
                dia: dia,
                docenteNombre: "${conflictivo['docente_nombre'] ?? 'Este docente'}",
                onCancel: () => Navigator.pop(ctx, false),
                onLiberar: () => Navigator.pop(ctx, true),
              )
            );

            if (confirm == true) {
               // CANCELAR CLASE ANTERIOR (Eliminar definición recurrente)
               try {
                 await _apiService.eliminarHorarioDocente(conflictivo['id']);
               } catch (e) {
                 print("Error liberando horario anterior: $e");
               }
            } else {
               proceed = false; // Canceló la operación para este día
            }
        }

        if (proceed) {
           final ok = await _apiService.crearHorarioAdmin(
             docenteId: docenteSeleccionado!,
             cursoId: cursoSeleccionado!,
             materiaId: materiaSeleccionada!,
             aulaId: aulaSeleccionada!,
             dia: dia,
             horaInicio: _horaInicioController.text,
             horaFin: _horaFinController.text,
           );
           if (ok) creados++; else fallidos++;
        }
    }

    if (mounted) {
      setState(() {
        cargando = false;
        if (fallidos == 0) {
          mensaje = "Se crearon $creados horarios con éxito";
        } else {
          mensaje = "Se crearon $creados horarios, pero $fallidos fallaron.";
        }
      });

      if (creados > 0) {
        if (widget.onSave != null) widget.onSave!();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡$creados horarios agregados correctamente!"), 
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          )
        );
        
        setState(() {
          diasSeleccionados.clear();
          // NO cerramos la ventana para permitir seguir agregando otros horarios rápidamente
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormLayout(
      title: "Crear Horario Semanal",
      subtitle: "Define clase recurrente (Ej: Lunes 8-10)",
      isLoading: cargando,
      icon: Icons.calendar_view_week_rounded,
      children: [
        if (mensaje != null) 
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            color: mensaje!.contains("éxito") ? Colors.green.shade50 : Colors.red.shade50,
            child: Text(mensaje!, style: TextStyle(color: mensaje!.contains("éxito") ? Colors.green : Colors.red)),
          ),
          
        // 1. Docente
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

        const SizedBox(height: 20),

        // 2. Curso
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

        // 3. Materia
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

        // 4. Aula
        DropdownButtonFormField<int>(
          value: aulaSeleccionada,
          decoration: premiumInputDecoration(label: "Aula", hint: "Seleccione aula...", icon: Icons.room, primaryColor: _primaryColor),
          items: aulas.map<DropdownMenuItem<int>>((a) => DropdownMenuItem(
            value: a['id'],
            child: Text("${a['nombre']} (${a['capacidad']} cap)"),
          )).toList(),
          onChanged: (v) => setState(() => aulaSeleccionada = v),
        ),

        const SizedBox(height: 20),

        // 5. Días de la semana (Selección Múltiple)
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text("Seleccione los días:", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: diasSemana.map((d) {
            final isSelected = (diasSeleccionados ?? []).contains(d);
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

        // 6. Horas
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  TextField(
                    controller: _horaInicioController,
                    decoration: premiumInputDecoration(label: "Hora Inicio", hint: "07:00", icon: Icons.access_time, primaryColor: _primaryColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _horaFinController,
                    decoration: premiumInputDecoration(label: "Hora Fin", hint: "09:00", icon: Icons.access_time_filled, primaryColor: _primaryColor),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _horaInicioController,
                    decoration: premiumInputDecoration(label: "Hora Inicio", hint: "07:00", icon: Icons.access_time, primaryColor: _primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _horaFinController,
                    decoration: premiumInputDecoration(label: "Hora Fin", hint: "09:00", icon: Icons.access_time_filled, primaryColor: _primaryColor),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 30),

        ElevatedButton.icon(
          onPressed: cargando ? null : _guardar,
          icon: const Icon(Icons.save),
          label: const Text("GUARDAR PARA ESTOS DÍAS"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white, 
          ),
        ),

        const SizedBox(height: 12),

        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text("FINALIZAR Y REGRESAR"),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            foregroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
