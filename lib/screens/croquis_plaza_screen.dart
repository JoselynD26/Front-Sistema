import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/croquis_viewer_dialog.dart';

class CroquisPlazaScreen extends StatefulWidget {
  final int sedeId;
  final String rol;

  const CroquisPlazaScreen({
    super.key,
    required this.sedeId,
    required this.rol,
  });

  @override
  State<CroquisPlazaScreen> createState() => _CroquisPlazaScreenState();
}

class _CroquisPlazaScreenState extends State<CroquisPlazaScreen> {
  final ApiService _api = ApiService();

  List<dynamic> plazas = [];
  List<dynamic> plazasConCroquis = [];
  bool cargando = true;

  late PageController _pageController;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cargarPlazas();
  }

  Future<void> _cargarPlazas() async {
    try {
      final data = await _api.listarPlazasPorSede(widget.sedeId);

      // Custom sort order
      final order = {
        "planta baja": 0,
        "planta alta": 1,
        "bloque b1 pa": 2,
        "bloque b1 pb": 3,
        "plaza guabos": 4,
        "sala 2": 5,
      };

      data.sort((a, b) {
         final nameA = (a["nombre"] ?? "").toString().trim().toLowerCase();
         final nameB = (b["nombre"] ?? "").toString().trim().toLowerCase();
         // If name starts with the key, match it (relaxed matching) or exact match?
         // Exact match is safer.
         final indexA = order[nameA] ?? 999;
         final indexB = order[nameB] ?? 999;
         
         if (indexA != indexB) return indexA.compareTo(indexB);
         return nameA.compareTo(nameB);
      });

      setState(() {
        plazas = data;
        plazasConCroquis = data
            .where((p) =>
                p['croquis_url'] != null &&
                p['croquis_url'].toString().isNotEmpty)
            .toList();
        cargando = false;
      });
    } catch (e) {
      debugPrint("Error cargando plazas: $e");
      setState(() => cargando = false);
    }
  }

  void _mostrarFormularioPlaza({Map<String, dynamic>? plaza}) {
    final TextEditingController nombreCtrl =
        TextEditingController(text: plaza?['nombre'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(plaza == null ? 'Nueva Plaza' : 'Editar Plaza'),
        content: TextField(
          controller: nombreCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de la Plaza',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) return;

              bool ok;
              if (plaza == null) {
                ok = await _api.crearPlaza(
                  nombreCtrl.text.trim(),
                  widget.sedeId,
                );
              } else {
                ok = await _api.editarPlaza(
                  plaza['id'],
                  nombreCtrl.text.trim(),
                  widget.sedeId,
                );
              }

              if (ok) {
                Navigator.pop(context);
                _cargarPlazas();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarPlaza(int plazaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Plaza'),
        content: const Text('¿Seguro que deseas eliminar esta plaza?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _api.eliminarPlaza(plazaId);
      _cargarPlazas();
    }
  }

  Future<void> _subirCroquisPlaza(int plazaId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'svg'],
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;

    final success = await _api.subirCroquisPlazaWeb(
      plazaId,
      file.bytes!,
      file.name,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Croquis subido correctamente')),
      );
      _cargarPlazas();
    }
  }

  Future<void> _verCroquisPlaza(dynamic plaza) async {
    final croquisUrl = await _api.obtenerCroquisPlaza(plaza['id']);

    if (croquisUrl == null || croquisUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay croquis disponible')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CroquisViewerDialog(
        imageUrl: croquisUrl, 
        title: "Croquis - ${plaza['nombre']}",
      ),
    );
  }

  Widget _buildVistaDocente() {
    return CroquisPlazaContent(sedeId: widget.sedeId);
  }

  Widget _buildVistaAdmin() {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (plazas.isEmpty) return _buildEmptyState();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        childAspectRatio: 0.85,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: plazas.length,
      itemBuilder: (context, index) {
        final plaza = plazas[index];
        return _buildPlazaCard(plaza);
      },
    );
  }

  Widget _buildPlazaCard(dynamic plaza) {
    final hasCroquis = plaza['croquis_url'] != null;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _verCroquisPlaza(plaza),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    child: hasCroquis
                      ? Image.network(
                          plaza['croquis_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  ),
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plaza['nombre'] ?? "Plaza sin nombre",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                          onPressed: () => _mostrarFormularioPlaza(plaza: plaza),
                          tooltip: "Editar",
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _eliminarPlaza(plaza['id']),
                          tooltip: "Eliminar",
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 20),
                          onPressed: () => _subirCroquisPlaza(plaza['id']),
                          tooltip: "Subir Croquis",
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: Colors.green, size: 20),
                          onPressed: () => _verCroquisPlaza(plaza),
                          tooltip: "Ver",
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No hay plazas registradas",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            "Sin croquis",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDocente = widget.rol.toLowerCase() == 'docente' || widget.rol.toLowerCase() == 'profesor';

    if (isDocente) {
      return AdminCRUDLayout(
        title: "Croquis de Plazas",
        subtitle: "Visualización de mapas de patios y plazas",
        idSede: widget.sedeId,
        child: CroquisPlazaContent(sedeId: widget.sedeId),
      );
    }

    return AdminCRUDLayout(
      title: "Gestión de Plazas",
      subtitle: "Administrar plazas y sus croquis",
      idSede: widget.sedeId,
      onAdd: () => _mostrarFormularioPlaza(),
      addLabel: "Nueva Plaza",
      child: _buildVistaAdmin(),
    );
  }
}

