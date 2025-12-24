import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DocenteCroquisScreen extends StatefulWidget {
  final int docenteId;

  const DocenteCroquisScreen({
    super.key,
    required this.docenteId,
  });

  @override
  State<DocenteCroquisScreen> createState() => _DocenteCroquisScreenState();
}

class _DocenteCroquisScreenState extends State<DocenteCroquisScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? croquis;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCroquis();
  }

  Future<void> _cargarCroquis() async {
    final data = await _api.obtenerMiCroquis(widget.docenteId);

    setState(() {
      croquis = data;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Croquis'),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : croquis == null
              ? const Center(
                  child: Text(
                    'No tienes un croquis asignado',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📍 INFO
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.desk),
                          title: Text(
                            'Escritorio: ${croquis!['escritorio']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Sala: ${croquis!['sala']}',
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🗺️ CROQUIS
                      Expanded(
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.network(
                              croquis!['croquis_url'],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Error al cargar el croquis'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
