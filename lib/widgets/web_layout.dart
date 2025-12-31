import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/mouse_tracker_fix.dart';
import '../services/api_service.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Removed direct usage
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
import '../screens/escritorio_screen.dart';
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
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final nombres = await _apiService.readStorage("nombres");
    final apellidos = await _apiService.readStorage("apellidos");
    final email = await _apiService.readStorage("email");
    final rol = await _apiService.readStorage("rol");
    final dId = await _apiService.readStorage("docente_id");
    
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
    await _apiService.clearStorage();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show mobile layout
    // We use a breakpoint (e.g., 900px)
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 900;
        
        if (isMobile) {
          return _buildMobileLayout(context);
        } else {
          return _buildWebLayout(context);
        }
      },
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    // 🔹 Modern Palette
    final backgroundColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6);
    final surfaceColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return MouseTrackerFix(
       child: Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            // 🔹 Sidebar (Desktop)
            Container(
              width: 280,
              color: surfaceColor,
              child: _SidebarContent(
                isDarkMode: _isDarkMode,
                isAdmin: _isAdmin,
                isDocente: _isDocente,
                title: widget.title,
                idSede: widget.idSede,
                docenteId: _docenteId,
                nombreUsuario: _nombreUsuario,
                emailUsuario: _emailUsuario,
                onNavigate: _navigateTo,
                onLogout: _logout,
              ),
            ),
            
            // 🔹 Main Content
            Expanded(
              child: Column(
                children: [
                   _buildHeader(context, isMobile: false),
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
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
     final backgroundColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6);
     final surfaceColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return MouseTrackerFix(
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: _buildHeader(context, isMobile: true),
        ),
        drawer: Drawer(
          backgroundColor: surfaceColor,
          child: _SidebarContent(
            isDarkMode: _isDarkMode,
            isAdmin: _isAdmin,
            isDocente: _isDocente,
            title: widget.title,
            idSede: widget.idSede,
            docenteId: _docenteId,
            nombreUsuario: _nombreUsuario,
            emailUsuario: _emailUsuario,
            onNavigate: (page) {
              Navigator.pop(context); // Close drawer
              _navigateTo(page);
            },
            onLogout: _logout,
          ),
        ),
        body: widget.scrollable 
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: widget.child,
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: widget.child,
            ),
        floatingActionButton: widget.floatingActionButton,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isMobile}) {
     final backgroundColor = _isDarkMode ? const Color(0xFF0F172A) : (_isMobileHeader(isMobile) ? Colors.white : const Color(0xFFF3F4F6));
     final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
     
     return Container(
        height: 70, // Slightly improved height
        padding: const EdgeInsets.symmetric(horizontal: 16), // Adjusted padding
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: isMobile ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Row(
          children: [
            // On mobile, AppBar handles the drawer icon automatically if we mistakenly don't put it, 
            // but since we return a Container for Desktop header, we manage it here.
            // Actually for Mobile, we returned 'PreferredSize' wrapping this.
            // The AppBar widget automatically inserts the menu button. 
            // Let's rely on standard AppBar behavior for mobile menu button creation if possible, 
            // OR build a custom row.
            
            // To be safe and consistent:
            if (isMobile) ...[
               Builder(builder: (context) => IconButton(
                 icon: Icon(Icons.menu_rounded, color: textColor),
                 onPressed: () => Scaffold.of(context).openDrawer(),
               )),
               const SizedBox(width: 8),
            ],

            if (widget.idSede != null && widget.title != "Panel de Gestión" && widget.title != "Selecciona una sede")
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: textColor,
                  tooltip: _isDocente ? "Volver al panel docente" : "Volver al panel de la sede",
                  onPressed: () {
                    if (_isDocente) {
                       _navigateTo(ProfesorDashboard(
                          docenteId: _docenteId ?? 0,
                          nombreProfesor: _nombreUsuario ?? "Profesor",
                        ));
                    } else {
                        _navigateTo(DetalleSedeScreen(
                          idSede: widget.idSede!,
                          nombre: "Sede",
                        ));
                    }
                  },
                ),
              ),

             Expanded(
               child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.5,
                     overflow: TextOverflow.ellipsis,
                  ),
                ),
             ),

            IconButton(
              onPressed: _toggleTheme,
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, color: textColor),
            ),
            
            // On desktop, FAB is usually floating, but user might want actions in header? 
            // The original code had actions in header only if floatingActionButton wasn't enough or different layout.
            // Standard WebLayout behavior puts FAB in Scaffold.floatingActionButton for mobile.
            if (!isMobile && widget.floatingActionButton != null) ...[
               const SizedBox(width: 16),
               widget.floatingActionButton!
            ]
          ],
        ),
     );
  }

  bool _isMobileHeader(bool isMobile) => isMobile;
}

