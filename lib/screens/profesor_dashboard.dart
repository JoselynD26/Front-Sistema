import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/web_layout.dart';
import 'pdf_horarios_screen.dart';
import 'croquis_screen.dart';
import 'docente_croquis_screen.dart';
import 'croquis_plaza_screen.dart';
import '../widgets/custom_dialog.dart';
import 'disponibilidad_aulas_screen.dart';
import '../utils/app_colors.dart';

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
  int? idSede; 
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
      // 1. Obtener el perfil del docente para detectar su SEDE de forma robusta
      final docenteProfile = await _apiService.obtenerDocente(widget.docenteId);
      int detectedSede = 1;
      
      if (docenteProfile != null) {
        print("DEBUG: Perfil completo del docente: $docenteProfile");
        detectedSede = docenteProfile['id_sede'] ?? 
                       docenteProfile['sede_id'] ?? 
                       (docenteProfile['sedes'] != null && (docenteProfile['sedes'] as List).isNotEmpty ? docenteProfile['sedes'][0]['id'] : 1);
        
        print("DEBUG: Sede detectada desde perfil para docente ${widget.docenteId}: $detectedSede");
        
        if (detectedSede == 1 && docenteProfile.containsKey('sede_id') == false && docenteProfile.containsKey('id_sede') == false) {
           print("WARNING: No se encontró campo de Sede en el perfil. Usando Sede 1 por defecto.");
        }
      } else {
        print("ERROR: No se pudo obtener el perfil del docente ${widget.docenteId}");
      }

      // 2. Cargar datos base y específicos de la sede
      final results = await Future.wait([
        _apiService.obtenerMisMaterias(widget.docenteId),
        _apiService.obtenerHorarioDocente(widget.docenteId),
        _apiService.obtenerMisReservas(widget.docenteId),
        _apiService.listarCursosPorSede(detectedSede),
        _apiService.listarAulasPorSede(detectedSede),
      ]);

      idSede = detectedSede;
      final rawHorarios = results[1] as List<dynamic>;

      if (mounted) {
        setState(() {
          materias = results[0] as List<dynamic>;
          
          horarios = rawHorarios.map((h) {
            final map = Map<String, dynamic>.from(h);
            if (!map.containsKey('materia_id') && map.containsKey('id_materia')) {
              map['materia_id'] = map['id_materia'];
            }
            if (!map.containsKey('aula_id') && map.containsKey('id_aula')) {
              map['aula_id'] = map['id_aula'];
            }
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
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    return WebLayout(
      title: "Panel Docente",
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Header

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 800;
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
                      final textColorPrimary = isDark ? Colors.white : AppColors.blueDark;
                      final textColorSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

                      return _EnterAnimation(
                        delay: 0,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardBg, 
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            // Gradient Accent Border on the Left
                            image: const DecorationImage(
                              image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"), // Subtle texture if available, else ignored
                              opacity: 0.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Side Gradient Accent (Left Bar)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 6,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF0070C9), // Primary Blue
                                        Color(0xFFFF6B35), // Orange
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              // Content
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0), // Spacing for the border
                                child: isMobile 
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF0070C9), Color(0xFF0F2B46)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.bluePrimary.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        ),
                                        child: CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.transparent, // Transparent to show gradient
                                          child: Text(
                                            widget.nombreProfesor.isNotEmpty ? widget.nombreProfesor[0].toUpperCase() : "P",
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white, 
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Bienvenido de nuevo,",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textColorSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.nombreProfesor,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: textColorPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF0070C9), Color(0xFF0F2B46)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.bluePrimary.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        ),
                                        child: CircleAvatar(
                                          radius: 48,
                                          backgroundColor: Colors.transparent,
                                          child: Text(
                                            widget.nombreProfesor.isNotEmpty ? widget.nombreProfesor[0].toUpperCase() : "P",
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Bienvenido de nuevo,",
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: textColorSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              widget.nombreProfesor,
                                              style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: textColorPrimary,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.orangeAccent.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFFF6B35), size: 14)
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  "Panel de Gestión Académica",
                                                  style: TextStyle(
                                                    color: Color(0xFF0070C9), // Primary Blue
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      // Right side decoration for desktop
                                      Image.asset(
                                        "assets/images/logo.png",
                                        height: 150,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ), 
 
                
                const SizedBox(height: 40),
                
                _EnterAnimation(
                  delay: 150,
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 28,
                        color: textColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Accesos Rápidos",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Grid de módulos
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: constraints.maxWidth > 1000 
                          ? 4 
                          : (constraints.maxWidth > 700 
                              ? 3 
                              : (constraints.maxWidth > 350 ? 2 : 1)),
                      crossAxisSpacing: 32,
                      mainAxisSpacing: 32,
                      childAspectRatio: 1.2,
                      children: [
                        _EnterAnimation(
                          delay: 300,
                          child: _buildModuleCard(
                            "Croquis Institucional",
                            Icons.map_rounded,
                            "Ubicación general",
                            const Color(0xFF1E3A8A),
                            () => _verCroquisPlazas(),
                          ),
                        ),
                        _EnterAnimation(
                          delay: 350,
                          child: _buildModuleCard(
                            "Mis Materias",
                            Icons.menu_book_rounded,
                            "${materias.length} asignadas",
                            const Color(0xFF1E3A8A),
                            () => _mostrarMaterias(),
                          ),
                        ),
                        _EnterAnimation(
                          delay: 400,
                          child: _buildModuleCard(
                            "Mi Horario",
                            Icons.calendar_month_rounded,
                            "${horarios.length} clases",
                            AppColors.bluePrimary,
                            () => _mostrarHorarios(),
                          ),
                        ),
                        _EnterAnimation(
                          delay: 450,
                          child: _buildModuleCard(
                            "Mis Reservas",
                            Icons.bookmark_rounded,
                            "${reservas.length} activas",
                            const Color(0xFF1E3A8A),
                            () => _mostrarReservas(),
                          ),
                        ),
                        _EnterAnimation(
                          delay: 500,
                          child: _buildModuleCard(
                            "Reservar Aula",
                            Icons.add_circle_outline_rounded,
                            "Nueva solicitud",
                            const Color(0xFF1E3A8A),
                            () => _crearReserva(),
                          ),
                        ),
                        _EnterAnimation(
                          delay: 550,
                          child: _buildModuleCard(
                            "Horarios PDF",
                            Icons.picture_as_pdf_rounded,
                            "Descargar",
                            const Color(0xFF1E3A8A),
                            () => _verHorarios(),
                          ),
                        ),
                        _EnterAnimation(
                          delay: 600,
                          child: _buildModuleCard(
                            "Sala de Profesores",
                            Icons.desk,
                            "Mi escritorio",
                            const Color(0xFF1E3A8A),
                            () => _verCroquis(),
                          ),
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
    return _HoverableCard(
      title: title,
      icon: icon,
      subtitle: subtitle,
      color: color,
      onTap: onTap,
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
          color: const Color(0xFF1E3A8A), 
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
                              const Icon(Icons.school, size: 14, color: Colors.grey),
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
          color: const Color(0xFF1E3A8A),
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
                                  builder: (_) => CustomDialog(
                                    title: reserva["estado"] == "aprobada" ? "Liberar Aula" : "Cancelar Solicitud",
                                    description: message,
                                    type: DialogType.warning,
                                    onConfirm: () => Navigator.pop(context, true),
                                    onCancel: () => Navigator.pop(context, false),
                                    confirmText: "Sí, proceder",
                                    cancelText: "No",
                                    showCancel: true,
                                  ),
                                );

                              if (confirm == true) {
                                  bool success;
                                  if (reserva["estado"] == "aprobada") {
                                    success = await _apiService.eliminarReserva(reserva["id"]);
                                  } else {
                                    success = await _apiService.cancelarReservaAula(reserva["id"], widget.docenteId);
                                  }

                                  if (success) {
                                    Navigator.pop(context);
                                    _cargarDatos();
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => CustomDialog(
                                        title: "¡Éxito!",
                                        description: reserva["estado"] == "aprobada" 
                                            ? "Aula liberada exitosamente" 
                                            : "Solicitud cancelada exitosamente",
                                        type: DialogType.success,
                                        confirmText: "Aceptar",
                                        onConfirm: () => Navigator.pop(ctx),
                                      )
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
                                builder: (_) => CustomDialog(
                                  title: "Eliminar Reserva",
                                  description: "¿Estás seguro? Se eliminará del historial permanentemente.",
                                  type: DialogType.error,
                                  confirmText: "Eliminar",
                                  cancelText: "Cancelar",
                                  showCancel: true,
                                  onConfirm: () => Navigator.pop(context, true),
                                  onCancel: () => Navigator.pop(context, false),
                                ),
                              );
                              
                              if (confirm == true) {
                                final success = await _apiService.eliminarReserva(reserva["id"]);
                                if (success) {
                                  Navigator.pop(context); 
                                  _cargarDatos();
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => CustomDialog(
                                      title: "¡Éxito!",
                                      description: "Reserva eliminada del historial",
                                      type: DialogType.success,
                                      confirmText: "Aceptar",
                                      onConfirm: () => Navigator.pop(ctx),
                                    )
                                  );
                                } else {
                                  _showPremiumSnackBar(
                                    "Error al eliminar la reserva",
                                    icon: Icons.error_outline_rounded,
                                    color: Colors.red
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
        return _FormularioReservaAula(docenteId: widget.docenteId, idSede: idSede ?? 1);
      },
    ).then((result) {
      if (result == true) {
        _cargarDatos(); // Recargar datos si se creó una reserva
      }
    });
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
          color: const Color(0xFF1E3A8A),
          child: PdfHorariosContent(sedeId: idSede ?? 1), 
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
          color: const Color(0xFF1E3A8A),
          child: CroquisPlazaContent(sedeId: idSede ?? 1), 
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
          color: const Color(0xFF1E3A8A),
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
        return DisponibilidadAulasScreen(idSede: idSede ?? 1);
      },
    );
  }

  void _cancelarClase(int horarioId) async {
    // Mostrar confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => CustomDialog(
        title: "Cancelar Clase",
        description: "Esta acción notificará a los estudiantes y administrativos. No se puede deshacer.",
        type: DialogType.error,
        confirmText: "Sí, Cancelar",
        cancelText: "Mantener Clase",
        showCancel: true,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmar == true) {
      // Cancelar horario usando endpoint específico
      final success = await _apiService.cancelarHorario(horarioId);
      
      if (success) {
        _cargarDatos();
        showDialog(
          context: context,
          builder: (ctx) => CustomDialog(
            title: "¡Éxito!",
            description: "Clase cancelada exitosamente",
            type: DialogType.success,
            confirmText: "Aceptar",
            onConfirm: () => Navigator.pop(ctx),
          )
        );
      } else {
        _showPremiumSnackBar(
          "Error al cancelar la clase",
          icon: Icons.error_outline_rounded,
          color: Colors.red
        );
      }
    }
  }

  void _showPremiumSnackBar(String message, {Color color = const Color(0xFF1E3A8A), IconData icon = Icons.info_outline_rounded}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      )
    );
  }

  Future<void> _cerrarSesion() async {
    await _apiService.clearStorage();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _editarPerfil() {
    showDialog(
      context: context,
      builder: (_) => _EditarPerfilDialog(
        docenteId: widget.docenteId,
        nombreActual: widget.nombreProfesor,
      ),
    );
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
  int _selectedDayIndex = DateTime.now().weekday - 1;

  @override
  void initState() {
    super.initState();
    if (_selectedDayIndex > 4) _selectedDayIndex = 0; // Default to Monday if weekend
  }
  
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
    final bool isMobile = MediaQuery.of(context).size.width < 650;
    
    return _PremiumDialog(
      title: "Mi Horario Semanal",
      subtitle: _formatearFecha(fechaSeleccionada),
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF1E3A8A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _cambiarSemana(-1),
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF1E3A8A)),
                ),
                TextButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF1E3A8A)),
                  label: Text(
                    "Cambiar Semana",
                    style: TextStyle(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                IconButton(
                  onPressed: () => _cambiarSemana(1),
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: isMobile ? _buildCalendarioMobile() : _buildCalendarioSemanal(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarioMobile() {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(dias.length, (index) {
                final isSelected = _selectedDayIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected? [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Text(
                      dias[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildListaClasesDia(dias[_selectedDayIndex]),
        ),
      ],
    );
  }

  Widget _buildListaClasesDia(String dia) {
    final clasesDia = widget.horarios.where((h) {
        String normalize(String s) => s.toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u');

        final diaApi = normalize(h['dia']?.toString() ?? "");
        return diaApi == normalize(dia);
    }).toList();

    clasesDia.sort((a, b) => _parseHora(a['hora_inicio']).compareTo(_parseHora(b['hora_inicio'])));

    if (clasesDia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("No tienes clases este día", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: clasesDia.length,
      itemBuilder: (context, index) {
        final h = clasesDia[index];
        final materiaNombre = _getMateriaNombre(h['materia_id']);
        final colorGradient = _getColorForMateria(materiaNombre);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              // Barra lateral de color
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: colorGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            materiaNombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            h['hora_inicio'].toString().substring(0, 5),
                            style: const TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          "${h['hora_inicio']} - ${h['hora_fin']}",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "${_getCursoNombre(h['curso_id'])} | ${_getAulaNombre(h['aula_id'])}",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
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
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1000, // Fixed width to ensure calendar looks good
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
          ),

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
  final int idSede;
  const _FormularioReservaAula({required this.docenteId, required this.idSede});

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

  String _normalize(String s) {
    return s.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

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

  Widget _buildCompactPicker({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    
    return _PremiumDialog(
      title: "Reservar Aula",
      subtitle: "Solicita un espacio para tus actividades",
      icon: Icons.add_circle_outline_rounded,
      color: const Color(0xFF1E3A8A),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20, 
          vertical: isMobile ? 12 : 16
        ),
        child: Column(
          children: [
            // 1. Selector de Horario (Card superior)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  if (isMobile) ...[
                    _buildCompactPicker(
                      icon: Icons.calendar_today,
                      label: "FECHA",
                      value: _fechaController.text.isEmpty ? "Seleccionar" : _fechaController.text,
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (fecha != null) setState(() => _fechaController.text = fecha.toString().split(' ')[0]);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactPicker(
                            icon: Icons.access_time,
                            label: "INICIO",
                            value: _horaInicioController.text.isEmpty ? "14:00" : _horaInicioController.text,
                            onTap: () => _seleccionarHora(_horaInicioController),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactPicker(
                            icon: Icons.access_time_filled,
                            label: "FIN",
                            value: _horaFinController.text.isEmpty ? "16:00" : _horaFinController.text,
                            onTap: () => _seleccionarHora(_horaFinController),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactPicker(
                            icon: Icons.calendar_today,
                            label: "FECHA",
                            value: _fechaController.text.isEmpty ? "Seleccionar" : _fechaController.text,
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (fecha != null) setState(() => _fechaController.text = fecha.toString().split(' ')[0]);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactPicker(
                            icon: Icons.access_time,
                            label: "INICIO",
                            value: _horaInicioController.text.isEmpty ? "14:00" : _horaInicioController.text,
                            onTap: () => _seleccionarHora(_horaInicioController),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactPicker(
                            icon: Icons.access_time_filled,
                            label: "FIN",
                            value: _horaFinController.text.isEmpty ? "16:00" : _horaFinController.text,
                            onTap: () => _seleccionarHora(_horaFinController),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFE8F33)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orangeAccent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: buscandoAulas ? null : _buscarAulasDisponibles,
                      icon: buscandoAulas
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search_rounded),
                      label: Text(
                        buscandoAulas ? "BUSCANDO..." : "BUSCAR AULAS DISPONIBLES",
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Resultados o Mensajes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      aulasDisponibles.isEmpty ? "Disponibilidad" : "Aulas Encontradas (${aulasDisponibles.length})",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                  
                  Expanded(
                    child: Container(
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Footer (Motivo y Confirmación) - Solo si hay algo seleccionado o buscado
            if (buscandoAulas == false && aulasDisponibles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06), 
                      blurRadius: 15, 
                      offset: const Offset(0, -5)
                    )
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _motivoController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "Motivo de la reserva",
                        labelStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF1E3A8A), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: const Text("Liberar mi aula actual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: const Text("Si tienes clase programada, la cancelaremos.", style: TextStyle(fontSize: 11)),
                      value: _liberarAulaActual,
                      activeColor: AppColors.orangeAccent,
                      onChanged: (v) => setState(() => _liberarAulaActual = v ?? false),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (aulaSeleccionada != null && !cargando)
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: (aulaSeleccionada != null && !cargando) ? _crearReserva : null,
                        icon: cargando 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          cargando ? "PROCESANDO..." : "CONFIRMAR RESERVA",
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (buscandoAulas) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (aulasDisponibles.isEmpty) {
      final hasFilters = _fechaController.text.isNotEmpty;
      final bool isMobile = MediaQuery.of(context).size.width < 600;
      
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: hasFilters ? Colors.orange.shade50 : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.search_off_rounded : Icons.search_rounded,
                size: isMobile ? 40 : 48,
                color: hasFilters ? Colors.orange : const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? "Sin resultados" : "¿Cuándo la necesitas?",
              style: TextStyle(
                fontSize: isMobile ? 16 : 18, 
                fontWeight: FontWeight.bold, 
                color: const Color(0xFF1E293B)
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
              child: Text(
                hasFilters ? "No hay aulas libres en ese rango de tiempo." : "Selecciona fecha y hora arriba para ver opciones.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 12 : 13),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: aulasDisponibles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final aula = aulasDisponibles[index];
        final isSelected = aulaSeleccionada == aula["id"];
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.02) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: InkWell(
            onTap: () => setState(() => aulaSeleccionada = aula["id"]),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected ? [
                        BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                      ] : [],
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aula["nombre"],
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildMiniTag(Icons.people_outline_rounded, "${aula["capacidad"]}"),
                            const SizedBox(width: 8),
                            _buildMiniTag(Icons.category_outlined, "${aula["tipo"] ?? 'Aula'}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Radio<int>(
                      value: aula["id"],
                      groupValue: aulaSeleccionada,
                      activeColor: const Color(0xFF1E3A8A),
                      onChanged: (v) => setState(() => aulaSeleccionada = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  int _parseHora(String hora) {
    if (hora.trim().isEmpty) return 0;
    try {
      final parts = hora.trim().split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = (parts.length > 1) ? (int.tryParse(parts[1]) ?? 0) : 0;
      return (h * 60) + m; // Total minutes since midnight
    } catch (e) {
      debugPrint("Error parsing hora '$hora': $e");
      return 0;
    }
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
       _showPremiumSnackBar("Ingresa fecha, hora de inicio y hora de fin", color: Colors.orange);
      return;
    }

    setState(() => buscandoAulas = true);

    try {
      final fechaDate = DateTime.parse(_fechaController.text);
      final diaSemana = _getDayName(fechaDate.weekday);
      final inicioSolicitado = _parseHora(_horaInicioController.text);
      final finSolicitado = _parseHora(_horaFinController.text);

      print("DEBUG: Iniciando Busqueda Exhaustiva para $diaSemana ${_fechaController.text} ($inicioSolicitado - $finSolicitado)");

      // 1. Obtener datos basicos: Aulas, Eventos y Horario Diario (Reservas + Ocupación) y CANCELACIONES
      final List<Future<dynamic>> futures = [
        _apiService.listarAulasPorSede(widget.idSede),
        _apiService.listarHorariosPorSede(widget.idSede),
        _apiService.listarDocentesPorSede(widget.idSede),
        _apiService.obtenerHorarioAulas(widget.idSede, _fechaController.text),
        _apiService.listarHorariosCancelados(widget.idSede, _fechaController.text),
        _apiService.listarReservasPorSede(widget.idSede),
      ];
      final resultsBasicos = await Future.wait(futures);

      final todasLasAulas = resultsBasicos[0] as List<dynamic>;
      final eventosPorFecha = resultsBasicos[1] as List<dynamic>;
      final docentes = resultsBasicos[2] as List<dynamic>;
      final horarioDiario = resultsBasicos[3] as List<dynamic>;
      final cancelacionesFecha = resultsBasicos[4] as List<dynamic>;
      final todasLasReservas = resultsBasicos[5] as List<dynamic>;

      if (todasLasAulas.isEmpty) {
        print("DEBUG: No hay aulas en la sede ${widget.idSede}");
        _showPremiumSnackBar("Aviso: No hay aulas registradas para tu sede.", color: Colors.orange, icon: Icons.warning_amber_rounded);
        setState(() => buscandoAulas = false);
        return;
      }

      // 2. Obtener Horarios Recurrentes de TODOS los docentes (Optimizado)
      print("DEBUG: Fetcheando horarios recurrentes (Bulk)...");
      final horarioRecurrenteTotal = await _apiService.listarHorariosDocentesPorSede(widget.idSede);
      
      print("DEBUG: Total Recurrentes Globales: ${horarioRecurrenteTotal.length}");
      print("DEBUG: Total Cancelaciones Fecha: ${cancelacionesFecha.length}");

      // 4. Filtrar aulas disponibles
      final disponibles = todasLasAulas.where((aula) {
        bool ocupada = false;

        // --- A. Revisar Horario Recurrente (Clases Semanales) ---
        final clasesRecurrentesAula = horarioRecurrenteTotal.where((h) {
          final hAulaId = h['aula_id'] ?? h['id_aula'];
          final hDia = h['dia']?.toString() ?? "";
          return hAulaId.toString() == aula['id'].toString() && 
                 _normalize(hDia) == _normalize(diaSemana);
        });

        for (var clase in clasesRecurrentesAula) {
          // CHECK: Si la clase está cancelada para esta fecha, la ignoramos (liberamos el aula)
          final esCancelada = cancelacionesFecha.any((c) => 
            c['horario_id'].toString() == clase['id'].toString() || 
            (c['id_horario'] != null && c['id_horario'].toString() == clase['id'].toString())
          );

          if (esCancelada) {
             print("   --- Clase Recurrente ${clase['id']} en ${aula['nombre']} está CANCELADA hoy. Ignorando conflicto.");
             continue; // Saltamos esta clase, no ocupa el aula
          }

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
          // Verificar si el evento NO es 'cancelado' (por si acaso el backend devuelve status)
          if (evento['estado'] == 'cancelado') continue; 

          final start = _parseHora(evento['hora_inicio']);
          final end = _parseHora(evento['hora_fin']);

          if (inicioSolicitado < end && finSolicitado > start) {
             print("   >>> CONFLICTO FECHA en ${aula['nombre']}: ${evento['hora_inicio']} - ${evento['hora_fin']} (Evento)");
             ocupada = true;
             break;
          }
        }
        if (ocupada) return false;

        // --- B2. Revisar Reservas Aprobadas (Bloqueo entre pares) ---
        final reservasAula = todasLasReservas.where((r) {
           final rAulaId = r['aula_id'] ?? r['id_aula'];
           final rFecha = r['fecha'];
           final rEstado = (r['estado'] ?? '').toString().toLowerCase();
           
           return rAulaId.toString() == aula['id'].toString() && 
                  rFecha == _fechaController.text &&
                  rEstado == 'aprobada';
        });

        for (var res in reservasAula) {
           // Si soy yo mismo el de la reserva, NO debería contar como ocupado (para permitirme editar o ver),
           // PERO si estoy creando una NUEVA, técnicamente ya tengo ocupada esa hora.
           // La regla de negocio dice: "no volverle a aparecer a otro profe". 
           // Si es mi propia reserva, ya está aprobada, así que el aula ESTÁ ocupada por mí.
           
           final start = _parseHora(res['hora_inicio']);
           final end = _parseHora(res['hora_fin']);

           if (inicioSolicitado < end && finSolicitado > start) {
             print("   >>> CONFLICTO RESERVA APROBADA en ${aula['nombre']}: ${res['hora_inicio']} - ${res['hora_fin']}");
             ocupada = true;
             break;
           }
        }
        if (ocupada) return false;

        // --- C. Revisar Ocupación Diaria de Aulas (Consolidado: Reservas + Otros) ---
        final infoAula = horarioDiario.firstWhere(
          (item) => item['id'].toString() == aula['id'].toString(),
          orElse: () => null
        );

        if (infoAula != null && infoAula['ocupaciones'] != null) {
          final ocupaciones = infoAula['ocupaciones'] as List<dynamic>;
          for (var ocup in ocupaciones) {
             // Si la ocupación coincide con una recurrente cancelada, la ignoramos
             // (Esto puede ser tricky si 'ocupaciones' ya viene filtrado o no del backend. 
             // Asumimos que el backend puede mandar todo. Intentamos filtrar si tenemos ID)
             
             // Si viene de 'ocupaciones', suele ser una vista final. 
             // Pero si el backend no filtro la cancelada, aqui podria reaparecer.
             // Sin embargo, 'horarioDiario' suele ser la vista 'real'. 
             // Vamos a confiar en que Block A era el problema principal, 
             // pero agregaremos logica defensiva si ocup tiene referencia al horario original.
             
             if (ocup['estado'] == 'cancelado') continue;

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

      // Sort alphabetically
      disponibles.sort((a, b) => (a['nombre'] ?? "").toString().compareTo(b['nombre'] ?? ""));

      print("DEBUG: Aulas Disponibles Final: ${disponibles.length}");

      setState(() {
        aulasDisponibles = disponibles;
        aulaSeleccionada = null;
        buscandoAulas = false;
      });

      if (disponibles.isEmpty) {
        _showPremiumSnackBar("No hay aulas disponibles en ese horario", color: Colors.orange);
      }
    } catch (e) {
      setState(() => buscandoAulas = false);
      print("ERROR DETECTADO: $e");
      _showPremiumSnackBar("Error al buscar disponibilidad: $e", color: Colors.red, icon: Icons.error_outline_rounded);
    }
  }

  void _showPremiumSnackBar(String message, {Color color = const Color(0xFF1E3A8A), IconData icon = Icons.info_outline_rounded}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      )
    );
  }

  bool _liberarAulaActual = false;

  Future<void> _crearReserva() async {
    setState(() => cargando = true);

    try {
      final inicioNuevo = _parseHora(_horaInicioController.text);
      final finNuevo = _parseHora(_horaFinController.text);
      final fechaStr = _fechaController.text.trim();
      
      print("DEBUG [RESERVA]: Solicitando $fechaStr de $inicioNuevo min a $finNuevo min");
      
      // 0. VALIDACIÓN DE CONFLICTOS
      // A. Verificar clases regulares (Horarios Fijos)
      final horariosDocente = await _apiService.obtenerHorarioDocente(widget.docenteId);
      Map<String, dynamic> claseConflictiva = {};

      if (horariosDocente != null && horariosDocente is List) {
        final date = DateTime.parse(fechaStr);
        final diaSemana = _getDayName(date.weekday);

        claseConflictiva = horariosDocente.cast<Map<String, dynamic>>().firstWhere((h) {
          final hDia = h['dia']?.toString() ?? "";
          if (_normalize(hDia) != _normalize(diaSemana)) return false;
          
          final start = _parseHora(h['hora_inicio']);
          final end = _parseHora(h['hora_fin']);
          return (inicioNuevo < end && finNuevo > start);
        }, orElse: () => {});
      }
      
      
      
      // B. Verificar OTRAS RESERVAS (Duplicate Booking Check)
      final misReservas = await _apiService.obtenerMisReservas(widget.docenteId);
      print("DEBUG [RESERVA]: Mis Reservas Totales: ${misReservas.length}");
      
      // Helper Function for parsing times
      Map<String, String> extraerHoras(Map<String, dynamic> r) {
          String findKey(Map map, List<String> candidates) {
            for (var k in candidates) {
               if (map.containsKey(k) && map[k] != null) return map[k].toString().trim();
            }
            return "";
         }
         
         String start = findKey(r, ['hora_inicio', 'horaInicio', 'inicio', 'start_time', 'startTime']);
         String end = findKey(r, ['hora_fin', 'horaFin', 'fin', 'end_time', 'endTime']);
         
         if (start.isEmpty || end.isEmpty) {
             final horaCombined = findKey(r, ['hora', 'horario']);
             if (horaCombined.contains('-')) {
                final parts = horaCombined.split('-');
                if (parts.length == 2) {
                   start = parts[0].trim();
                   end = parts[1].trim();
                }
             }
         }
         return {"start": start, "end": end};
      }

      final reservasConflictivas = misReservas.cast<Map<String,dynamic>>().where((r) {
         final rFecha = (r['fecha']?.toString() ?? "").trim();
         final rEstado = (r['estado']?.toString() ?? "").trim().toUpperCase();
         final times = extraerHoras(r);
         final rInicioStr = times["start"]!;
         final rFinStr = times["end"]!;

         try {
           final rDate = DateTime.parse(rFecha);
           final targetDate = DateTime.parse(fechaStr);
           
           final isSameDay = (rDate.year == targetDate.year && 
                              rDate.month == targetDate.month && 
                              rDate.day == targetDate.day);
                              
           if (!isSameDay) return false;
         } catch(e) {
           if (!rFecha.startsWith(fechaStr.trim())) return false;
         }
         
         if (rEstado == 'RECHAZADA' || rEstado == 'CANCELADO' || rEstado == 'CANCELADA') return false;
         
         if (rInicioStr.isEmpty || rFinStr.isEmpty) return false;
         
         final rStart = _parseHora(rInicioStr);
         final rEnd = _parseHora(rFinStr);
         
         final hayConflicto = (inicioNuevo < rEnd && finNuevo > rStart);
         if (hayConflicto) {
            print("   >>> CONFLICTO DETECTADO con reserva ${r['id']} ($rInicioStr - $rFinStr)");
         }
         return hayConflicto;
      }).toList();
      
      if (reservasConflictivas.isNotEmpty) {
         setState(() => cargando = false);
         final rConflicto = reservasConflictivas.first;
         
         final times = extraerHoras(rConflicto); // Use correct extraction for display
         final horaStr = "${times['start']} - ${times['end']}";
         final estadoStr = rConflicto['estado']?.toString().toUpperCase() ?? "PENDIENTE";
         
         showDialog(
           context: context,
           builder: (ctx) => CustomDialog(
              title: "Conflicto de Reserva",
              description: "Ya tienes una solicitud $estadoStr para el $fechaStr a las $horaStr.\nNo es posible crear otra en el mismo horario.",
              type: DialogType.error,
              confirmText: "Entendido",
              onConfirm: () => Navigator.pop(ctx),
           )
         );
         return;
      }

      // 2. Conflicto con CLASE REGULARES (Regular Class Conflict)
      if (claseConflictiva.isNotEmpty && !_liberarAulaActual) {
        setState(() => cargando = false);
        
        final nombreMateria = claseConflictiva['materia_nombre'] ?? 'otra clase';
        final aulaActual = claseConflictiva['aula_nombre'] ?? 'su aula actual';
        
        // Mostrar Dialogo de Advertencia con Opción de Liberar
        showDialog(
          context: context,
          builder: (ctx) => CustomDialog(
            title: "Conflicto de Horario",
            description: "Tienes clase de $nombreMateria en $aulaActual a esta hora.\n¿Deseas liberar tu aula actual para ocupar esta nueva sala?",
            type: DialogType.warning,
            confirmText: "Sí, Liberar y Reservar",
            showCancel: true,
            cancelText: "Cancelar",
            onConfirm: () {
              Navigator.pop(ctx);
              setState(() => _liberarAulaActual = true);
              _crearReserva(); // Reintentar inmediatamente
            },
          ),
        );
        return;
      }

      String motivoFinal = _motivoController.text;
      if (_liberarAulaActual && claseConflictiva.isNotEmpty) {
         motivoFinal = "$motivoFinal [SOLICITUD LIBERACION]";
      }

      final success = await _apiService.crearReservaAulaConRango(
        _fechaController.text,
        _horaInicioController.text,
        _horaFinController.text,
        aulaSeleccionada!,
        widget.docenteId,
        motivoFinal,
      );

      setState(() => cargando = false);

      if (success) {
        Navigator.pop(context, true);
        showDialog(
          context: context,
          builder: (ctx) => CustomDialog(
            title: "¡Éxito!",
            description: _liberarAulaActual && claseConflictiva.isNotEmpty
                ? "Solicitud enviada (Con liberación de aula)"
                : "Reserva creada exitosamente",
            type: DialogType.success,
            confirmText: "Aceptar",
            onConfirm: () => Navigator.pop(ctx),
          )
        );
      } else {
      }
    } catch (e) {
      setState(() => cargando = false);
      _showPremiumSnackBar("Error: $e", color: Colors.red);
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
  
  // Controladores (Solo Password es editable)
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  // Datos del docente (Solo lectura)
  String _nombres = "Cargando...";
  String _apellidos = "";
  String _correo = "";
  
  bool cargando = true;
  bool guardando = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosDocente();
  }

  Future<void> _cargarDatosDocente() async {
    try {
      final data = await _apiService.obtenerDocente(widget.docenteId);
      if (data != null) {
        setState(() {
          _nombres = data["nombres"] ?? "";
          _apellidos = data["apellidos"] ?? "";
          _correo = data["correo"] ?? "";
          cargando = false;
        });
      } else {
        setState(() {
          _nombres = "Error al cargar";
          cargando = false;
        });
      }
    } catch (e) {
      print("Error cargando perfil: $e");
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumDialog(
      title: "Mi Perfil",
      subtitle: widget.nombreActual,
      icon: Icons.person_rounded,
      color: const Color(0xFF1E3A8A),
      heightFactor: 0.85,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: cargando 
                ? const Center(child: CircularProgressIndicator()) 
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: Información Personal (Solo Lectura)
                    _buildSectionTitle("Información Personal", Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildReadOnlyField("Nombres", _nombres, Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildReadOnlyField("Apellidos", _apellidos, Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildReadOnlyField("Correo Electrónico", _correo, Icons.email_outlined),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    // Sección: Seguridad (Actualizable)
                    _buildSectionTitle("Seguridad", Icons.lock_outline, color: Colors.orange),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _newPassController, 
                      label: "Nueva Contraseña",
                      obscureText: _obscureNewPass,
                      onToggleVisibility: () => setState(() => _obscureNewPass = !_obscureNewPass),
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _confirmPassController, 
                      label: "Confirmar Nueva Contraseña",
                      obscureText: _obscureConfirmPass,
                      onToggleVisibility: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Déjalo en blanco si no deseas cambiar tu contraseña.",
                            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ),
          ),
          
          // Footer Botones
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: guardando ? null : _guardarCambios,
                  icon: guardando 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                  label: Text(guardando ? "GUARDANDO..." : "GUARDAR CAMBIOS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color color = const Color(0xFF1E3A8A)}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Fondo grisáceo para indicar "disabled"
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, color: Colors.grey, size: 16), // Candadito visual
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller, 
    required String label, 
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.orange),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _guardarCambios() async {
    // Solo validamos contraseña si se escribió algo
    if (_newPassController.text.isNotEmpty) {
      if (_newPassController.text != _confirmPassController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Las contraseñas no coinciden")),
        );
        return;
      }

      setState(() => guardando = true);

      try {
        final success = await _apiService.actualizarContrasenaDocente(widget.docenteId, _newPassController.text);
        
        setState(() => guardando = false);

        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Contraseña actualizada exitosamente"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error al actualizar contraseña"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } else {
      // Si no hay contraseña, solo cerramos el diálogo (pues el resto es read-only)
      Navigator.pop(context);
    }
  }
}

class _PremiumDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final double? heightFactor;

  const _PremiumDialog({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.heightFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;
    
    // More refined width and height
    final double width = size.width > 900 ? 900.0 : size.width * (isMobile ? 0.94 : 0.95);
    final double height = size.height > 800 ? 800.0 : size.height * (heightFactor ?? (isMobile ? 0.85 : 0.9));

    final gradientColors = [
      color.withOpacity(0.95),
      color.withOpacity(0.85),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24, 
        vertical: isMobile ? 24 : 40
      ),
      elevation: 0, // We use our own shadow
      child: Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 28 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pull bar on mobile
              if (isMobile)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
              // Premium Gradient Header
              Container(
                padding: EdgeInsets.fromLTRB(24, isMobile ? 12 : 20, 16, 20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: Icon(icon, color: Colors.white, size: isMobile ? 24 : 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 1), blurRadius: 2)
                              ]
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 13,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.2,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              
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
      ),
    );
  }
}



class _EnterAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  const _EnterAnimation({required this.child, this.delay = 0});

  @override
  State<_EnterAnimation> createState() => _EnterAnimationState();
}

class _EnterAnimationState extends State<_EnterAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class _HoverableCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HoverableCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DeepL / Bonito Theme Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0070C9);
    final darkBlue = const Color(0xFF0F2B46);
    final orangeAccent = const Color(0xFFFF6B35);
    final orangeLight = const Color(0xFFFF9F43);
    
    // Dynamic Colors based on Theme
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : darkBlue;
    final subtextColor = isDark ? Colors.white70 : darkBlue.withOpacity(0.6);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg, // Dynamic Background
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isHovered ? orangeAccent.withOpacity(0.5) : Colors.transparent, // Orange Border on Hover
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered 
                          ? orangeAccent.withOpacity(0.25) // Orange Glow
                          : Colors.black.withOpacity(isDark ? 0.3 : 0.05), // Subtle Shadow
                      blurRadius: _isHovered ? 20 : 10,
                      offset: Offset(0, _isHovered ? 10 : 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isHovered 
                              ? [orangeAccent, orangeLight] // Orange on Hover
                              : [darkBlue, primaryColor],   // Blue normally
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isHovered ? orangeAccent : primaryColor).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: _iconScaleAnimation.value,
                        child: Icon(widget.icon, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Dynamic Text Color
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    if (widget.subtitle.isNotEmpty)
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor, // Dynamic Subtext Color
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}