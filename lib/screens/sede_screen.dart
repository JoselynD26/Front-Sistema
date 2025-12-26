import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../widgets/web_layout.dart';
import '../utils/mouse_tracker_fix.dart';
import 'detalle_sede_screen.dart';
import 'form_sede_screen.dart';

class SedeScreen extends StatefulWidget {
  const SedeScreen({super.key});

  @override
  _SedeScreenState createState() => _SedeScreenState();
}

class _SedeScreenState extends State<SedeScreen> with SafeStateMixin {
  final _apiService = ApiService();
  List<dynamic> sedes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSedes();
  }

  Future<void> _cargarSedes() async {
    try {
      final data = await _apiService.listarSedes();
      safeSetState(() {
        sedes = data;
        cargando = false;
      });
    } catch (e) {
      safeSetState(() {
        cargando = false;
      });
      print("Error cargando sedes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebLayout(
      title: "Selecciona una sede",
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormSedeScreen()),
          );
          if (resultado == true) {
            _cargarSedes();
          }
        },
        child: const Icon(Icons.add),
      ),
      child: cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  SizedBox(height: 16),
                  Text(
                    "Cargando sedes...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const Text(
                  "Selecciona tu sede",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Elige la sede donde realizarás la gestión académica",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSedesGrid(),
              ],
            ),
    );
  }

  Widget _buildSedesGrid() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 32,
          runSpacing: 39,
          children: sedes.map((sede) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalleSedeScreen(
                        idSede: sede["id"],
                        nombre: sede["nombre"],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 350,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        sede["nombre"],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sede["ubicacion"] ?? "Campus Principal",
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