class _SidebarContent extends StatelessWidget {
  final bool isDarkMode;
  final bool isAdmin;
  final bool isDocente;
  final String title;
  final int? idSede;
  final int? docenteId;
  final String? nombreUsuario;
  final String? emailUsuario;
  final Function(Widget) onNavigate;
  final VoidCallback onLogout;

  const _SidebarContent({
    required this.isDarkMode,
    required this.isAdmin,
    required this.isDocente,
    required this.title,
    this.idSede,
    this.docenteId,
    this.nombreUsuario,
    this.emailUsuario,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return Column(
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
                isActive: title.contains("Perfil"),
                textColor: textColor,
                onTap: () => onNavigate(const ProfileScreen()),
              ),

              if (isAdmin) ...[
                _SidebarItem(
                  icon: Icons.business_rounded,
                  label: "Sedes",
                  isActive: title.contains("Sedes") || title.contains("Sede") || title.contains("Gestión"),
                  textColor: textColor,
                  onTap: () => onNavigate(const SedeScreen()),
                ),
                
                if (idSede != null) ...[
                  _SidebarItem(
                    icon: Icons.school_rounded,
                    label: "Carreras",
                    isActive: title.contains("Carreras"),
                    textColor: textColor,
                    onTap: () => onNavigate(CarrerasScreen(idSede: idSede!)),
                  ),
                  _SidebarItem(
                    icon: Icons.meeting_room_rounded,
                    label: "Aulas",
                    isActive: title.contains("Aulas"),
                    textColor: textColor,
                    onTap: () => onNavigate(AulasScreen(idSede: idSede!)),
                  ),
                  _SidebarItem(
                    icon: Icons.people_rounded,
                    label: "Docentes",
                    isActive: title.contains("Docentes"),
                    textColor: textColor,
                    onTap: () => onNavigate(DocentesScreen(idSede: idSede!)),
                  ),
                   _SidebarItem(
                    icon: Icons.class_rounded,
                    label: "Cursos",
                    isActive: title.contains("Cursos"),
                    textColor: textColor,
                    onTap: () => onNavigate(CursosScreen(idSede: idSede!)),
                  ),
                  _SidebarItem(
                    icon: Icons.book_rounded,
                    label: "Materias",
                    isActive: title.contains("Materias"),
                    textColor: textColor,
                    onTap: () => onNavigate(MateriasScreen(idSede: idSede!)),
                  ),
                  _SidebarItem(
                    icon: Icons.desktop_windows_rounded,
                    label: "Escritorios",
                    isActive: title.contains("Escritorios"),
                    textColor: textColor,
                    onTap: () => onNavigate(EscritoriosScreen(idSede: idSede!)),
                  ),
                  _SidebarItem(
                    icon: Icons.event_available_rounded,
                    label: "Reservas",
                    isActive: title.contains("Reservas") && !title.contains("Calendario"),
                    textColor: textColor,
                    onTap: () => onNavigate(AdminReservasScreen(idSede: idSede)),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text("Utilidades", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  _SidebarItem(
                    icon: Icons.map_rounded,
                    label: "Croquis Salas",
                    isActive: title.contains("Croquis de Salas"),
                    textColor: textColor,
                    onTap: () => onNavigate(CroquisScreen(sedeId: idSede!, rol: 'admin')),
                  ),
                  _SidebarItem(
                    icon: Icons.location_city_rounded,
                    label: "Plazas",
                    isActive: title.contains("Plazas"),
                    textColor: textColor,
                    onTap: () => onNavigate(CroquisPlazaScreen(sedeId: idSede!, rol: 'admin')),
                  ),
                  _SidebarItem(
                    icon: Icons.picture_as_pdf_rounded,
                    label: "PDF Horarios",
                    isActive: title.contains("PDF"),
                    textColor: textColor,
                    onTap: () => onNavigate(PdfHorariosScreen(sedeId: idSede!, rol: 'admin')),
                  ),
                ],
              ],

              if (isDocente) ...[
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: "Panel Docente",
                  isActive: title.contains("Panel Docente"),
                  textColor: textColor,
                  onTap: () => onNavigate(ProfesorDashboard(
                    docenteId: docenteId ?? 0,
                    nombreProfesor: nombreUsuario ?? "Profesor",
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
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
              child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onNavigate(const ProfileScreen()),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        (nombreUsuario?.isNotEmpty ?? false) ? nombreUsuario![0].toUpperCase() : "A",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onNavigate(const ProfileScreen()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreUsuario ?? "Cargando...",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          emailUsuario ?? "...",
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  onPressed: onLogout,
                  tooltip: "Cerrar sesión",
                ) 
              ],
            ),
          ),
        ),
      ],
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