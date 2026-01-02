import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';

class DisponibilidadAulasScreen extends StatefulWidget {
  final int idSede;
  const DisponibilidadAulasScreen({super.key, required this.idSede});

  @override
  State<DisponibilidadAulasScreen> createState() => _DisponibilidadAulasScreenState();
}

class _DisponibilidadAulasScreenState extends State<DisponibilidadAulasScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> aulas = [];
  List<dynamic> horariosEventos = []; // Individuales
  List<dynamic> horariosRecurrentes = []; // Semanales
  Map<int, String> carrerasMap = {};
  Map<int, Map<String, dynamic>> cursosMap = {};
  Map<int, String> materiasMap = {};
  bool cargando = true;
  DateTime fechaSeleccionada = DateTime.now();

  List<dynamic> _cancelados = []; // Nueva lista para excepciones

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _fetchCancelados();
  }

  Future<void> _fetchCancelados() async {
    try {
      final fechaStr = "${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2,'0')}-${fechaSeleccionada.day.toString().padLeft(2,'0')}";
      final cancelados = await _apiService.listarHorariosCancelados(widget.idSede, fechaStr);
      if (mounted) {
        setState(() {
          _cancelados = cancelados;
        });
        print("DEBUG: Cancelados recibidos para $fechaStr: ${_cancelados.length}");
        for(var c in _cancelados) {
           print("  -> Cancelado: ID=${c['id']} horario_id=${c['horario_id']} fecha=${c['fecha']}");
        }
      }
    } catch (e) {
      print("Error fetching cancelados: $e");
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => cargando = true);
    try {
      final results = await Future.wait<dynamic>([
        _apiService.listarAulasPorSede(widget.idSede),
        _apiService.listarHorariosPorSede(widget.idSede), // Eventos individuales (Reservas)
        _apiService.listarDocentesPorSede(widget.idSede),
        _apiService.listarCarreras(),
        _apiService.listarCursosPorSede(widget.idSede),
        _apiService.listarMateriasPorSede(widget.idSede),
        _apiService.listarHorariosDocentesPorSede(widget.idSede), // ✅ Bulk Load Recurrentes
        _apiService.listarHistorialReservas(), // ✅ Historial de Reservas para incluir Aprobadas
      ]);

      final List<dynamic> aulasList = results[0] ?? [];
      final List<dynamic> eventos = results[1] ?? [];
      final List<dynamic> docentes = results[2] ?? [];
      final List<dynamic> carreras = results[3] ?? [];
      final List<dynamic> cursos = results[4] ?? [];
      final List<dynamic> materias = results[5] ?? [];
      final List<dynamic> recurrentesRaw = results[6] ?? [];
      final List<dynamic> historialReservas = results[7] ?? [];

      // Ordenar aulas A-Z
      aulasList.sort((a, b) => (a["nombre"] ?? "").toString().toLowerCase().compareTo((b["nombre"] ?? "").toString().toLowerCase()));

      final Map<int, String> cMap = {};
      for (var c in carreras) {
        if (c != null && c["id"] != null) cMap[c["id"]] = c["nombre"] ?? "";
      }

      final Map<int, Map<String, dynamic>> cuMap = {};
      for (var c in cursos) {
        if (c != null && c["id"] != null) cuMap[c["id"]] = c;
      }

      final Map<int, String> mMap = {};
      for (var m in materias) {
        if (m != null && m["id"] != null) mMap[m["id"]] = m["nombre"] ?? "";
      }
      
      final Map<int, dynamic> docentesMap = {};
      for(var d in docentes) {
        if (d["id"]!=null) docentesMap[d["id"]] = d;
      }

      // Procesar horarios recurrentes
      final List<dynamic> recurrentesTotal = [];
      for (var h in recurrentesRaw) {
        final dId = h["docente_id"];
        final docente = docentesMap[dId];
        final hIdMateria = h["id_materia"] ?? h["materia_id"];
        
        final Map<String, dynamic> recurrenteMap = Map<String, dynamic>.from(h);
        recurrenteMap["docente_nombre"] = docente != null ? "${docente['apellidos']} ${docente['nombres']}" : "Docente #$dId";
        recurrenteMap["materia_nombre"] = h["materia_nombre"] ?? mMap[hIdMateria];

        recurrentesTotal.add(recurrenteMap);
      }

      // Procesar reservas aprobadas del historial
      // Debemos asegurarnos de que tengan el formato correcto para ser mostradas
      final List<dynamic> reservasAprobadas = [];
      for (var r in historialReservas) {
         if ((r["estado"] ?? "").toString().toLowerCase() == "aprobada") {
            // Normalizar hora inicio/fin si viene en string único "HH:MM - HH:MM"
            String hInicio = r["hora_inicio"] ?? "";
            String hFin = r["hora_fin"] ?? "";
            
            if (hInicio.isEmpty && r["hora"] != null) {
               final parts = r["hora"].toString().split("-");
               if (parts.length == 2) {
                 hInicio = parts[0].trim();
                 hFin = parts[1].trim();
               }
            }

            // Normalizar fecha (tomar 10 primeros chars por si es ISO)
            final rawFecha = r["fecha"] ?? r["fecha_reserva"];
            String fechaStr = "";
            if (rawFecha != null) {
              fechaStr = rawFecha.toString();
              if (fechaStr.length > 10) fechaStr = fechaStr.substring(0, 10);
            }
            
            final Map<String, dynamic> reservaMap = Map<String, dynamic>.from(r);

            // RESOLVE ID
            dynamic resolvedAulaId = r["aula_id"] ?? r["id_aula"];
            
            // Fallback: search by name
            if (resolvedAulaId == null && r["aula_nombre"] != null) {
               final nameToFind = r["aula_nombre"].toString().toLowerCase().trim();
               try {
                  final foundAula = aulasList.firstWhere((a) => 
                     (a["nombre"] ?? "").toString().toLowerCase().trim() == nameToFind, 
                     orElse: () => null
                  );
                  if (foundAula != null) {
                     resolvedAulaId = foundAula["id"];
                  }
               } catch(e) { }
            }

            reservaMap["fecha"] = fechaStr;
            reservaMap["hora_inicio"] = hInicio;
            reservaMap["hora_fin"] = hFin;
            reservaMap["id_aula"] = resolvedAulaId;

            reservasAprobadas.add(reservaMap);
         }
      }

      setState(() {
        aulas = aulasList;
        horariosEventos = [...eventos, ...reservasAprobadas]; // Unimos ambos tipos de eventos puntuales
        horariosRecurrentes = recurrentesTotal;
        carrerasMap = cMap;
        cursosMap = cuMap;
        materiasMap = mMap;
        cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  String _getDiaSemana(DateTime date) {
    final dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    return dias[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Disponibilidad de Aulas",
      subtitle: "Visualiza qué aulas están ocupadas o libres hoy",
      idSede: widget.idSede,
      scrollable: false,
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDatePicker(),
                const SizedBox(height: 24),
                Expanded(child: _buildTimelineList()),
              ],
            ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                fechaSeleccionada = fechaSeleccionada.subtract(const Duration(days: 1));
                if (fechaSeleccionada.weekday == DateTime.saturday) {
                  fechaSeleccionada = fechaSeleccionada.subtract(const Duration(days: 1));
                }
                if (fechaSeleccionada.weekday == DateTime.sunday) {
                  fechaSeleccionada = fechaSeleccionada.subtract(const Duration(days: 2));
                }
              });
              _fetchCancelados();
            },
          ),
          Column(
            children: [
              Text(
                _getDiaSemana(fechaSeleccionada),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2,'0')}-${fechaSeleccionada.day.toString().padLeft(2,'0')}",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                fechaSeleccionada = fechaSeleccionada.add(const Duration(days: 1));
                if (fechaSeleccionada.weekday == DateTime.saturday) {
                  fechaSeleccionada = fechaSeleccionada.add(const Duration(days: 2));
                }
                if (fechaSeleccionada.weekday == DateTime.sunday) {
                  fechaSeleccionada = fechaSeleccionada.add(const Duration(days: 1));
                }
              });
              _fetchCancelados();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList() {
    final dia = _getDiaSemana(fechaSeleccionada);
    final fechaStr = "${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2,'0')}-${fechaSeleccionada.day.toString().padLeft(2,'0')}";
    
    // Filtrar ocupación por aula
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: aulas.length,
      itemBuilder: (context, index) {
        final aula = aulas[index];
        final idAula = aula["id"];

        // 1. Ocupación por eventos/reservas (match por fecha)
        // Ya incluye las reservas aprobadas del historial
        final ocupacionEventos = (horariosEventos ?? []).where((h) {
          final hFecha = h["fecha"]; 
          final hIdAula = h["id_aula"] ?? h["aula_id"];
          // Importante: comparar con fecha exacta
          return h != null && hIdAula?.toString() == idAula?.toString() && hFecha == fechaStr;
        }).toList();

        // 2. Ocupación por horario recurrente (match por día)
        final ocupacionRecurrentes = (horariosRecurrentes ?? []).where((h) {
          final hIdAula = h["id_aula"] ?? h["aula_id"];
          
          if (h == null || hIdAula?.toString() != idAula?.toString() || h["dia"] != dia) {
            return false;
          }

           // Check de cancelación (Excepción)
             // Check de cancelación (Excepción)
            final esCancelado = _cancelados.any((c) {
               // 1. Match Directo por ID
               final matchId = c['horario_id'].toString() == h['id'].toString() || 
                             c['id_horario'].toString() == h['id'].toString();
               if (matchId) { // debugPrint omitted to reduce noise
                  return true;
               }

               // 2. Fallback: Match por Aula + Hora (Ignorando segundos)
               // Esto cubre casos donde el ID no cruza correctamente pero es la misma clase
               try {
                 final cAula = c['aula_id'] ?? c['id_aula'];
                 if (cAula != null && cAula.toString() != idAula.toString()) return false;

                 String cHora = (c['hora_inicio'] ?? "").toString().split(":").take(2).join(":"); // "07:00:00" -> "07:00"
                 String hHora = (h['hora_inicio'] ?? "").toString().split(":").take(2).join(":"); 
                 
                 final matchTime = (cHora == hHora) && cHora.isNotEmpty;
                 if (matchTime) {
                    print("DEBUG: Filtro cancelado por TIEMPO! Aula: ${aula['nombre']} Hora: $hHora");
                 }
                 return matchTime;
               } catch (e) {
                 return false;
               }
            });
          
          if (esCancelado) return false;

          return true;
        }).toList();

        // Unificar y mapear datos extra
        final List<Map<String, dynamic>> ocupacionHoy = [];
        
        for (var h in ocupacionEventos) {
          // Detectar si es una reserva aprobada del historial (suele tener "motivo")
          bool esReserva = h.containsKey("motivo") || (h["estado"] == "aprobada");
          
          final hIdCurso = h["id_curso"] ?? h["curso_id"];
          final curso = cursosMap[hIdCurso];
          final carName = carrerasMap[curso?["carrera_id"]] ?? (h["carrera_nombre"] ?? "");
          
          ocupacionHoy.add({
            ...h,
            "tipo": esReserva ? "Reserva" : "Evento",
            "display_carrera": esReserva ? (h["motivo"] ?? "Reserva de Espacio") : carName,
            "display_curso": esReserva ? "Reservado" : "${curso?['nombre'] ?? (h['curso_nombre']??'')} ${curso?['paralelo']??''}",
          });
        }

        for (var h in ocupacionRecurrentes) {
          final hIdCurso = h["id_curso"] ?? h["curso_id"];
          final curso = cursosMap[hIdCurso];
          final carName = carrerasMap[curso?["carrera_id"]] ?? (h["carrera_nombre"] ?? "");
          
          ocupacionHoy.add({
            ...h,
            "tipo": "Recurrente",
            "display_carrera": carName,
            "display_curso": "${curso?['nombre'] ?? (h['curso_nombre']??'')} ${curso?['paralelo']??''}",
          });
        }

        ocupacionHoy.sort((a, b) => (a["hora_inicio"] ?? "").compareTo(b["hora_inicio"] ?? ""));

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: ocupacionHoy.isEmpty ? Colors.green.shade50 : Colors.orange.shade50,
              child: Icon(
                ocupacionHoy.isEmpty ? Icons.check_circle_outline : Icons.access_time,
                color: ocupacionHoy.isEmpty ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(
              "${aula["nombre"]} ${aula["numero"] != null ? '(${aula["numero"]})' : ''}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              ocupacionHoy.isEmpty ? "Disponible todo el día" : "${ocupacionHoy.length} clases hoy",
            ),
            children: ocupacionHoy.isEmpty 
              ? [const Padding(padding: EdgeInsets.all(16), child: Text("No hay clases programadas para hoy."))]
              : ocupacionHoy.map((h) => ListTile(
                  dense: true,
                  leading: Icon(Icons.circle, size: 8, color: h["tipo"] == "Evento" ? Colors.blue : Colors.orange),
                  title: Text("${h["hora_inicio"]} - ${h["hora_fin"]}"),
                  subtitle: Text("${h["materia_nombre"] ?? 'Materia'} • ${h["display_curso"]}\n${h["display_carrera"]} • ${h["docente_nombre"]}"),
                  isThreeLine: true,
                )).toList(),
          ),
        );
      },
    );
  }
}
