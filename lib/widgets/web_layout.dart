import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/mouse_tracker_fix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/sede_screen.dart';
import '../screens/carrera_screen.dart';
import '../screens/aula_screen.dart';
import '../screens/docente_screen.dart';
import '../screens/curso_screen.dart';
import '../screens/materia_screen.dart';
import '../screens/horario_screen.dart';
import '../screens/admin_reservas_screen.dart';
import '../screens/calendario_reservas_screen.dart';
import '../screens/croquis_screen.dart';
import '../screens/croquis_plaza_screen.dart';
import '../screens/pdf_horarios_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/profesor_dashboard.dart';
import '../screens/detalle_sede_screen.dart';

class WebLayout extends StatefulWidget {
  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final int? idSede;
  final bool scrollable;

  const WebLayout({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
    this.backgroundColor,
    this.idSede,
    this.scrollable = true,
  });

  @override
  _WebLayoutState createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> with SafeStateMixin {
  bool _isDarkMode = false;
  String? _nombreUsuario;
  String? _emailUsuario;
  String? _rolUsuario;
  int? _docenteId;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final nombres = await _storage.read(key: "nombres");
    final apellidos = await _storage.read(key: "apellidos");
    final email = await _storage.read(key: "email");
    final rol = await _storage.read(key: "rol");
    final dId = await _storage.read(key: "docente_id");
    
    debugPrint("WEBLAYOUT: Carga de datos usuario");
    debugPrint(" - nombres: $nombres");
    debugPrint(" - apellidos: $apellidos");
    debugPrint(" - email: $email");
    debugPrint(" - rol: $rol");
    debugPrint(" - docente_id: $dId");

    safeSetState(() {
      if (nombres != null && apellidos != null) {
        _nombreUsuario = "$nombres $apellidos";
      } else {
        _nombreUsuario = "Usuario";
      }
      _emailUsuario = email ?? "usuario@yavirac.edu.ec";
      _rolUsuario = rol?.trim().toLowerCase();
      if (dId != null) _docenteId = int.tryParse(dId);
    });
    
    debugPrint("WebLayout: Title='${widget.title}', Final Rol='$_rolUsuario'");
  }

  bool get _isDocente => _rolUsuario == 'docente' || _rolUsuario == 'profesor';
  bool get _isAdmin => _rolUsuario == 'admin';

