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
                const SizedBox(height: 8),
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
    const yaviracOrange = Color(0xFFFF6B35);
    const yaviracBlue = Color(0xFF1E3A8A);
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: sedes.map((sede) {
            return SizedBox(
              width: 280,
              height: 180,
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
                child: Card(
                  elevation: 6,
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
                          yaviracOrange.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
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
                          child: const Icon(
                            Icons.school,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          sede["nombre"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: yaviracBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: yaviracOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sede["ubicacion"] ?? "Campus Principal",
                            style: TextStyle(
                              fontSize: 12,
                              color: yaviracOrange,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
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
