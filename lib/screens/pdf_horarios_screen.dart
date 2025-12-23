import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import '../services/api_service.dart';

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
        final file = result.files.first;
        
        // Después pedir nombre
        String? nombre = await _mostrarDialogoNombre();
        if (nombre == null || nombre.isEmpty) return;
        
        // Crear FormData para enviar nombre y archivo
        final url = Uri.parse("${_apiService.baseUrl}/pdf-horarios/subir/${widget.sedeId}/$tipo?nombre=$nombre");
        final request = html.HttpRequest();
        request.open('POST', url.toString());
        
        final formData = html.FormData();
        formData.appendBlob('file', html.Blob([file.bytes!]), file.name);
        
        request.send(formData);
        
        request.onLoadEnd.listen((e) {
          if (request.status == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF "$nombre" subido exitosamente')),
            );
            _cargarHorarios();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al subir PDF')),
            );
          }
        });
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
      final url = "${_apiService.baseUrl}/pdf-horarios/ver/${widget.sedeId}/$archivo";
      html.window.open(url, '_blank');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF abierto')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir PDF: $e')),
      );
    }
  }

  Future<void> _eliminarPdf(String archivo) async {
    try {
      final url = Uri.parse("${_apiService.baseUrl}/pdf-horarios/eliminar/${widget.sedeId}/$archivo");
      final response = await html.HttpRequest.request(
        url.toString(),
        method: 'DELETE',
      );
      
      if (response.status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF eliminado exitosamente')),
        );
        _cargarHorarios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar PDF')),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre: ${horario['nombre'] ?? ''}'),
                if ((horario['fecha_subida'] ?? '').isNotEmpty)
                  Text('Subido: ${horario['fecha_subida'].toString().substring(0, 10)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.visibility, color: Colors.blue),
                  onPressed: (horario['archivo'] ?? '').isNotEmpty ? () => _verPdf(horario['archivo']) : null,
                  tooltip: 'Ver PDF',
                ),
                if (widget.rol == 'admin')
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: (horario['archivo'] ?? '').isNotEmpty ? () => _eliminarPdf(horario['archivo']) : null,
                    tooltip: 'Eliminar PDF',
                  ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rol == 'admin' ? 'PDF Horarios' : 'Horarios'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Botón para subir nuevo PDF (solo admin)
                if (widget.rol == 'admin')
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: _tiposHorarios.map((tipoInfo) => 
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: ElevatedButton.icon(
                              onPressed: () => _subirPdf(tipoInfo['tipo']!),
                              icon: Icon(Icons.upload_file),
                              label: Text('Subir ${tipoInfo['titulo']!}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                
                // Botón para ver PDFs (solo docentes)
                if (widget.rol == 'docente')
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarPdfs(),
                      icon: Icon(Icons.picture_as_pdf),
                      label: Text('Ver Horarios PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ),
                
                // Lista de PDFs (admin) o mensaje (docente)
                Expanded(
                  child: widget.rol == 'admin' 
                    ? _buildListaAdmin()
                    : _buildVistaDocente(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildListaAdmin() {
    return _horarios.isEmpty
        ? Center(
            child: Text(
              'No hay PDFs subidos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Horarios de Aulas
                if (_horarios.any((h) => h['tipo'] == 'aulas'))
                  _buildSeccionTipo('aulas', 'Horarios de Aulas', Icons.meeting_room),
                if (_horarios.any((h) => h['tipo'] == 'aulas'))
                  SizedBox(height: 16),
                
                // Horarios de Cursos
                if (_horarios.any((h) => h['tipo'] == 'cursos'))
                  _buildSeccionTipo('cursos', 'Horarios de Cursos', Icons.class_),
                if (_horarios.any((h) => h['tipo'] == 'cursos'))
                  SizedBox(height: 16),
                
                // Horarios de Docentes
                if (_horarios.any((h) => h['tipo'] == 'docentes'))
                  _buildSeccionTipo('docentes', 'Horarios de Docentes', Icons.person),
              ],
            ),
          );
  }
  
  Widget _buildVistaDocente() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Consulta de Horarios',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Presiona "Ver Horarios PDF" para consultar\nlos horarios disponibles',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
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