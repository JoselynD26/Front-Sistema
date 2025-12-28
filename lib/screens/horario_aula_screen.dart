import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import 'horario_aula_form.dart';
import 'horario_form.dart';

class HorarioAulaScreen extends StatefulWidget {
  final int idSede;
  final int aulaId;
  final String aulaNombre;

  const HorarioAulaScreen({
    super.key,
    required this.idSede,
    required this.aulaId,
    required this.aulaNombre,
  });

  @override
  State<HorarioAulaScreen> createState() => _HorarioAulaScreenState();
}

class _HorarioAulaScreenState extends State<HorarioAulaScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> horarios = [];
  Map<int, String> carrerasMap = {};
  Map<int, Map<String, dynamic>> cursosMap = {};
  Map<int, String> materiasMap = {};
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    setState(() => cargando = true);
    try {
      final results = await Future.wait<dynamic>([
        _apiService.listarHorariosPorSede(widget.idSede),
        _apiService.listarDocentesPorSede(widget.idSede),
        _apiService.listarCarreras(),
        _apiService.listarCursosPorSede(widget.idSede),
        _apiService.listarMateriasPorSede(widget.idSede),
      ]);

      final List<dynamic> eventosTotal = results[0] ?? [];
      final List<dynamic> docentes = results[1] ?? [];
      final List<dynamic> carreras = results[2] ?? [];
      final List<dynamic> cursos = results[3] ?? [];
      final List<dynamic> materias = results[4] ?? [];

      final Map<int, String> caMap = {};
      for (var c in carreras) {
        if (c != null && c["id"] != null) caMap[c["id"]] = c["nombre"] ?? "";
      }

      final Map<int, Map<String, dynamic>> cuMap = {};
      for (var c in cursos) {
        if (c != null && c["id"] != null) cuMap[c["id"]] = c;
      }

      final Map<int, String> maMap = {};
      for (var m in materias) {
        if (m != null && m["id"] != null) maMap[m["id"]] = m["nombre"] ?? "";
      }

      // Cargar horarios recurrentes de todos los docentes
      final List<dynamic> recurrentesTotal = [];
      try {
        final teacherSchedules = await Future.wait(
          docentes.map((d) => _apiService.obtenerHorarioDocente(d["id"]))
        );
        
        for (var i = 0; i < teacherSchedules.length; i++) {
          final list = teacherSchedules[i];
          final docente = docentes[i];
          if (list != null) {
            for (var h in list) {
              final hIdMateria = h["id_materia"] ?? h["materia_id"];
              recurrentesTotal.add({
                ...h,
                "docente_nombre": "${docente['apellidos']} ${docente['nombres']}",
                "materia_nombre": h["materia_nombre"] ?? maMap[hIdMateria],
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error al cargar horarios recurrentes del docente: $e");
      }

      // Unificar y filtrar por aula
      final List<dynamic> mergeHorarios = [];
      
      // Agregar eventos individuales del aula
      for (var h in (eventosTotal ?? [])) {
        final hIdAula = h["id_aula"] ?? h["aula_id"];
        if (hIdAula?.toString() == widget.aulaId.toString()) {
          final hIdCurso = h["id_curso"] ?? h["curso_id"];
          final curso = cuMap[hIdCurso];
          final carName = caMap[curso?["carrera_id"]] ?? (h["carrera_nombre"] ?? "");
          mergeHorarios.add({
            ...h,
            "tipo": "Evento",
            "display_carrera": carName,
            "display_curso": "${curso?['nombre'] ?? (h['curso_nombre']??'')} ${curso?['paralelo']??''}",
          });
        }
      }

      // Agregar horarios recurrentes del aula
      for (var h in (recurrentesTotal ?? [])) {
        final hIdAula = h["id_aula"] ?? h["aula_id"];
        if (hIdAula?.toString() == widget.aulaId.toString()) {
          final hIdCurso = h["id_curso"] ?? h["curso_id"];
          final curso = cuMap[hIdCurso];
          final carName = caMap[curso?["carrera_id"]] ?? (h["carrera_nombre"] ?? "");
          mergeHorarios.add({
            ...h,
            "tipo": "Recurrente",
            "display_carrera": carName,
            "display_curso": "${curso?['nombre'] ?? (h['curso_nombre']??'')} ${curso?['paralelo']??''}",
          });
        }
      }

      setState(() {
        horarios = mergeHorarios;
        carrerasMap = caMap;
        cursosMap = cuMap;
        materiasMap = maMap;
        cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar horarios: $e")),
        );
      }
    }
  }

  Future<void> _eliminarHorario(dynamic h) async {
    bool ok = false;
    final id = h["id"];
    
    if (h["tipo"] == "Recurrente") {
      ok = await _apiService.eliminarHorarioDocente(id);
    } else {
      ok = await _apiService.eliminarHorario(id);
    }
    
    if (ok) {
      _cargarHorarios();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Horario eliminado exitosamente")),
      );
    }
  }

  void _abrirEdicion(dynamic h) async {
    Widget form;
    final Map<String, dynamic> horarioMap = Map<String, dynamic>.from(h as Map);
    
    if (h["tipo"] == "Recurrente") {
      form = HorarioAulaForm(
        idSede: widget.idSede,
        aulaId: widget.aulaId,
        aulaNombre: widget.aulaNombre,
        horario: horarioMap,
        onSave: _cargarHorarios,
      );
    } else {
      form = HorarioForm(
        idSede: widget.idSede,
        horario: horarioMap,
        onSave: _cargarHorarios,
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => form),
    );

    if (result == true) {
      _cargarHorarios();
    }
  }

  void _abrirFormulario() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HorarioAulaForm(
          idSede: widget.idSede,
          aulaId: widget.aulaId,
          aulaNombre: widget.aulaNombre,
          onSave: _cargarHorarios,
        ),
      ),
    );

    if (result == true) {
      _cargarHorarios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Horario: ${widget.aulaNombre}",
      subtitle: "Gestión de ocupación semanal del aula",
      idSede: widget.idSede,
      onAdd: _abrirFormulario,
      addLabel: "Agregar Ocupación",
      scrollable: false,
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : horarios.isEmpty
              ? _buildEmptyState()
              : _buildListaHorarios(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No hay horarios registrados para esta aula",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _abrirFormulario,
            icon: const Icon(Icons.add),
            label: const Text("Registrar primer horario"),
          ),
        ],
      ),
    );
  }

  Widget _buildListaHorarios() {
    // Agrupar por día para mejor visualización (solo días válidos)
    final Map<String, List<dynamic>> porDia = {};
    final diasValidos = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    
    for (var h in (horarios ?? [])) {
      if (h == null) continue;
      final dia = h["dia"];
      
      // Solo agregar si tiene un día válido
      if (dia != null && diasValidos.contains(dia)) {
        porDia.putIfAbsent(dia, () => []);
        porDia[dia]!.add(h);
      }
    }

    // Orden de días
    final diasPresentes = porDia.keys.toList();
    diasPresentes.sort((a, b) => diasValidos.indexOf(a).compareTo(diasValidos.indexOf(b)));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: diasPresentes.length,
      itemBuilder: (context, index) {
        final dia = diasPresentes[index];
        final items = porDia[dia]!;
        items.sort((a, b) => (a["hora_inicio"] ?? "").compareTo(b["hora_inicio"] ?? ""));

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_view_day, color: Colors.indigo, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      dia,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((h) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.access_time, color: Colors.blue, size: 20),
                ),
                title: Text(
                  "${h["hora_inicio"]} - ${h["hora_fin"]}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${h["materia_nombre"] ?? 'Materia'} - ${h["display_curso"]}\n${h["display_carrera"]} • ${h["docente_nombre"] ?? 'Docente'}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _abrirEdicion(h),
                      tooltip: "Editar",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmarEliminar(h),
                      tooltip: "Eliminar",
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  void _confirmarEliminar(dynamic h) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar Horario"),
        content: Text("¿Estás seguro de eliminar el horario de ${h["dia"]} ${h["hora_inicio"]}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarHorario(h);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }
}
