import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/croquis_viewer_dialog.dart';

class CroquisScreen extends StatefulWidget {
  final int sedeId;
  final String rol;
  
  const CroquisScreen({
    Key? key,
    required this.sedeId,
    required this.rol,
  }) : super(key: key);

  @override
  State<CroquisScreen> createState() => _CroquisScreenState();
}

class _CroquisScreenState extends State<CroquisScreen> {
  final ApiService _api = ApiService();
  List<dynamic> salas = [];
  List<dynamic> filteredSalas = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _cargarSalas();
  }

  Future<void> _cargarSalas() async {
    try {
      final sedesData = await _api.listarSedes();
      List<dynamic> todasSalas = [];
      
      for (var sede in sedesData) {
        try {
          final salasData = await _api.listarSalasPorSede(sede['id']);
          for (var sala in salasData) {
            sala['sede_nombre'] = sede['nombre'];
          }
          todasSalas.addAll(salasData);
        } catch (e) {
          print('Error cargando sede ${sede['id']}: $e');
        }
      }
      
      // Ordenar salas por nombre
      todasSalas.sort((a, b) => (a["nombre"] ?? "").toString().toLowerCase().compareTo((b["nombre"] ?? "").toString().toLowerCase()));

      setState(() {
        salas = todasSalas;
        filteredSalas = todasSalas;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterSalas(String query) {
    setState(() {
      searchQuery = query;
      filteredSalas = salas.where((sala) {
        final nombre = (sala['nombre'] ?? "").toString().toLowerCase();
        final sede = (sala['sede_nombre'] ?? "").toString().toLowerCase();
        return nombre.contains(query.toLowerCase()) || sede.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _subirCroquisSala(int salaId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'svg'],
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

  Future<void> _verCroquisSala(dynamic sala) async {
    final salaId = sala['id'];
    final croquisUrl = await _api.obtenerCroquisSala(salaId);
    
    if (croquisUrl != null && croquisUrl.isNotEmpty) {
      final imageUrl = croquisUrl.startsWith('http') ? croquisUrl : '${_api.baseUrl}$croquisUrl';
      
      showDialog(
        context: context,
        builder: (context) => CroquisViewerDialog(
          imageUrl: imageUrl, 
          title: "Croquis - ${sala['nombre']}",
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay croquis disponible para esta sala')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.rol.toLowerCase() == 'admin';
    
    return AdminCRUDLayout(
      title: isAdmin ? "Croquis de Salas" : "Croquis Disponibles",
      subtitle: "Gestión visual de los mapas de ubicación de las salas",
      idSede: widget.sedeId,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterSalas,
              decoration: InputDecoration(
                hintText: "Buscar por sala o sede...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredSalas.isEmpty)
            _buildEmptyState()
          else
            GridView.builder(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                childAspectRatio: 0.85,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: filteredSalas.length,
              itemBuilder: (context, index) {
                final sala = filteredSalas[index];
                return _buildSalaCard(sala);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? "No hay salas registradas" : "No se encontraron salas que coincidan",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaCard(dynamic sala) {
    final hasCroquis = sala['croquis_url'] != null;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _verCroquisSala(sala),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Image Area
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    child: hasCroquis
                      ? Image.network(
                          sala['croquis_url'].startsWith('http') 
                              ? sala['croquis_url'] 
                              : '${_api.baseUrl}${sala['croquis_url']}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  ),
                  // Badge for status
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasCroquis ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasCroquis ? "CON MAPA" : "SIN MAPA",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Info Area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sala['nombre'] ?? "Sala sin nombre",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sala['sede_nombre'] ?? "Sede no especificada",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              "${sala['capacidad'] ?? 0} cap.",
                              style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (widget.rol.toLowerCase() == 'admin')
                              IconButton(
                                icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 20),
                                onPressed: () => _subirCroquisSala(sala['id']),
                                tooltip: 'Subir nuevo croquis',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Colors.green, size: 20),
                              onPressed: () => _verCroquisSala(sala),
                              tooltip: 'Ver pantalla completa',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            "Sin croquis",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
