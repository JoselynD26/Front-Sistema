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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Croquis'),
      ),
      body: DocenteCroquisContent(docenteId: widget.docenteId),
    );
  }
}

class DocenteCroquisContent extends StatefulWidget {
  final int docenteId;

  const DocenteCroquisContent({Key? key, required this.docenteId}) : super(key: key);

  @override
  _DocenteCroquisContentState createState() => _DocenteCroquisContentState();
}

class _DocenteCroquisContentState extends State<DocenteCroquisContent> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? croquis;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCroquis();
  }

  Future<void> _cargarCroquis() async {
    try {
      final data = await _api.obtenerMiCroquis(widget.docenteId);
      if (mounted) {
        setState(() {
          croquis = data;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());
    
    if (croquis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No tienes un croquis asignado',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 📍 INFO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.desk, color: Colors.green),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Escritorio: ${croquis!['escritorio']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Sala: ${croquis!['sala']}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🗺️ CROQUIS
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50], // Fondo suave
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 0.5,
                  child: Image.network(
                    croquis!['croquis_url'],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Error al cargar la imagen del croquis'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
