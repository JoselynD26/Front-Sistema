import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../widgets/web_layout.dart';
import '../widgets/admin_card.dart';

// Screens
import 'carrera_screen.dart';
import 'aula_screen.dart';
import 'escritorio_screen.dart';
import 'docente_screen.dart';
import 'curso_screen.dart';
import 'materia_screen.dart';
import 'sala_screen.dart';
import 'horario_screen.dart'; 
import 'admin_reservas_screen.dart';
import 'croquis_screen.dart';
import 'pdf_horarios_screen.dart';
import 'croquis_plaza_screen.dart';
import 'disponibilidad_aulas_screen.dart';

class DetalleSedeScreen extends StatefulWidget {
  final int idSede;
  final String nombre;

  const DetalleSedeScreen({
    super.key,
    required this.idSede,
    required this.nombre,
  });

  @override
  _DetalleSedeScreenState createState() => _DetalleSedeScreenState();
}

class _DetalleSedeScreenState extends State<DetalleSedeScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  List<dynamic> modulos = [];
  bool cargando = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cargarModulos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarModulos() async {
    try {
      final data = await _apiService.listarModulosPorSede(widget.idSede);
      if (mounted) {
        setState(() {
          // Filtrar modulo Horarios/Horario de clases si el usuario lo pidió eliminar
          modulos = data.where((m) => m["titulo"] != "Horarios").toList();
          cargando = false;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
      }
      debugPrint("Error cargando módulos: $e");
    }
  }

  Widget _pantallaPorModulo(String titulo) {
    switch (titulo) {
      case "Carreras": return CarrerasScreen(idSede: widget.idSede);
      case "Aulas": return AulasScreen(idSede: widget.idSede);
      case "Escritorios": return EscritoriosScreen(idSede: widget.idSede);
      case "Docentes": return DocentesScreen(idSede: widget.idSede);
      case "Cursos": return CursosScreen(idSede: widget.idSede);
      case "Salas": return SalasScreen(idSede: widget.idSede);
      case "Materias": return MateriasScreen(idSede: widget.idSede);
      case "Horarios": return HorarioScreen(idSede: widget.idSede);
      case "Reservas": return AdminReservasScreen(idSede: widget.idSede);
      case "Croquis por Sala": return CroquisScreen(sedeId: widget.idSede, rol: 'admin');
      case "Croquis Institucionales": return CroquisPlazaScreen(sedeId: widget.idSede, rol: 'admin');
      case "PDFHorarios": return PdfHorariosScreen(sedeId: widget.idSede, rol: 'admin');
      case "Disponibilidad Aulas": return DisponibilidadAulasScreen(idSede: widget.idSede);
      default: return const Scaffold(body: Center(child: Text("Módulo no implementado")));
    }
  }

  IconData _iconoPorNombre(String? icono) {
    if (icono == null) return Icons.help_outline_rounded;
    switch (icono) {
      case "school": return Icons.school_rounded;
      case "meeting_room": return Icons.meeting_room_rounded;
      case "desktop_windows": return Icons.desktop_windows_rounded;
      case "person": return Icons.person_rounded;
      case "class": return Icons.class_rounded;
      case "book": return Icons.menu_book_rounded;
      case "business": return Icons.business_rounded;
      case "schedule": return Icons.schedule_rounded;
      case "pending_actions": return Icons.pending_actions_rounded;
      case "map": return Icons.map_rounded;
      case "location_city": return Icons.location_city_rounded;
      case "picture_as_pdf": return Icons.picture_as_pdf_rounded;
      default: 
        debugPrint("Icono desconocido: $icono");
        return Icons.grid_view_rounded;
    }
  }

  Color _getColorForModule(String titulo) {
    if (titulo.contains("Carreras")) return Colors.blue.shade700;
    if (titulo.contains("Aulas") || titulo.contains("Salas") || titulo.contains("Espacios")) return Colors.green.shade700;
    if (titulo.contains("Docentes") || titulo.contains("Personal")) return Colors.purple.shade700;
    if (titulo.contains("Cursos")) return Colors.orange.shade700;
    if (titulo.contains("Materias")) return Colors.indigo.shade700;
    if (titulo.contains("Horarios")) return Colors.teal.shade700;
    if (titulo.contains("Reservas")) return Colors.pink.shade700;
    if (titulo.contains("Croquis")) return Colors.amber.shade700;
    if (titulo.contains("PDF")) return Colors.red.shade700;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return WebLayout(
      title: "Panel de Gestión",
      idSede: widget.idSede,
      // backgroundColor: const Color(0xFFF1F5F9), // Removed to allow theme to control it
      child: cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 16),
                  Text("Cargando módulos...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 HERO HEADER
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 24 : 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF0F172A), Colors.blue.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.blue.shade900.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isMobile)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 32),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "GESTIÓN DE SEDE",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.nombre.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 32),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "GESTIÓN DE SEDE",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.nombre.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            
                            SizedBox(height: isMobile ? 16 : 24),
                            Text(
                              "Seleccione un módulo para comenzar a administrar recursos, horarios y personal.",
                              style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    }
                  ),

                  const SizedBox(height: 40),

                  // 🔹 SECTION TITLE
                  Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 24),
                    child: Text(
                      "Módulos Administrativos",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  // 🔹 GRID
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            ...List.generate(modulos.length, (index) {
                              final modulo = modulos[index];
                              return SizedBox(
                                width: 280,
                                height: 180,
                                child: AdminCard(
                                  title: modulo["titulo"],
                                  subtitle: "Gestionar ${modulo['titulo'].toString().toLowerCase()}",
                                  icon: _iconoPorNombre(modulo["icono"]),
                                  color: _getColorForModule(modulo["titulo"]),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => _pantallaPorModulo(modulo["titulo"])),
                                    );
                                  },
                                ),
                              );
                            }),
                            // Tarjeta Manual para Disponibilidad
                            SizedBox(
                              width: 280,
                              height: 180,
                              child: AdminCard(
                                title: "Disponibilidad Aulas",
                                subtitle: "Ver aulas libres y ocupadas",
                                icon: Icons.event_available_rounded,
                                color: Colors.teal.shade700,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => DisponibilidadAulasScreen(idSede: widget.idSede)),
                                  );
                                },
                              ),
                            ),
                          ],
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
