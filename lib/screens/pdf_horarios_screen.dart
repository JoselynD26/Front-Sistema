import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';

class PdfHorariosScreen extends StatefulWidget {
  final int sedeId;
  final String rol;

  const PdfHorariosScreen({
    Key? key,
    required this.sedeId,
    required this.rol,
  }) : super(key: key);

  @override
  _PdfHorariosScreenState createState() => _PdfHorariosScreenState();
}

class _PdfHorariosScreenState extends State<PdfHorariosScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _horarios = [];
  bool _isLoading = true;

  final List<Map<String, String>> _tiposHorarios = [
    {'tipo': 'aulas', 'titulo': 'Horario de Aulas', 'icono': 'meeting_room'},
    {'tipo': 'cursos', 'titulo': 'Horario de Cursos', 'icono': 'class'},
    {'tipo': 'docentes', 'titulo': 'Horario de Docentes', 'icono': 'person'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    try {
      final response = await _apiService.listarPdfHorarios(widget.sedeId);
      setState(() {
        _horarios = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar horarios: $e')),
      );
    }
  }

  Future<void> _subirPdf(String tipo) async {
    try {
      // Primero seleccionar archivo PDF
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final platformFile = result.files.first;
        
        // Después pedir nombre
        String? nombre = await _mostrarDialogoNombre();
        if (nombre == null || nombre.isEmpty) return;
        
        bool success = false;

        if (kIsWeb) {
          if (platformFile.bytes != null) {
             success = await _apiService.subirPdfHorarioCompleto(
                widget.sedeId, 
                tipo, 
                platformFile.bytes!, 
                nombre // Pasamos el nombre ingresado como nombre del archivo/param
             );
          }
        } else {
             // Mobile
             if (platformFile.path != null) {
                success = await _apiService.subirPdfHorarioCompletoPath(
                  widget.sedeId,
                  tipo,
                  platformFile.path!,
                  nombre
                );
             }
        }
        
        if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF "$nombre" subido exitosamente')),
            );
            _cargarHorarios();
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al subir PDF')),
            );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir PDF: $e')),
      );
    }
  }
  
  Future<String?> _mostrarDialogoNombre() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nombre del horario'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ej: Semestre 2024-1, Enero 2024, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Subir'),
          ),
        ],
      ),
    );
  }

  Future<void> _verPdf(String archivo) async {
    try {
      final url = Uri.parse("${_apiService.baseUrl}/pdf-horarios/ver/${widget.sedeId}/$archivo");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir PDF: $e')),
      );
    }
  }

  Future<void> _editarPdf(Map<String, dynamic> horario) async {
    final controller = TextEditingController(text: horario['titulo'] ?? horario['nombre']);
    
    FilePickerResult? resultPicker; 

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text("Editar Horario PDF"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Título del Horario",
                  hintText: "Ej. Horario 2024 - v2",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Para actualizar, es necesario subir el archivo nuevamente.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                   final res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (res != null) {
                    setModalState(() => resultPicker = res);
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: Text(resultPicker != null 
                  ? "Archivo: ${resultPicker!.files.first.name}" 
                  : "Seleccionar nuevo PDF"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (resultPicker == null) {
                   ScaffoldMessenger.of(dialogContext).showSnackBar(
                     const SnackBar(content: Text("Por favor seleccione el nuevo archivo PDF.")),
                   );
                   return;
                }
                Navigator.pop(dialogContext);
                
                // 1. ELIMINAR EL ANTERIOR
                try {
                  await _apiService.eliminarPdfHorario(widget.sedeId, horario['archivo']);
                } catch(e) {
                  print("Error eliminando anterior: $e");
                }

                // 2. SUBIR EL NUEVO
                try {
                  final platformFile = resultPicker!.files.first;
                  final nombre = controller.text;
                  final tipo = horario['tipo'];
                  bool success = false;

                  if (kIsWeb) {
                     if (platformFile.bytes != null) {
                       success = await _apiService.subirPdfHorarioCompleto(widget.sedeId, tipo, platformFile.bytes!, nombre);
                     }
                  } else {
                     if (platformFile.path != null) {
                       success = await _apiService.subirPdfHorarioCompletoPath(widget.sedeId, tipo, platformFile.path!, nombre);
                     }
                  }
                  
                  if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Horario actualizado con éxito')),
                      );
                      _cargarHorarios();
                  } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al subir el nuevo archivo')),
                      );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: $e')),
                  );
                }
              },
              child: const Text("Actualizar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarPdf(String archivo) async {
    try {
      final success = await _apiService.eliminarPdfHorario(widget.sedeId, archivo);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF eliminado exitosamente')),
        );
        _cargarHorarios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar PDF: $e')),
      );
    }
  }

  Widget _buildSeccionTipo(String tipo, String titulo, IconData icono) {
    final horariosTipo = _horarios.where((h) => h['tipo'] == tipo).toList();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Row(
              children: [
                Icon(icono, color: const Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
          ),
          AdminTable(
            isLoading: false, // Ya cargaron
            columns: const [
              DataColumn(label: Text("Título")),
              DataColumn(label: Text("Nombre Archivo")),
              DataColumn(label: Text("Fecha Subida")),
              DataColumn(label: Text("Acciones")),
            ],
            rows: horariosTipo.map((horario) {
              return DataRow(cells: [
                DataCell(Text(horario['titulo'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(horario['nombre'] ?? '', overflow: TextOverflow.ellipsis)),
                DataCell(Text(horario['fecha_subida']?.toString().substring(0, 10) ?? '')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                      onPressed: (horario['archivo'] ?? '').isNotEmpty ? () => _verPdf(horario['archivo']) : null,
                      tooltip: 'Ver PDF',
                    ),
                    if (widget.rol.toLowerCase() == 'admin') ...[
                      IconButton(
                         icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                         onPressed: () => _editarPdf(horario),
                         tooltip: 'Editar PDF',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: (horario['archivo'] ?? '').isNotEmpty ? () => _eliminarPdf(horario['archivo']) : null,
                        tooltip: 'Eliminar PDF',
                      ),
                    ],
                  ],
                )),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDocente = widget.rol.toLowerCase() == 'docente' || widget.rol.toLowerCase() == 'profesor';
    final bool isAdmin = widget.rol.toLowerCase() == 'admin';

    if (isDocente) {
      return AdminCRUDLayout(
        title: "Horarios PDF",
        subtitle: "Descarga y visualización de horarios",
        idSede: widget.sedeId,
        child: SizedBox(
          height: 600,
          child: PdfHorariosContent(sedeId: widget.sedeId),
        ),
      );
    }

    return AdminCRUDLayout(
      title: "Gestión de Horarios PDF",
      subtitle: "Subir y administrar horarios institucionales",
      idSede: widget.sedeId,
      // Custom actions provided in body
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ACTION BUTTONS ROW
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _tiposHorarios.map((tipoInfo) => 
                        ElevatedButton.icon(
                          onPressed: () => _subirPdf(tipoInfo['tipo']!),
                          icon: const Icon(Icons.upload_file),
                          label: Text('Subir ${tipoInfo['titulo']!}'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),

                // LISTA DE PDFS
                 isAdmin 
                    ? _buildListaAdmin()
                    : _buildVistaDocente(),
              ],
            ),
    );
  }
  
  Widget _buildListaAdmin() {
    if (_horarios.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No hay PDFs subidos',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // We can use ListView with headers inside the layout card
    return Column(
      children: [
        // Horarios de Aulas
        if (_horarios.any((h) => h['tipo'] == 'aulas'))
          _buildSeccionTipo('aulas', 'Horarios de Aulas', Icons.meeting_room_rounded),
          
        // Horarios de Cursos
        if (_horarios.any((h) => h['tipo'] == 'cursos'))
          _buildSeccionTipo('cursos', 'Horarios de Cursos', Icons.class_rounded),
          
        // Horarios de Docentes
        if (_horarios.any((h) => h['tipo'] == 'docentes'))
          _buildSeccionTipo('docentes', 'Horarios de Docentes', Icons.person_rounded),
      ],
    );
  }
  
  Widget _buildVistaDocente() {
    if (_horarios.isEmpty) {
      return const Center(
        child: Text(
          'No hay horarios disponibles para descargar.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_horarios.any((h) => h['tipo'] == 'aulas'))
            _buildSeccionTipoDocente('aulas', 'Horarios de Aulas', Icons.meeting_room),
          if (_horarios.any((h) => h['tipo'] == 'aulas'))
            const SizedBox(height: 24),
          
          if (_horarios.any((h) => h['tipo'] == 'cursos'))
            _buildSeccionTipoDocente('cursos', 'Horarios de Cursos', Icons.class_),
          if (_horarios.any((h) => h['tipo'] == 'cursos'))
            const SizedBox(height: 24),
          
          if (_horarios.any((h) => h['tipo'] == 'docentes'))
            _buildSeccionTipoDocente('docentes', 'Horarios de Docentes', Icons.person),
        ],
      ),
    );
  }
  
  void _mostrarPdfs() {
    if (_horarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay horarios disponibles')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Horarios Disponibles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // Horarios de Aulas
                  if (_horarios.any((h) => h['tipo'] == 'aulas'))
                    _buildSeccionTipoDocente('aulas', 'Horarios de Aulas', Icons.meeting_room),
                  if (_horarios.any((h) => h['tipo'] == 'aulas'))
                    SizedBox(height: 16),
                  
                  // Horarios de Cursos
                  if (_horarios.any((h) => h['tipo'] == 'cursos'))
                    _buildSeccionTipoDocente('cursos', 'Horarios de Cursos', Icons.class_),
                  if (_horarios.any((h) => h['tipo'] == 'cursos'))
                    SizedBox(height: 16),
                  
                  // Horarios de Docentes
                  if (_horarios.any((h) => h['tipo'] == 'docentes'))
                    _buildSeccionTipoDocente('docentes', 'Horarios de Docentes', Icons.person),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSeccionTipoDocente(String tipo, String titulo, IconData icono) {
    final horariosTipo = _horarios.where((h) => h['tipo'] == tipo).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        SizedBox(height: 8),
        ...horariosTipo.map((horario) => Card(
          margin: EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: Icon(icono, color: Colors.green, size: 40),
            title: Text(horario['titulo'] ?? 'Sin título'),
            subtitle: Text('Nombre: ${horario['nombre'] ?? ''}'),
            trailing: IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue),
              onPressed: (horario['archivo'] ?? '').isNotEmpty ? () => _verPdf(horario['archivo']) : null,
              tooltip: 'Ver PDF',
            ),
          ),
        )).toList(),
      ],
    );
  }
}

class PdfHorariosContent extends StatefulWidget {
  final int sedeId;

  const PdfHorariosContent({Key? key, required this.sedeId}) : super(key: key);

  @override
  _PdfHorariosContentState createState() => _PdfHorariosContentState();
}

class _PdfHorariosContentState extends State<PdfHorariosContent> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _horarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    try {
      final response = await _apiService.listarPdfHorarios(widget.sedeId);
      if (mounted) {
        setState(() {
          _horarios = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verPdf(String archivo) async {
    try {
      final url = Uri.parse("${_apiService.baseUrl}/pdf-horarios/ver/${widget.sedeId}/$archivo");
      // Use launchUrl instead of html.window.open
       if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_horarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay horarios disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_horarios.any((h) => h['tipo'] == 'aulas'))
            _buildSection('Horarios de Aulas', 'aulas', Icons.meeting_room_rounded, Colors.orange),
          
          if (_horarios.any((h) => h['tipo'] == 'cursos'))
            _buildSection('Horarios de Cursos', 'cursos', Icons.class_rounded, Colors.blue),
          
          if (_horarios.any((h) => h['tipo'] == 'docentes'))
            _buildSection('Horarios de Docentes', 'docentes', Icons.person_rounded, Colors.green),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String type, IconData icon, Color color) {
    final items = _horarios.where((h) => h['tipo'] == type).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            title: Text(
              item['titulo'] ?? 'Sin título',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              item['nombre'] ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.grey),
              onPressed: () => _verPdf(item['archivo']),
              tooltip: "Ver/Descargar",
            ),
            onTap: () => _verPdf(item['archivo']),
          ),
        )).toList(),
        const SizedBox(height: 16),
      ],
    );
  }
}