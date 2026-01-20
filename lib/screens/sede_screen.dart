import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../widgets/web_layout.dart';
import '../utils/mouse_tracker_fix.dart';
import 'detalle_sede_screen.dart';
import 'form_sede_screen.dart';
import 'sedes_management_screen.dart';
import '../widgets/admin_card.dart';

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
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "fab_gestionar",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SedesManagementScreen()),
              );
              _cargarSedes(); // Reload in case changes were made
            },
            label: const Text("Gestionar"),
            icon: const Icon(Icons.settings),
            backgroundColor: Colors.blueGrey,
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
             heroTag: "fab_agregar",
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
        ],
      ),
      child: cargando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   CircularProgressIndicator(color: Theme.of(context).primaryColor),
                   const SizedBox(height: 16),
                   const Text(
                    "Cargando sedes...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Text(
                  "Selecciona tu sede",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
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
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 32,
          runSpacing: 32,
          children: sedes.map((sede) {
            return SizedBox(
              width: 300,
              height: 240,
              child: AdminCard(
                title: sede["nombre"],
                subtitle: sede["ubicacion"] ?? "Campus Principal",
                icon: Icons.business_rounded,
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
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
