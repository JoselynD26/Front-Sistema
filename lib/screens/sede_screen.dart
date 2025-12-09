import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detalle_sede_screen.dart';
import 'form_sede_screen.dart'; // 👈 Asegúrate de crear esta pantalla

class SedeScreen extends StatefulWidget {
  const SedeScreen({super.key});

  @override
  _SedeScreenState createState() => _SedeScreenState();
}

class _SedeScreenState extends State<SedeScreen> {
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
      setState(() {
        sedes = data;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        cargando = false;
      });
      print("Error cargando sedes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona una sede")),
      
      // ⬇⬇⬇ AGREGADO: Botón de Crear Sede
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormSedeScreen()),
          );
          if (resultado == true) {
            _cargarSedes(); // Recargar sedes al volver
          }
        },
        child: const Icon(Icons.add),
      ),
      // ⬆⬆⬆ AGREGADO
      
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
              itemCount: sedes.length,
              itemBuilder: (context, index) {
                final sede = sedes[index];
                return GestureDetector(
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
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_city, size: 60),
                        const SizedBox(height: 12),
                        Text(
                          sede["nombre"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
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