  void _toggleTheme() {
    safeSetState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _navigateTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _logout() async {
    await _storage.deleteAll();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildWebLayout(BuildContext context) {
    return MouseTrackerFix(
      child: _buildWebLayoutContent(context),
    );
  }

  Widget _buildWebLayoutContent(BuildContext context) {
    // 🔹 Modern Palette
    final backgroundColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6); // Lighter gray for cleaner look
    final surfaceColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // 🔹 Sidebar Navigation (Desktop Style)
          Container(
            width: 280,
            color: surfaceColor,
            child: Column(
              children: [
                // Logo Area
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Theme.of(context).primaryColor, Colors.blue.shade300],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "YAVIRAC",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Menu Items
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _SidebarItem(
                        icon: Icons.person_rounded,
                        label: "Mi Perfil",
                        isActive: widget.title.contains("Perfil"),
                        textColor: textColor,
                        onTap: () => _navigateTo(const ProfileScreen()),
                      ),

                      if (_isAdmin) ...[
                        _SidebarItem(
                          icon: Icons.business_rounded,
                          label: "Sedes",
                          isActive: widget.title.contains("Sedes") || widget.title.contains("Sede") || widget.title.contains("Gestión"),
                          textColor: textColor,
                          onTap: () => _navigateTo(const SedeScreen()),
                        ),
                        
                        // Solo mostrar si hay una sede seleccionada
                        if (widget.idSede != null) ...[
                          _SidebarItem(
                            icon: Icons.school_rounded,
                            label: "Carreras",
                            isActive: widget.title.contains("Carreras"),
                            textColor: textColor,
                            onTap: () => _navigateTo(CarrerasScreen(idSede: widget.idSede!)),
                          ),
                          _SidebarItem(
                            icon: Icons.meeting_room_rounded,
                            label: "Aulas",
                            isActive: widget.title.contains("Aulas"),
                            textColor: textColor,
                            onTap: () => _navigateTo(AulasScreen(idSede: widget.idSede!)),
                          ),
                          _SidebarItem(
                            icon: Icons.people_rounded,
                            label: "Docentes",
                            isActive: widget.title.contains("Docentes"),
                            textColor: textColor,
                            onTap: () => _navigateTo(DocentesScreen(idSede: widget.idSede!)),
                          ),
                          _SidebarItem(
                            icon: Icons.class_rounded,
                            label: "Cursos",
                            isActive: widget.title.contains("Cursos"),
                            textColor: textColor,
                            onTap: () => _navigateTo(CursosScreen(idSede: widget.idSede!)),
                          ),
                          _SidebarItem(
                            icon: Icons.book_rounded,
                            label: "Materias",
                            isActive: widget.title.contains("Materias"),
                            textColor: textColor,
                            onTap: () => _navigateTo(MateriasScreen(idSede: widget.idSede!)),
                          ),
                          // _SidebarItem(
                          //   icon: Icons.schedule_rounded,
                          //   label: "Horarios",
                          //   isActive: widget.title.contains("Horarios") && !widget.title.contains("PDF"),
                          //   textColor: textColor,
                          //   onTap: () => _navigateTo(HorarioScreen(idSede: widget.idSede!)),
                          // ),
                          _SidebarItem(
                            icon: Icons.event_available_rounded,
                            label: "Reservas",
                            isActive: widget.title.contains("Reservas") && !widget.title.contains("Calendario"),
                            textColor: textColor,
                            onTap: () => _navigateTo(AdminReservasScreen(idSede: widget.idSede)),
                          ),
                          // _SidebarItem(
                          //   icon: Icons.calendar_month_rounded,
                          //   label: "Calendario",
                          //   isActive: widget.title.contains("Calendario"),
                          //   textColor: textColor,
                          //   onTap: () => _navigateTo(const CalendarioReservasScreen()),
                          // ),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text("Utilidades", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          _SidebarItem(
                            icon: Icons.map_rounded,
                            label: "Croquis Salas",
                            isActive: widget.title.contains("Croquis de Salas"),
                            textColor: textColor,
                            onTap: () => _navigateTo(CroquisScreen(sedeId: widget.idSede!, rol: 'admin')),
                          ),
                          _SidebarItem(
                            icon: Icons.location_city_rounded,
                            label: "Plazas",
                            isActive: widget.title.contains("Plazas"),
                            textColor: textColor,
                            onTap: () => _navigateTo(CroquisPlazaScreen(sedeId: widget.idSede!, rol: 'admin')),
                          ),
                          _SidebarItem(
                            icon: Icons.picture_as_pdf_rounded,
                            label: "PDF Horarios",
                            isActive: widget.title.contains("PDF"),
                            textColor: textColor,
                            onTap: () => _navigateTo(PdfHorariosScreen(sedeId: widget.idSede!, rol: 'admin')),
                          ),
                        ],
                      ],

                      if (_isDocente) ...[
                        _SidebarItem(
                          icon: Icons.dashboard_rounded,
                          label: "Panel Docente",
                          isActive: widget.title.contains("Panel Docente"),
                          textColor: textColor,
                          onTap: () => _navigateTo(ProfesorDashboard(
                            docenteId: _docenteId ?? 0,
                            nombreProfesor: _nombreUsuario ?? "Profesor",
                          )),
                        ),
                      ],

                    ],
                  ),
                ),
                
                // User Profile / Logout
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                      child: Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _navigateTo(const ProfileScreen()),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                (_nombreUsuario?.isNotEmpty ?? false) ? _nombreUsuario![0].toUpperCase() : "A",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _navigateTo(const ProfileScreen()),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nombreUsuario ?? "Cargando...",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _emailUsuario ?? "...",
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                          onPressed: _logout,
                          tooltip: "Cerrar sesión",
                        ) 
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 🔹 Main Content Area
          Expanded(
            child: Column(
              children: [
                // Minimal Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  color: backgroundColor, // Blend with background
                  child: Row(
                    children: [
                      if (widget.idSede != null && widget.title != "Panel de Gestión" && widget.title != "Selecciona una sede")
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: _isDocente ? "Volver al panel docente" : "Volver al panel de la sede",
                            onPressed: () {
                              if (_isDocente) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfesorDashboard(
                                      docenteId: _docenteId ?? 0,
                                      nombreProfesor: _nombreUsuario ?? "Profesor",
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleSedeScreen(
                                      idSede: widget.idSede!,
                                      nombre: "Sede",
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleTheme,
                        icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                      ),
                      const SizedBox(width: 16),
                      // Action Button (if any)
                      if (widget.floatingActionButton != null)
                        widget.floatingActionButton!
                    ],
                  ),
                ),
                
                // Content Scroll
                Expanded(
                  child: widget.scrollable 
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1600),
                          child: widget.child,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(32),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1600),
                            child: widget.child,
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return MouseTrackerFix(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: widget.child,
        floatingActionButton: widget.floatingActionButton,
        backgroundColor: widget.backgroundColor,
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color textColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Theme.of(context).primaryColor : textColor.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}