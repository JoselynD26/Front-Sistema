import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

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

  // ================================
  // 📥 CARGAR PLAZAS
  // ================================
  Future<void> _cargarPlazas() async {
    try {
      final data = await _api.listarPlazasPorSede(widget.sedeId);

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

  // ================================
  // 🟢 FORM CREAR / EDITAR PLAZA (ADMIN)
  // ================================
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

  // ================================
  // 🗑️ ELIMINAR PLAZA (ADMIN)
  // ================================
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

  // ================================
  // 📤 SUBIR CROQUIS (ADMIN)
  // ================================
  Future<void> _subirCroquisPlaza(int plazaId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'svg', 'pdf'],
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

  // ================================
  // 👁️ VER CROQUIS (ADMIN)
  // ================================
  Future<void> _verCroquisPlaza(int plazaId) async {
    final croquisUrl = await _api.obtenerCroquisPlaza(plazaId);

    if (croquisUrl == null || croquisUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay croquis disponible')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          children: [
            AppBar(
              title: const Text('Croquis de la Plaza'),
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
                croquisUrl,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // 👨‍🏫 VISTA DOCENTE (SOLO VER)
  // ================================
  Widget _buildVistaDocente() {
    if (plazasConCroquis.isEmpty) {
      return const Center(
        child: Text('No hay croquis disponibles'),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),

        Text(
          plazasConCroquis[_paginaActual]['nombre'],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: plazasConCroquis.length,
                onPageChanged: (index) {
                  setState(() => _paginaActual = index);
                },
                itemBuilder: (_, index) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 4,
                      child: Image.network(
                        plazasConCroquis[index]['croquis_url'],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _paginaActual > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
              ),

              Positioned(
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed:
                      _paginaActual < plazasConCroquis.length - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================
  // 🛠️ VISTA ADMIN (SIN CAMBIOS)
  // ================================
  Widget _buildVistaAdmin() {
    return plazas.isEmpty
        ? const Center(child: Text('No hay plazas registradas'))
        : ListView.builder(
            itemCount: plazas.length,
            itemBuilder: (_, index) {
              final plaza = plazas[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(plaza['nombre']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () =>
                            _mostrarFormularioPlaza(plaza: plaza),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _eliminarPlaza(plaza['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.upload_file,
                            color: Colors.blue),
                        onPressed: () =>
                            _subirCroquisPlaza(plaza['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility,
                            color: Colors.green),
                        onPressed: () =>
                            _verCroquisPlaza(plaza['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Croquis por Plaza'),
      ),
      floatingActionButton: widget.rol == 'admin'
          ? FloatingActionButton(
              onPressed: () => _mostrarFormularioPlaza(),
              child: const Icon(Icons.add),
            )
          : null,
      body: widget.rol == 'docente'
          ? _buildVistaDocente()
          : _buildVistaAdmin(),
    );
  }
}
