import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class CroquisScreen extends StatefulWidget {
  const CroquisScreen({Key? key}) : super(key: key);

  @override
  State<CroquisScreen> createState() => _CroquisScreenState();
}

class _CroquisScreenState extends State<CroquisScreen> {
  final ApiService _api = ApiService();
  List<dynamic> salas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSalas();
  }

  Future<void> _cargarSalas() async {
    try {
      // Cargar todas las salas de profesores de todas las sedes
      final sedesData = await _api.listarSedes();
      List<dynamic> todasSalas = [];
      
      for (var sede in sedesData) {
        try {
          final salasData = await _api.listarSalasPorSede(sede['id']);
          // Agregar información de la sede a cada sala
          for (var sala in salasData) {
            sala['sede_nombre'] = sede['nombre'];
          }
          todasSalas.addAll(salasData);
        } catch (e) {
          print('Error cargando sede ${sede['id']}: $e');
        }
      }
      
      setState(() {
        salas = todasSalas;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _subirCroquisSala(int salaId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'svg', 'pdf'],
    );

    if (result != null) {
      final file = result.files.single;
      final success = await _api.subirCroquisSalaWeb(
        salaId, 
        file.bytes!, 
        file.name
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Croquis subido exitosamente')),
        );
        _cargarSalas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir croquis')),
        );
      }
    }
  }

  Future<void> _verCroquisSala(int salaId) async {
    final croquisUrl = await _api.obtenerCroquisSala(salaId);
    
    if (croquisUrl != null && croquisUrl.isNotEmpty) {
      // Si la URL ya es completa (de Supabase), usarla directamente
      final imageUrl = croquisUrl.startsWith('http') ? croquisUrl : '${_api.baseUrl}$croquisUrl';
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Croquis de la Sala'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Error al cargar imagen'));
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay croquis disponible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Croquis de Salas de Profesores'),
      ),
      body: salas.isEmpty
          ? const Center(
              child: Text(
                'No hay salas disponibles',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: salas.length,
              itemBuilder: (context, index) {
                final sala = salas[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(sala['nombre'] ?? 'Sin nombre'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Capacidad: ${sala['capacidad']}'),
                        Text('Sede: ${sala['sede_nombre'] ?? 'Sin sede'}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.upload_file, color: Colors.blue),
                          onPressed: () => _subirCroquisSala(sala['id']),
                          tooltip: 'Subir croquis',
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.green),
                          onPressed: () => _verCroquisSala(sala['id']),
                          tooltip: 'Ver croquis',
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