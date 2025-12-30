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

  @override
  void initState() {
    super.initState();
    _cargarDatos();
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
      ]);

      final List<dynamic> aulasList = results[0] ?? [];
      final List<dynamic> eventos = results[1] ?? []; // Reservas
      final List<dynamic> docentes = results[2] ?? [];
      final List<dynamic> carreras = results[3] ?? [];
      final List<dynamic> cursos = results[4] ?? [];
      final List<dynamic> materias = results[5] ?? [];
      final List<dynamic> recurrentesRaw = results[6] ?? []; // Todo el horario docente

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
        
        recurrentesTotal.add({
          ...h,
          "docente_nombre": docente != null ? "${docente['apellidos']} ${docente['nombres']}" : "Docente #$dId",
          "materia_nombre": h["materia_nombre"] ?? mMap[hIdMateria],
        });
      }

      setState(() {
        aulas = aulasList;
        horariosEventos = eventos;
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
            },
          ),
          Column(
            children: [
              Text(
                _getDiaSemana(fechaSeleccionada),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}",
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

        // 1. Ocupación por eventos individuales (match por fecha)
        final ocupacionEventos = (horariosEventos ?? []).where((h) {
          final hFecha = h["fecha"]; // Asumiendo formato YYYY-MM-DD
          final hIdAula = h["id_aula"] ?? h["aula_id"];
          return h != null && hIdAula?.toString() == idAula?.toString() && hFecha == fechaStr;
        }).toList();

        // 2. Ocupación por horario recurrente (match por día)
        final ocupacionRecurrentes = (horariosRecurrentes ?? []).where((h) {
          final hIdAula = h["id_aula"] ?? h["aula_id"];
          return h != null && hIdAula?.toString() == idAula?.toString() && h["dia"] == dia;
        }).toList();

        // Unificar y mapear datos extra
        final List<Map<String, dynamic>> ocupacionHoy = [];
        
        for (var h in ocupacionEventos) {
          final hIdCurso = h["id_curso"] ?? h["curso_id"];
          final curso = cursosMap[hIdCurso];
          final carName = carrerasMap[curso?["carrera_id"]] ?? (h["carrera_nombre"] ?? "");
          ocupacionHoy.add({
            ...h,
            "tipo": "Evento",
            "display_carrera": carName,
            "display_curso": "${curso?['nombre'] ?? (h['curso_nombre']??'')} ${curso?['paralelo']??''}",
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
