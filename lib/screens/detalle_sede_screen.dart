import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../widgets/web_layout.dart';

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

class _DetalleSedeScreenState extends State<DetalleSedeScreen> {
  final _apiService = ApiService();
  List<dynamic> modulos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarModulos();
  }

  Future<void> _cargarModulos() async {
    try {
      final data = await _apiService.listarModulosPorSede(widget.idSede);
      setState(() {
        modulos = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      debugPrint("Error cargando módulos: $e");
    }
  }

  /// Devuelve la pantalla correspondiente según el módulo
  Widget _pantallaPorModulo(String titulo) {
    switch (titulo) {
      case "Carreras":
        return CarrerasScreen(idSede: widget.idSede);
      case "Aulas":
        return AulasScreen(idSede: widget.idSede);
      case "Escritorios":
        return EscritoriosScreen(idSede: widget.idSede);
      case "Docentes":
        return DocentesScreen(idSede: widget.idSede);
      case "Cursos":
        return CursosScreen(idSede: widget.idSede);
      case "Salas":
        return SalasScreen(idSede: widget.idSede);
      case "Materias":
        return MateriasScreen(idSede: widget.idSede);

     
      case "Horarios":
        return HorarioScreen(idSede: widget.idSede);

      case "Reservas":
        return const AdminReservasScreen();
      case "Croquis por Sala":
        return CroquisScreen(sedeId: widget.idSede, rol: 'admin');
      case "Croquis Institucionales":
        return CroquisPlazaScreen(
          sedeId: widget.idSede,
          rol: 'admin',
      );

      case "PDFHorarios":
        return PdfHorariosScreen(sedeId: widget.idSede, rol: 'admin');
      default:
        return const Scaffold(
          body: Center(child: Text("Módulo no implementado")),
        );
    }
  }

  /// Devuelve el ícono según el nombre
  IconData _iconoPorNombre(String icono) {
    switch (icono) {
      case "school":
        return Icons.school;
      case "meeting_room":
        return Icons.meeting_room;
      case "desktop_windows":
        return Icons.desktop_windows;
      case "person":
        return Icons.person;
      case "class":
        return Icons.class_;
      case "book":
        return Icons.book;
      case "business":
        return Icons.business;
      case "schedule":
        return Icons.schedule; // sigue igual
      case "pending_actions":
        return Icons.pending_actions;
      case "map":
        return Icons.map;
      case "picture_as_pdf":
        return Icons.picture_as_pdf;
      default:
        return Icons.extension;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebLayout(
      title: "${widget.nombre} - Módulos",
      child: cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  SizedBox(height: 16),
                  Text(
                    "Cargando módulos...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Text(
                  "Gestión Académica - ${widget.nombre}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Selecciona el módulo que deseas gestionar",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                _buildModulosGrid(),
              ],
            ),
    );
  }

  Widget _buildModulosGrid() {
    const yaviracOrange = Color(0xFFFF6B35);
    const yaviracBlue = Color(0xFF1E3A8A);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kIsWeb ? 4 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.1,
          ),
          itemCount: modulos.length,
          itemBuilder: (context, index) {
            final modulo = modulos[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _pantallaPorModulo(modulo["titulo"]),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        const Color.fromARGB(255, 197, 150, 132).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: yaviracBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: yaviracBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconoPorNombre(modulo["icono"]),
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        modulo["titulo"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: yaviracBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