class CroquisPlazaContent extends StatefulWidget {
  final int sedeId;

  const CroquisPlazaContent({Key? key, required this.sedeId}) : super(key: key);

  @override
  _CroquisPlazaContentState createState() => _CroquisPlazaContentState();
}

class _CroquisPlazaContentState extends State<CroquisPlazaContent> {
  final ApiService _api = ApiService();
  List<dynamic> plazasConCroquis = [];
  bool cargando = true;
  late PageController _pageController;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cargarPlazas();
  }

  Future<void> _cargarPlazas() async {
    try {
      final data = await _api.listarPlazasPorSede(widget.sedeId);
      
      // Custom sort order
      final order = {
        "planta baja": 0,
        "planta alta": 1,
        "bloque b1 pa": 2,
        "bloque b1 pb": 3,
        "plaza guabos": 4,
        "sala 2": 5,
      };

      data.sort((a, b) {
         final nameA = (a["nombre"] ?? "").toString().trim().toLowerCase();
         final nameB = (b["nombre"] ?? "").toString().trim().toLowerCase();
         final indexA = order[nameA] ?? 999;
         final indexB = order[nameB] ?? 999;
         
         if (indexA != indexB) return indexA.compareTo(indexB);
         return nameA.compareTo(nameB);
      });
      if (mounted) {
        setState(() {
          plazasConCroquis = data
              .where((p) =>
                  p['croquis_url'] != null &&
                  p['croquis_url'].toString().isNotEmpty)
              .toList();
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());
    
    if (plazasConCroquis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay croquis disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            plazasConCroquis[_paginaActual]['nombre'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: plazasConCroquis.length,
                    onPageChanged: (index) {
                      setState(() => _paginaActual = index);
                    },
                    itemBuilder: (_, index) {
                      return InteractiveViewer(
                         maxScale: 4.0,
                         minScale: 0.5,
                        child: Image.network(
                          plazasConCroquis[index]['croquis_url'],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (_, __, ___) => const Center(
                              child: Text('Error al cargar imagen'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (plazasConCroquis.length > 1) ...[
                Positioned(
                  left: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: _paginaActual > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      color: _paginaActual > 0 ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed:
                          _paginaActual < plazasConCroquis.length - 1
                              ? () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                      color: _paginaActual < plazasConCroquis.length - 1 ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(plazasConCroquis.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _paginaActual == index
                    ? const Color(0xFF6366F1)
                    : Colors.grey[300],
              ),
            );
          }),
        ),
      ],
    );
  }
}

