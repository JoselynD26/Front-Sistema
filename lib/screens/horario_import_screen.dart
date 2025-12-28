import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';

class HorarioImportScreen extends StatefulWidget {
  final int idSede;
  const HorarioImportScreen({super.key, required this.idSede});

  @override
  State<HorarioImportScreen> createState() => _HorarioImportScreenState();
}

class _HorarioImportScreenState extends State<HorarioImportScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _textController = TextEditingController();
  
  bool _procesando = false;
  Uint8List? _pdfBytes;
  String? _pdfName;
  List<Map<String, dynamic>> _registrosDetectados = [];
  
  // Referencias para el mapeo (en desarrollo)
  List<dynamic> _docentes = [];
  List<dynamic> _materias = [];
  List<dynamic> _aulas = [];
  List<dynamic> _cursos = [];
  Map<int, String> _carrerasMap = {};

  @override
  void initState() {
    super.initState();
    _cargarReferencias();
  }

  Future<void> _cargarReferencias() async {
    try {
      final res = await Future.wait([
        _api.listarDocentesPorSede(widget.idSede),
        _api.listarMateriasPorSede(widget.idSede),
        _api.listarAulasPorSede(widget.idSede),
        _api.listarCursosPorSede(widget.idSede),
        _api.listarCarreras(),
      ]);
      final docs = res[0] as List;
      final mats = res[1] as List;
      final auls = res[2] as List;
      final curs = res[3] as List;
      final carrs = res[4] as List;

      final Map<int, String> cMap = {};
      for (var c in carrs) {
        if (c["id"] != null) cMap[c["id"]] = c["nombre"] ?? "";
      }

      final Map<int, dynamic> uniqueDocs = {};
      for (var d in docs) {
        if (d['id'] != null) uniqueDocs[d['id']] = d;
      }
      final sortedDocs = uniqueDocs.values.toList();
      sortedDocs.sort((a, b) {
        final apeA = (a['apellidos'] ?? '').toString().trim().toLowerCase();
        final apeB = (b['apellidos'] ?? '').toString().trim().toLowerCase();
        final cmp = apeA.compareTo(apeB);
        if (cmp != 0) return cmp;
        
        final nomA = (a['nombres'] ?? '').toString().trim().toLowerCase();
        final nomB = (b['nombres'] ?? '').toString().trim().toLowerCase();
        return nomA.compareTo(nomB);
      });

      mats.sort((a, b) => (a['nombre'] ?? "").toString().toLowerCase().compareTo((b['nombre'] ?? "").toString().toLowerCase()));
      auls.sort((a, b) => (a['nombre'] ?? "").toString().toLowerCase().compareTo((b['nombre'] ?? "").toString().toLowerCase()));
      
      curs.sort((a, b) {
        final nomCarreraA = cMap[a["carrera_id"]]?.toLowerCase() ?? "";
        final nomCarreraB = cMap[b["carrera_id"]]?.toLowerCase() ?? "";
        final cmpCarrera = nomCarreraA.compareTo(nomCarreraB);
        if (cmpCarrera != 0) return cmpCarrera;

        final nomA = (a["nombre"] ?? "").toString().toLowerCase();
        final nomB = (b["nombre"] ?? "").toString().toLowerCase();
        return nomA.compareTo(nomB);
      });

      for (var c in curs) {
        c['carrera_nombre'] = cMap[c['carrera_id']] ?? "N/A";
      }

      setState(() {
        _docentes = sortedDocs;
        _materias = mats;
        _aulas = auls;
        _cursos = curs;
        _carrerasMap = cMap;
      });
    } catch (e) {
      debugPrint("Error cargando referencias: $e");
    }
  }

  int? _buscarDocenteId(String nombrePdf) {
    if (nombrePdf == "Desconocido") return null;
    final normalizedPdf = nombrePdf.toLowerCase().replaceAll(' ', '');
    for (var d in _docentes) {
      final nomComp = "${d['nombres']} ${d['apellidos']}".toLowerCase().replaceAll(' ', '');
      final nomInv = "${d['apellidos']} ${d['nombres']}".toLowerCase().replaceAll(' ', '');
      if (normalizedPdf.contains(nomComp) || normalizedPdf.contains(nomInv) || 
          nomComp.contains(normalizedPdf) || nomInv.contains(normalizedPdf)) {
        return d['usuario_id'] ?? d['id'];
      }
    }
    return null;
  }

  int? _buscarMateriaId(String texto) {
    for (var m in _materias) {
      if (texto.toLowerCase().contains(m['nombre'].toString().toLowerCase())) return m['id'];
    }
    return null;
  }

  int? _buscarAulaId(String texto) {
    for (var a in _aulas) {
      if (texto.toLowerCase().contains(a['nombre'].toString().toLowerCase())) return a['id'];
    }
    return null;
  }

  int? _buscarCursoId(String texto) {
    for (var c in _cursos) {
      if (texto.toLowerCase().contains(c['nombre'].toString().toLowerCase())) return c['id'];
    }
    return null;
  }

  Future<void> _subirYEscanear() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.first.bytes != null) {
        debugPrint("PDF Seleccionado: ${result.files.first.name} (${result.files.first.size} bytes)");
        setState(() {
          _procesando = true;
          _pdfBytes = result.files.first.bytes;
          _pdfName = result.files.first.name;
          _registrosDetectados = [];
        });
        
        final bytes = _pdfBytes!;
        debugPrint("Iniciando procesamiento de documento Syncfusion...");
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        
        // Extraemos TODO de una vez para evitar lentitud en el loop
        debugPrint("Extrayendo todas las líneas del documento (esta operación puede tardar)...");
        final List<TextLine> allLines = extractor.extractTextLines(); 
        debugPrint("Total de líneas extraídas: ${allLines.length}");
        
        if (allLines.isEmpty) {
          setState(() => _procesando = false);
          return;
        }

        // 1. Identificar delimitadores (nombres de profesores o cabeceras)
        // Agrupamos las líneas por página física o por proximidad
        List<Map<String, dynamic>> detectedRecords = [];
        
        // Buscamos los anchors de días y horas globales 
        final dayAnchors = <String, double>{};
        final hourAnchors = <Map<String, dynamic>>[];
        
        for (var line in allLines) {
          final t = line.text.trim();
          if (["Lu", "Ma", "Mi", "Ju", "Vi"].contains(t)) {
            dayAnchors[t] = line.bounds.left + (line.bounds.width / 2);
          }
          final match = RegExp(r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})').firstMatch(t);
          if (match != null) {
            hourAnchors.add({
              'start': match.group(1),
              'end': match.group(2),
              'y': line.bounds.top + (line.bounds.height / 2),
            });
          }
        }

        debugPrint("Días detectados: ${dayAnchors.keys.toList()}");
        debugPrint("Segmentos horarios detectados: ${hourAnchors.length}");

        // 2. Procesamiento espacial
        // Agrupamos por docente preguntando quién es el más cercano arriba de este bloque
        String? currentTeacher;
        final dayLabelMap = {"Lu": "Lunes", "Ma": "Martes", "Mi": "Miércoles", "Ju": "Jueves", "Vi": "Viernes"};

        for (var line in allLines) {
          final t = line.text.trim();
          if (t.isEmpty || t.length < 2) continue;
          if (t.contains("Minha Escola") || t.contains("Horario generado") || t.contains("aSc Horarios")) continue;
          if (dayAnchors.containsKey(t)) continue;
          if (RegExp(r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})').hasMatch(t)) continue;
          if (RegExp(r'^\d+$').hasMatch(t)) continue;

          // Es un posible nombre de docente si es texto largo y está "arriba" de las horas significativamente
          // O simplemente detectamos el cambio de página/bloque.
          // En el PDF del usuario, el nombre está en grande arriba.
          if (t == t.toUpperCase() && t.split(' ').length >= 2 && line.bounds.top < 100) {
            currentTeacher = t;
            debugPrint("Cambiando a docente: $currentTeacher");
            continue;
          }

          if (currentTeacher == null) continue;

          // Encontrar el día más cercano (X)
          String? bestDay;
          double minDistX = 100; // Umbral de proximidad
          dayAnchors.forEach((day, x) {
            double dx = (line.bounds.left + (line.bounds.width / 2) - x).abs();
            if (dx < minDistX) {
              minDistX = dx;
              bestDay = day;
            }
          });

          // Encontrar la hora más cercana (Y)
          Map<String, dynamic>? bestHour;
          double minDistY = 15; // Umbral de altura de celda
          for (var hour in hourAnchors) {
            double dy = (line.bounds.top + (line.bounds.height / 2) - hour['y']).abs();
            if (dy < minDistY) {
              minDistY = dy;
              bestHour = hour;
            }
          }

          if (bestDay != null && bestHour != null) {
            final materiaStr = t;
            final dId = _buscarDocenteId(currentTeacher);
            final mId = _buscarMateriaId(materiaStr);
            final aId = _buscarAulaId(materiaStr);
            final cId = _buscarCursoId(materiaStr);

            detectedRecords.add({
              'docente_str': currentTeacher,
              'docente_id': dId,
              'materia_id': mId,
              'aula_id': aId,
              'curso_id': cId,
              'hora_inicio': bestHour['start'],
              'hora_fin': bestHour['end'],
              'materia_str': materiaStr,
              'dia': dayLabelMap[bestDay],
              'selected': dId != null && mId != null,
            });
          }
        }

        document.dispose();
        
        setState(() {
          _registrosDetectados = detectedRecords;
          _procesando = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() => _procesando = false);
        debugPrint("Error escaneando PDF: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al leer el PDF: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _importarSeleccionados() async {
    final toSave = _registrosDetectados.where((r) => r['selected']).toList();
    if (toSave.isEmpty) return;

    setState(() => _procesando = true);
    
    // 1. Respaldar PDF en Supabase
    String? publicUrl;
    if (_pdfBytes != null) {
      publicUrl = await _api.subirHorarioPDF(_pdfBytes!, _pdfName ?? "horario.pdf");
      debugPrint("PDF Respaldado en: $publicUrl");
    }

    int creados = 0;
    int fallidos = 0;

    for (var reg in toSave) {
      final ok = await _api.crearHorarioAdmin(
        docenteId: reg['docente_id'],
        cursoId: reg['curso_id'],
        materiaId: reg['materia_id'],
        aulaId: reg['aula_id'],
        dia: reg['dia'],
        horaInicio: reg['hora_inicio'],
        horaFin: reg['hora_fin'],
        // pdf_url: publicUrl, // Si el backend soporta registro del log
      );
      if (ok) creados++; else fallidos++;
    }

    if (mounted) {
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Importación finalizada: $creados creados, $fallidos fallaron."),
          backgroundColor: fallidos == 0 ? Colors.green : Colors.orange,
        )
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Escáner de Horarios",
      subtitle: "Importación inteligente desde PDF de aSc Horarios",
      idSede: widget.idSede,
      scrollable: false,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (_registrosDetectados.isEmpty) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, size: 80, color: Colors.indigo),
                    const SizedBox(height: 24),
                    const Text(
                      "Carga tu archivo PDF de aSc Horarios",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "El sistema detectará automáticamente a cada docente y su carga horaria.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _procesando ? null : _subirYEscanear,
                      icon: _procesando ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.upload_file),
                      label: Text(_procesando ? "ANALIZANDO..." : "SELECCIONAR ARCHIVO PDF"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Resultados del escaneo
              Row(
                children: [
                  Text("${_registrosDetectados.length} clases detectadas", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _registrosDetectados = []),
                    icon: const Icon(Icons.refresh),
                    label: const Text("CAMBIAR ARCHIVO"),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _registrosDetectados.length,
                  itemBuilder: (context, index) {
                    final reg = _registrosDetectados[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade50,
                          child: Text(reg['dia'].toString().substring(0,1), style: const TextStyle(color: Colors.indigo)),
                        ),
                        title: Text(reg['materia_str'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${reg['dia']} | ${reg['hora_inicio']} - ${reg['hora_fin']}"),
                            Text("👤 ${reg['docente_str']}", style: TextStyle(color: Colors.indigo.shade700, fontSize: 12)),
                          ],
                        ),
                        trailing: Checkbox(
                          value: reg['selected'],
                          onChanged: (v) => setState(() => reg['selected'] = v),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _importarSeleccionados,
                icon: const Icon(Icons.cloud_done),
                label: Text("GUARDAR ${_registrosDetectados.where((r)=>r['selected']).length} REGISTROS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  minimumSize: const Size(double.infinity, 60)
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
