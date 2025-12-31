import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/web_layout.dart';
import 'pdf_horarios_screen.dart';
import 'croquis_screen.dart';
import 'docente_croquis_screen.dart';
import 'croquis_plaza_screen.dart';

class ProfesorDashboard extends StatefulWidget {
  final int docenteId;
  final String nombreProfesor;

  const ProfesorDashboard({
    super.key,
    required this.docenteId,
    required this.nombreProfesor,
  });

  @override
  _ProfesorDashboardState createState() => _ProfesorDashboardState();
}

class _ProfesorDashboardState extends State<ProfesorDashboard> {
  final _apiService = ApiService();
  List<dynamic> materias = [];
  List<dynamic> horarios = [];
  List<dynamic> reservas = [];
  List<dynamic> cursos = []; // Lista de cursos para lookup
  List<dynamic> aulas = []; // Lista de aulas para lookup
  Map<String, dynamic> miEscritorio = {};
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final results = await Future.wait([
        _apiService.obtenerMisMaterias(widget.docenteId),
        _apiService.obtenerHorarioDocente(widget.docenteId), // Usar mismo endpoint que admin
        _apiService.obtenerMisReservas(widget.docenteId),
        _apiService.listarCursosPorSede(1), // Fetch cursos (Sede 1 fixed for now)
        _apiService.listarAulasPorSede(1), // Fetch aulas (Sede 1 fixed for now)
      ]);

