import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'carrera_screen.dart';
import 'aula_screen.dart';
import 'escritorio_screen.dart';
import 'docente_screen.dart';   // ✅ módulo docentes
import 'curso_screen.dart';     // ✅ módulo cursos
import 'materia_screen.dart';   // ✅ módulo materias
import 'sala_screen.dart';      // ✅ módulo salas
import 'horario_screen.dart';   // ✅ módulo horarios

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
      print("Error cargando módulos: $e");
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
      case "Horarios": // ✅ nuevo caso
        return HorariosScreen(idSede: widget.idSede);
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
        return Icons.person; // ✅ ícono para docentes
      case "class":
        return Icons.class_; // ✅ ícono para cursos
      case "book":
        return Icons.book;   // ✅ ícono para materias
      case "business":
        return Icons.business; // ✅ ícono para salas
      case "schedule":
        return Icons.schedule; // ✅ ícono para horarios
      default:
        return Icons.extension;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sede: ${widget.nombre}")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconoPorNombre(modulo["icono"]),
                          size: 60,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          modulo["titulo"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}