      setState(() {
        materias = results[0] as List<dynamic>;
        
        // Normalizar horarios para asegurar compatibilidad con la vista
        final rawHorarios = results[1] as List<dynamic>;
        horarios = rawHorarios.map((h) {
          final map = Map<String, dynamic>.from(h);
          // Asegurar materia_id
          if (!map.containsKey('materia_id') && map.containsKey('id_materia')) {
            map['materia_id'] = map['id_materia'];
          }
           // Asegurar aula_id
          if (!map.containsKey('aula_id') && map.containsKey('id_aula')) {
            map['aula_id'] = map['id_aula'];
          }
          // Asegurar curso_id
          if (!map.containsKey('curso_id') && map.containsKey('id_curso')) {
            map['curso_id'] = map['id_curso'];
          }
          return map;
        }).toList();

        reservas = results[2] as List<dynamic>;
        cursos = results[3] as List<dynamic>;
        aulas = results[4] as List<dynamic>;
        cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar datos: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebLayout(
      title: "Panel Docente",
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          widget.nombreProfesor.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _editarPerfil,
                              child: Text(
                                "Hola, ${widget.nombreProfesor}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Panel de Gestión Académica",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ], // Closes Row
                  ), // Closes Container child
                ), // Closes Container
                
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 28,
                      color: const Color(0xFF1E293B),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Accesos Rápidos",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Grid de módulos
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 3 : 2),
                      crossAxisSpacing: 32,
                      mainAxisSpacing: 32,
                      childAspectRatio: 1.2,
                      children: [
                        _buildModuleCard(
                        "Croquis Institucional",
                        Icons.map_rounded,
                        "Ubicación general",
                        const Color(0xFF6366F1),
                        () => _verCroquisPlazas(),
                      ),

                        _buildModuleCard(
                          "Mis Materias",
                          Icons.menu_book_rounded,
                          "${materias.length} asignadas",
                          const Color(0xFF3B82F6), // Blue
                          () => _mostrarMaterias(),
                        ),
                        _buildModuleCard(
                          "Mi Horario",
                          Icons.calendar_month_rounded,
                          "${horarios.length} clases",
                          const Color(0xFF10B981), // Emerald
                          () => _mostrarHorarios(),
                        ),
                        _buildModuleCard(
                          "Mis Reservas",
                          Icons.bookmark_rounded,
                          "${reservas.length} activas",
                          const Color(0xFF8B5CF6), // Violet
                          () => _mostrarReservas(),
                        ),
                        _buildModuleCard(
                          "Reservar Aula",
                          Icons.add_circle_outline_rounded,
                          "Nueva solicitud",
                          const Color(0xFFF59E0B), // Amber
                          () => _crearReserva(),
                        ),
                        _buildModuleCard(
                          "Horarios PDF",
                          Icons.picture_as_pdf_rounded,
                          "Descargar",
                          const Color(0xFFEF4444), // Red
                          () => _verHorarios(),
                        ),
                        _buildModuleCard(
                          "Sala de Profesores",
                          Icons.desk,
                          "Mi escritorio",
                          const Color(0xFF10B981),
                          () => _verCroquis(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildModuleCard(
    String title,
    IconData icon,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 15,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editarPerfil() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _EditarPerfilDialog(
          docenteId: widget.docenteId,
          nombreActual: widget.nombreProfesor,
        );
      },
    );
  }

  void _mostrarMaterias() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _PremiumDialog(
          title: "Mis Materias",
          subtitle: "Asignaturas impartidas este periodo",
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF3B82F6),
          child: ListView.separated(
            padding: const EdgeInsets.all(4),
            itemCount: materias.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final materia = materias[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.book, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            materia["nombre"],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.school, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Carreras: ${materia["carreras"].map((c) => c["nombre"]).join(", ")}",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _mostrarHorarios() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _HorarioCalendarioDialog(
          horarios: horarios,
          materias: materias,
          cursos: cursos,
          aulas: aulas,
        );
      },
    );
  }


  void _mostrarReservas() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _PremiumDialog(
          title: "Mis Reservas",
          subtitle: "Historial de solicitudes de aulas",
          icon: Icons.bookmark_rounded,
          color: const Color(0xFF8B5CF6),
          child: reservas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No tienes reservas activas",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(4),
                  itemCount: reservas.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final reserva = reservas[index];
                    Color statusColor = reserva["estado"] == "aprobada"
                        ? Colors.green
                        : reserva["estado"] == "pendiente"
                            ? Colors.orange
                            : Colors.red;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.meeting_room, color: statusColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reserva["aula_nombre"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${reserva["fecha"]} • ${reserva["hora"]}",
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    reserva["estado"].toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (reserva["estado"] == "pendiente" || reserva["estado"] == "aprobada")
                            IconButton(
                              icon:  Icon(Icons.cancel_outlined, color: reserva["estado"] == "aprobada" ? Colors.orange : Colors.red),
                              onPressed: () async {
                                final message = reserva["estado"] == "aprobada" 
                                   ? "¿Deseas liberar esta aula? Volverá a estar disponible para otros docentes."
                                   : "¿Deseas cancelar esta solicitud?";
                                
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(reserva["estado"] == "aprobada" ? "Liberar Aula" : "Cancelar Solicitud"),
                                    content: Text(message),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sí, proceder", style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  bool success;
                                  if (reserva["estado"] == "aprobada") {
                                    // Para aprobadas, usamos eliminar (DELETE) porque el endpoint cancelar (POST) 
                                    // prohibe cancelar aprobadas en el backend actual.
                                    success = await _apiService.eliminarReserva(reserva["id"]);
                                  } else {
                                    success = await _apiService.cancelarReservaAula(reserva["id"], widget.docenteId);
                                  }

                                  if (success) {
                                    Navigator.pop(context);
                                    _cargarDatos();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(reserva["estado"] == "aprobada" 
                                          ? "Aula liberada exitosamente" 
                                          : "Solicitud cancelada exitosamente")),
                                    );
                                  }
                                }
                              },
                              tooltip: reserva["estado"] == "aprobada" ? "Liberar aula" : "Cancelar solicitud",
                            ),
                          // Botón de eliminar (Basurero)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Eliminar Reserva"),
                                  content: const Text("¿Estás seguro? Se eliminará del historial permanentemente."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                final success = await _apiService.eliminarReserva(reserva["id"]);
                                if (success) {
                                  // Refresh local list closing dialog and reopening or just refreshing if state management allowed (Dialog is general dialog).
                                  // Since it's a dialog with local list 'reservas', I need to refresh it.
                                  // But `reservas` comes from `_cargarDatos`. If I close and reopen or setState...
                                  // This is inside `_mostrarReservas` which uses `reservas` from the parent widget state.
                                  // I should close the dialog and reload or ideally setState inside this builder if it were stateful.
                                  // For simplicity and matching current flow: Close and Reload.
                                  Navigator.pop(context); 
                                  _cargarDatos();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Reserva eliminada")),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Error al eliminar")),
                                  );
                                }
                              }
                            },
                            tooltip: "Eliminar del historial",
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }



  void _crearReserva() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _FormularioReservaAula(docenteId: widget.docenteId);
      },
    ).then((result) {
      if (result == true) {
        _cargarDatos(); // Recargar datos si se creó una reserva
      }
    });
  }



  void _cerrarSesion() async {
    await _apiService.logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _verHorarios() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _PremiumDialog(
          title: "Horarios PDF",
          subtitle: "Descarga de horarios oficiales",
          icon: Icons.picture_as_pdf_rounded,
          color: const Color(0xFFEF4444),
          child: PdfHorariosContent(sedeId: 1), // Sede ID fija por ahora o dinámica
        );
      },
    );
  }

  void _verCroquisPlazas() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _PremiumDialog(
          title: "Croquis Institucional",
          subtitle: "Mapas de patios y plazas",
          icon: Icons.map_rounded,
          color: const Color(0xFF6366F1),
          child: CroquisPlazaContent(sedeId: 1), // Sede ID fija por ahora o dinámica
        );
      },
    );
  }

  void _verCroquis() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _PremiumDialog(
          title: "Sala de Profesores",
          subtitle: "Mi ubicación y escritorio asignado",
          icon: Icons.desk_rounded,
          color: const Color(0xFF10B981),
          child: DocenteCroquisContent(docenteId: widget.docenteId),
        );
      },
    );
  }



  void _verHorarioAulas() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _HorarioAulasDialog();
      },
    );
  }

  void _cancelarClase(int horarioId) async {
    // Mostrar confirmación
    // Mostrar confirmación
    final confirmar = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _PremiumDialog(
          title: "Cancelar Clase",
          subtitle: "¿Estás seguro de que quieres cancelar esta clase?",
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Esta acción notificará a los estudiantes y administrativos. No se puede deshacer.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Mantener Clase"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Sí, Cancelar"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmar == true) {
      // Cancelar horario usando endpoint específico
      final success = await _apiService.cancelarHorario(horarioId);
      
      if (success) {
        _cargarDatos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Clase cancelada exitosamente"),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al cancelar la clase"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _HorarioAulasDialog extends StatefulWidget {
  @override
  _HorarioAulasDialogState createState() => _HorarioAulasDialogState();
}

class _HorarioAulasDialogState extends State<_HorarioAulasDialog> {
  final _apiService = ApiService();
  final _fechaController = TextEditingController();
  List<dynamic> horarioAulas = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toString().split(' ')[0];
    _cargarHorarioAulas();
  }

  Future<void> _cargarHorarioAulas() async {
    if (_fechaController.text.isEmpty) return;
    setState(() => cargando = true);
    try {
      final datos = await _apiService.obtenerHorarioAulas(1, _fechaController.text);
      setState(() {
        horarioAulas = datos;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumDialog(
      title: "Horario de Ocupación",
      subtitle: "Disponibilidad de aulas por fecha",
      icon: Icons.view_timeline_rounded,
      color: const Color(0xFF3B82F6),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
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
                        _cargarHorarioAulas();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            _fechaController.text.isEmpty 
                                ? "Seleccionar fecha" 
                                : _fechaController.text,
                            style: TextStyle(
                              color: _fechaController.text.isEmpty 
                                  ? Colors.grey 
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: cargando ? null : _cargarHorarioAulas,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Actualizar"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: horarioAulas.length,
                      itemBuilder: (context, index) {
                        final aula = horarioAulas[index];
                        final ocupaciones = aula["ocupaciones"] as List;
                        return Card(
                          child: ExpansionTile(
                            leading: Icon(
                              Icons.meeting_room,
                              color: aula["disponible"] ? Colors.green : Colors.red,
                            ),
                            title: Text(aula["nombre"]),
                            subtitle: Text(
                              "Capacidad: ${aula["capacidad"]} | ${ocupaciones.length} ocupación(es)",
                            ),
                            children: ocupaciones.isEmpty
                                ? [const ListTile(title: Text("Disponible todo el día"))]
                                : ocupaciones.map<Widget>((ocupacion) {
                                    return ListTile(
                                      leading: Icon(
                                        ocupacion["tipo"] == "reserva" 
                                            ? Icons.event_available 
                                            : Icons.school,
                                        color: ocupacion["tipo"] == "reserva" 
                                            ? Colors.orange 
                                            : Colors.blue,
                                      ),
                                      title: Text(
                                        "${ocupacion["hora_inicio"]} - ${ocupacion["hora_fin"]}",
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Profesor: ${ocupacion["profesor"]}"),
                                          Text("${ocupacion["tipo"] == "reserva" ? "Motivo" : "Materia"}: ${ocupacion["materia"]}"),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: ocupacion["tipo"] == "reserva" 
                                              ? Colors.orange 
                                              : Colors.blue,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          ocupacion["tipo"].toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorarioCalendarioDialog extends StatefulWidget {
  final List<dynamic> horarios;
  final List<dynamic> materias;
  final List<dynamic> cursos; // Nueva lista para cruzar datos
  final List<dynamic> aulas; // Nueva lista para cruzar datos

  const _HorarioCalendarioDialog({
    required this.horarios,
    required this.materias,
    required this.cursos,
    required this.aulas,
  });

  @override
  _HorarioCalendarioDialogState createState() => _HorarioCalendarioDialogState();
}

class _HorarioCalendarioDialogState extends State<_HorarioCalendarioDialog> {
  DateTime fechaSeleccionada = DateTime.now();
  
  // Cache de nombres
  String _getMateriaNombre(int? id) {
     if (id == null) return 'Materia ?';
     final materia = widget.materias.cast<dynamic>().firstWhere(
        (m) => m['id'] == id, 
        orElse: () => null
     );
     return materia != null ? materia['nombre'] : 'Materia ?';
  }

  String _getCursoNombre(int? id) {
     if (id == null) return '';
     final curso = widget.cursos.cast<dynamic>().firstWhere(
        (c) => c['id'] == id, 
        orElse: () => null
     );
     // Ajusta según la estructura real de tu curso (nombre + paralelo)
     if (curso != null) {
       return "${curso['nombre'] ?? ''} ${curso['paralelo'] ?? ''}".trim();
     }
     return '';
  }

  String _getAulaNombre(int? id) {
     if (id == null) return '';
     final aula = widget.aulas.cast<dynamic>().firstWhere(
        (a) => a['id'] == id, 
        orElse: () => null
     );
     return aula != null ? "${aula['numero']} - ${aula['nombre']}" : "Aula $id";
  }

  LinearGradient _getColorForMateria(String nombreMateria) {
    // Paleta Pastel Profesional
    final gradients = [
      const LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Blue 100-200
      const LinearGradient(colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Emerald 100-200
      const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Violet 100-200
      const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Amber 100-200
      const LinearGradient(colors: [Color(0xFFFEE2E2), Color(0xFFFECACA)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Red 100-200
      const LinearGradient(colors: [Color(0xFFFCE7F3), Color(0xFFFBCFE8)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Pink 100-200
      const LinearGradient(colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Indigo 100-200
      const LinearGradient(colors: [Color(0xFFCCFBF1), Color(0xFF99F6E4)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Teal 100-200
    ];
    
    final hash = nombreMateria.codeUnits.fold(0, (prev, element) => prev + element);
    return gradients[hash % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 1000,
        height: 800,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text(
                      "Mi Horario Semanal",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatearFecha(fechaSeleccionada),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                        onPressed: () => _cambiarSemana(-1),
                         icon: const Icon(Icons.chevron_left)),
                    TextButton.icon(
                      onPressed: _seleccionarFecha,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("Cambiar Semana"),
                    ),
                    IconButton(
                        onPressed: () => _cambiarSemana(1),
                        icon: const Icon(Icons.chevron_right)),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildCalendarioSemanal()),
          ],
        ),
      ),
    );
  }
  
  void _cambiarSemana(int direccion) {
    setState(() {
      fechaSeleccionada = fechaSeleccionada.add(Duration(days: 7 * direccion));
    });
  }
  
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fecha != null) {
      setState(() {
        fechaSeleccionada = fecha;
      });
    }
  }
  
  String _formatearFecha(DateTime fecha) {
    final lunes = fecha.subtract(Duration(days: fecha.weekday - 1));
    final viernes = lunes.add(const Duration(days: 4));
    return "${lunes.day}/${lunes.month} - ${viernes.day}/${viernes.month}/${viernes.year}";
  }
  
  Widget _buildCalendarioSemanal() {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    const horas = [
      '07:00 - 08:00', '08:00 - 09:00', '09:00 - 10:00', 
      '10:00 - 11:00', '11:00 - 12:00', '12:00 - 13:00', 
      '13:00 - 14:00', '14:00 - 15:00', '15:00 - 16:00', 
      '16:00 - 17:00', '17:00 - 17:50', '17:50 - 18:40', 
      '18:40 - 19:30', '19:30 - 20:20', '20:20 - 21:10'
    ];

    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: const {
          0: FixedColumnWidth(80),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
          4: FlexColumnWidth(),
          5: FlexColumnWidth(),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Hora',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              ...dias.asMap().entries.map((entry) {
                final index = entry.key;
                final dia = entry.value;
                final fechaDia = _obtenerFechaDia(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        dia,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${fechaDia.day}/${fechaDia.month}",
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          ...horas.map((hora) => TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            children: [
              Container(
                height: 85, // Un poco más alto para elegancia y evitar overflow
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4),
                color: const Color(0xFFF8FAFC), // Fondo muy suave para la hora
                child: Text(
                  hora,
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.grey.shade600
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ...dias.asMap().entries.map((entry) {
                final index = entry.key;
                final dia = entry.value;
                final fechaDia = _obtenerFechaDia(index);
                return _buildCeldaHorario(dia, hora, fechaDia);
              }).toList(),
            ],
          )).toList(),
        ],
      ),
    );
  }
  
  DateTime _obtenerFechaDia(int indiceDia) {
    final lunes = fechaSeleccionada.subtract(Duration(days: fechaSeleccionada.weekday - 1));
    return lunes.add(Duration(days: indiceDia));
  }

  Widget _buildCeldaHorario(String dia, String hora, DateTime fechaDia) {
    final horario = widget.horarios.cast<dynamic>().firstWhere(
      (h) {
        final partsBloque = hora.split(' - ');
        final inicioBloque = _parseHora(partsBloque[0]);
        
        final inicioClase = _parseHora(h['hora_inicio']);
        final finClase = _parseHora(h['hora_fin']);

        String normalize(String s) => s.toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u');

        final diaApi = normalize(h['dia']?.toString() ?? "");
        final diaColumna = normalize(dia);
        
        final diaCoincide = diaApi == diaColumna;
        final horaCoincide = (inicioBloque >= inicioClase) && (inicioBloque < finClase);
        
        // Relax fecha check (Always true for now)
        bool fechaCoincide = true;
        
        return diaCoincide && horaCoincide && fechaCoincide;
      },
      orElse: () => null,
    );
    
    final materiaNombre = horario != null ? _getMateriaNombre(horario['materia_id']) : '';

    return Container(
      height: 85,
      padding: const EdgeInsets.all(3),
      child: horario != null
          ? Container(
              decoration: BoxDecoration(
                gradient: _getColorForMateria(materiaNombre),
                borderRadius: BorderRadius.circular(12), // Bordes más redondeados
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), // Sombra muy sutil
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getMateriaNombre(horario['materia_id']), 
                    style: TextStyle(
                      color: Colors.grey.shade800, // Texto oscuro
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_getCursoNombre(horario['curso_id']).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCursoNombre(horario['curso_id']),
                          style: TextStyle(
                            color: Colors.grey.shade900,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (horario['aula_id'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _getAulaNombre(horario['aula_id']), 
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 9,
                          fontStyle: FontStyle.italic
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }
  
  bool _esMismaFecha(dynamic fechaHorario, DateTime fechaDia) {
    if (fechaHorario == null) return false;
    
    try {
      DateTime fechaH;
      if (fechaHorario is String) {
        fechaH = DateTime.parse(fechaHorario);
      } else if (fechaHorario is DateTime) {
        fechaH = fechaHorario;
      } else {
        return false;
      }
      
      return fechaH.year == fechaDia.year &&
             fechaH.month == fechaDia.month &&
             fechaH.day == fechaDia.day;
    } catch (e) {
      return false;
    }
  }

  bool _estaEnRangoHora(String horaActual, String? horaInicio, String? horaFin) {
    if (horaInicio == null || horaFin == null) return false;
    
    try {
      final actual = _parseHora(horaActual);
      final inicio = _parseHora(horaInicio);
      final fin = _parseHora(horaFin);
      
      return actual >= inicio && actual < fin;
    } catch (e) {
      return false;
    }
  }

  int _parseHora(String? hora) {
    if (hora == null) return -1;
    try {
      final parts = hora.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return h * 60 + m;
    } catch (e) {
      return -1;
    }
  }
}

class _FormularioReservaAula extends StatefulWidget {
  final int docenteId;

  const _FormularioReservaAula({required this.docenteId});

  @override
  _FormularioReservaAulaState createState() => _FormularioReservaAulaState();
}

class _FormularioReservaAulaState extends State<_FormularioReservaAula> {
  final _apiService = ApiService();
  final _fechaController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();
  final _motivoController = TextEditingController(text: "Clase adicional");
  
  List<dynamic> aulasDisponibles = [];
  int? aulaSeleccionada;
  bool cargando = false;
  bool buscandoAulas = false;

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toString().split(' ')[0];
    
    // Limpiar resultados si cambian los filtros para obligar a buscar de nuevo
    void limpiarResultados() {
      if (aulasDisponibles.isNotEmpty) {
        setState(() {
          aulasDisponibles = [];
          aulaSeleccionada = null;
        });
      }
    }
    _fechaController.addListener(limpiarResultados);
    _horaInicioController.addListener(limpiarResultados);
    _horaFinController.addListener(limpiarResultados);
  }

  Future<void> _seleccionarHora(TextEditingController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = "$hour:$minute";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumDialog(
      title: "Reservar Aula",
      subtitle: "Solicita un espacio físico para actividades adicionales",
      icon: Icons.add_circle_outline_rounded,
      color: const Color(0xFFF59E0B),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Formulario de búsqueda
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (fecha != null) {
                                setState(() {
                                  _fechaController.text = fecha.toString().split(' ')[0];
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Text(
                                    _fechaController.text.isEmpty 
                                        ? "Seleccionar fecha" 
                                        : _fechaController.text,
                                    style: TextStyle(
                                      color: _fechaController.text.isEmpty 
                                          ? Colors.grey 
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _horaInicioController,
                            readOnly: true,
                            onTap: () => _seleccionarHora(_horaInicioController),
                            decoration: const InputDecoration(
                              labelText: "Hora Inicio",
                              hintText: "14:00",
                              prefixIcon: Icon(Icons.access_time),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _horaFinController,
                            readOnly: true,
                            onTap: () => _seleccionarHora(_horaFinController),
                            decoration: const InputDecoration(
                              labelText: "Hora Fin",
                              hintText: "16:00",
                              prefixIcon: Icon(Icons.access_time_filled),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: buscandoAulas ? null : _buscarAulasDisponibles,
                        icon: buscandoAulas
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(buscandoAulas ? "Buscando..." : "Buscar Aulas Disponibles"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tabla de aulas disponibles
            if (aulasDisponibles.isNotEmpty) ...[
              const Text(
                "Aulas Disponibles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Aula",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Capacidad",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Tipo",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Seleccionar",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: aulasDisponibles.length,
                          itemBuilder: (context, index) {
                            final aula = aulasDisponibles[index];
                            final isSelected = aulaSeleccionada == aula["id"];
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF6B35).withOpacity(0.1) : null,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                title: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.meeting_room,
                                            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            aula["nombre"],
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? const Color(0xFFFF6B35) : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text("${aula["capacidad"]} personas"),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          aula["tipo"] ?? "Aula",
                                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Radio<int>(
                                          value: aula["id"],
                                          groupValue: aulaSeleccionada,
                                          onChanged: (value) => setState(() => aulaSeleccionada = value),
                                          activeColor: const Color(0xFFFF6B35),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => setState(() => aulaSeleccionada = aula["id"]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Campo de motivo
              TextField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: "Motivo de la reserva",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ] else if (!buscandoAulas && _fechaController.text.isNotEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No se encontraron aulas disponibles",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Intenta con otra fecha u horario",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "Ingresa fecha y horarios para buscar aulas",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Botones de acción
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: (aulaSeleccionada != null && !cargando) ? _crearReserva : null,
                  icon: cargando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(cargando ? "Creando..." : "Confirmar Reserva"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _parseHora(String hora) {
    if (hora.isEmpty) return 0.0;
    final parts = hora.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h + (m / 60.0);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return "Lunes";
      case 2: return "Martes";
      case 3: return "Miércoles";
      case 4: return "Jueves";
      case 5: return "Viernes";
      case 6: return "Sábado";
      case 7: return "Domingo";
      default: return "";
    }
  }

  Future<void> _buscarAulasDisponibles() async {
    if (_fechaController.text.isEmpty || _horaInicioController.text.isEmpty || _horaFinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa fecha, hora de inicio y hora de fin")),
      );
      return;
    }

    setState(() => buscandoAulas = true);

    try {
      final fechaDate = DateTime.parse(_fechaController.text);
      final diaSemana = _getDayName(fechaDate.weekday);
      final inicioSolicitado = _parseHora(_horaInicioController.text);
      final finSolicitado = _parseHora(_horaFinController.text);

      print("DEBUG: Iniciando Busqueda Exhaustiva para $diaSemana ${_fechaController.text} ($inicioSolicitado - $finSolicitado)");

      // 1. Obtener datos basicos: Aulas, Eventos y Horario Diario (Reservas + Ocupación)
      final resultsBasicos = await Future.wait([
        _apiService.listarAulasPorSede(1),
        _apiService.listarHorariosPorSede(1), // Eventos con fecha especifica
        _apiService.listarDocentesPorSede(1), // Lista de todos los profes para ver sus recurrentes
        _apiService.obtenerHorarioAulas(1, _fechaController.text), // NUEVO: Horario diario consolidado
      ]);

      final todasLasAulas = resultsBasicos[0] as List<dynamic>;
      final eventosPorFecha = resultsBasicos[1] as List<dynamic>;
      final docentes = resultsBasicos[2] as List<dynamic>;
      final horarioDiario = resultsBasicos[3] as List<dynamic>;

      // 2. Obtener Horarios Recurrentes de TODOS los docentes (Pesado pero necesario)
      print("DEBUG: Fetcheando horarios de ${docentes.length} docentes...");
      final teacherSchedules = await Future.wait(
        docentes.map((d) => _apiService.obtenerHorarioDocente(d["id"]))
      );

      // 3. Aplanar la lista de recurrentes
      final List<dynamic> horarioRecurrenteTotal = [];
      for (var list in teacherSchedules) {
        if (list != null) {
          horarioRecurrenteTotal.addAll(list as List<dynamic>);
        }
      }
      
      print("DEBUG: Total Recurrentes Globales: ${horarioRecurrenteTotal.length}");
      print("DEBUG: Total Eventos Por Fecha: ${eventosPorFecha.length}");
      print("DEBUG: Items Horario Diario: ${horarioDiario.length}");

      // 4. Filtrar aulas disponibles
      final disponibles = todasLasAulas.where((aula) {
        bool ocupada = false;

        // --- A. Revisar Horario Recurrente (Clases Semanales) ---
        final clasesRecurrentesAula = horarioRecurrenteTotal.where((h) {
          final hAulaId = h['aula_id'] ?? h['id_aula'];
          final hDia = h['dia'];
          return hAulaId.toString() == aula['id'].toString() && 
                 hDia.toString().toLowerCase() == diaSemana.toLowerCase();
        });

        for (var clase in clasesRecurrentesAula) {
          final start = _parseHora(clase['hora_inicio']);
          final end = _parseHora(clase['hora_fin']);
          
          if (inicioSolicitado < end && finSolicitado > start) {
            print("   >>> CONFLICTO RECURRENTE en ${aula['nombre']}: ${clase['hora_inicio']} - ${clase['hora_fin']} (${clase['materia_nombre'] ?? 'Clase'})");
            ocupada = true;
            break;
          }
        }
        if (ocupada) return false;

        // --- B. Revisar Eventos por Fecha (Excepciones) ---
        final eventosFechaAula = eventosPorFecha.where((h) {
          final hAulaId = h['aula_id'] ?? h['id_aula'];
          final hFecha = h['fecha'];
          return hAulaId.toString() == aula['id'].toString() && 
                 hFecha != null && 
                 hFecha.toString() == _fechaController.text;
        });

        for (var evento in eventosFechaAula) {
          final start = _parseHora(evento['hora_inicio']);
          final end = _parseHora(evento['hora_fin']);

          if (inicioSolicitado < end && finSolicitado > start) {
             print("   >>> CONFLICTO FECHA en ${aula['nombre']}: ${evento['hora_inicio']} - ${evento['hora_fin']} (Evento)");
             ocupada = true;
             break;
          }
        }
        if (ocupada) return false;

        // --- C. Revisar Ocupación Diaria de Aulas (Consolidado: Reservas + Otros) ---
        // Buscamos el objeto correspondiente a esta aula en horarioDiario
        final infoAula = horarioDiario.firstWhere(
          (item) => item['id'].toString() == aula['id'].toString(),
          orElse: () => null
        );

        if (infoAula != null && infoAula['ocupaciones'] != null) {
          final ocupaciones = infoAula['ocupaciones'] as List<dynamic>;
          for (var ocup in ocupaciones) {
             final start = _parseHora(ocup['hora_inicio']);
             final end = _parseHora(ocup['hora_fin']);
             
             if (inicioSolicitado < end && finSolicitado > start) {
               print("   >>> CONFLICTO DIARIO en ${aula['nombre']}: ${ocup['hora_inicio']} - ${ocup['hora_fin']} (${ocup['tipo'] ?? 'Ocupado'})");
               ocupada = true;
               break;
             }
          }
        }
        if (ocupada) return false;

        return true; 
      }).toList();

      print("DEBUG: Aulas Disponibles Final: ${disponibles.length}");

      setState(() {
        aulasDisponibles = disponibles;
        aulaSeleccionada = null;
        buscandoAulas = false;
      });

      if (disponibles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No hay aulas disponibles en ese horario")),
        );
      }
    } catch (e) {
      setState(() => buscandoAulas = false);
      print("ERROR DETECTADO: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al buscar disponibilidad: $e")),
      );
    }
  }

  Future<void> _crearReserva() async {
    setState(() => cargando = true);

    try {
      final success = await _apiService.crearReservaAulaConRango(
        _fechaController.text,
        _horaInicioController.text,
        _horaFinController.text,
        aulaSeleccionada!,
        widget.docenteId,
        _motivoController.text,
      );

      setState(() => cargando = false);

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reserva creada exitosamente")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al crear reserva")),
        );
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

class _EditarPerfilDialog extends StatefulWidget {
  final int docenteId;
  final String nombreActual;

  const _EditarPerfilDialog({
    required this.docenteId,
    required this.nombreActual,
  });

  @override
  _EditarPerfilDialogState createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<_EditarPerfilDialog> {
  final _apiService = ApiService();
  final _nombreController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.nombreActual;
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumDialog(
      title: "Editar Perfil",
      subtitle: "Actualiza tu información personal",
      icon: Icons.person_rounded,
      color: const Color(0xFF1E3A8A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: "Nombre Completo",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Text("Seguridad", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPassController,
                    decoration: InputDecoration(
                      labelText: "Nueva Contraseña",
                      hintText: "Dejar en blanco para mantener",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPassController,
                    decoration: InputDecoration(
                      labelText: "Confirmar Nueva Contraseña",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: cargando ? null : _guardarCambios,
                  icon: cargando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(cargando ? "Guardando..." : "Guardar Cambios"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarCambios() async {
    if (_nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre no puede estar vacío")),
      );
      return;
    }

    if (_newPassController.text.isNotEmpty) {
      if (_newPassController.text != _confirmPassController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Las contraseñas no coinciden")),
        );
        return;
      }
    }

    setState(() => cargando = true);

    try {
      // Actualizar nombre
      final successNombre = await _apiService.actualizarDocente(widget.docenteId, {"nombres": _nombreController.text});

      bool successPass = true;
      if (_newPassController.text.isNotEmpty) {
        successPass = await _apiService.actualizarContrasenaDocente(widget.docenteId, _newPassController.text);
      }

      setState(() => cargando = false);

      if (successNombre && successPass) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado exitosamente")),
        );
        // Aquí podrías recargar los datos si es necesario
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar perfil")),
        );
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

class _PremiumDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _PremiumDialog({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculamos dimensiones responsivas y más grandes
    final size = MediaQuery.of(context).size;
    final width = size.width > 900 ? 900.0 : size.width * 0.95;
    final height = size.height > 800 ? 800.0 : size.height * 0.9;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Sombra más fuerte
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                         ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider suave
            Container(height: 1, color: Colors.grey.withOpacity(0.1)),

            // Body
            Expanded(
              child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: child
              ),
            ),
          ],
        ),
      ),
    );
  }
}