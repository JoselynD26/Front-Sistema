import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';

class MateriaExcelImportScreen extends StatefulWidget {
  final int idSede;
  const MateriaExcelImportScreen({super.key, required this.idSede});

  @override
  State<MateriaExcelImportScreen> createState() => _MateriaExcelImportScreenState();
}

class _MateriaExcelImportScreenState extends State<MateriaExcelImportScreen> {
  final ApiService _api = ApiService();
  
  bool _procesando = false;
  
  // Datos importados
  List<Map<String, dynamic>> _registros = [];
  int _validos = 0;
  int _invalidos = 0;

  // Cache para validaciones
  List<dynamic> _carrerasDisponibles = [];
  List<dynamic> _docentesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosValidacion();
  }

  Future<void> _cargarDatosValidacion() async {
    try {
      final carreras = await _api.listarCarrerasPorSede(widget.idSede);
      final docentes = await _api.listarDocentesPorSede(widget.idSede);
      
      if (mounted) {
        setState(() {
          _carrerasDisponibles = carreras;
          _docentesDisponibles = docentes;
        });
        print("DEBUG: Loaded ${carreras.length} carreras and ${docentes.length} docentes for validation.");
        for(var c in carreras) print("DEBUG: Available Carrera: '${c['nombre']}'");
      }
    } catch (e) {
      debugPrint("Error cargando datos de validación: $e");
    }
  }

  void _descargarPlantilla() {
    var excel = Excel.createExcel();
    
    // Hoja Principal
    Sheet sheet = excel['Plantilla_Materias'];
    excel.setDefaultSheet('Plantilla_Materias');

    // Headers
    List<String> headers = [
      'Nombre Materia', 
      'Carreras (Nombres separadas por coma)', 
      'Docentes (Cédulas separadas por coma)'
    ];
    
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    
    // Ejemplo
    sheet.appendRow([
      TextCellValue("Programación Avanzada"),
      TextCellValue("Desarrollo de Software, Sistemas"),
      TextCellValue("1712345678, 1787654321"),
    ]);

    // Hoja de Referencias (Informativa)
    Sheet refSheet = excel['REFERENCIAS'];
    refSheet.appendRow([TextCellValue("CARRERAS DISPONIBLES EN SEDE"), TextCellValue("DOCENTES DISPONIBLES (Cédula)")].map((e) => e).toList());

    int maxRows = _carrerasDisponibles.length > _docentesDisponibles.length 
        ? _carrerasDisponibles.length 
        : _docentesDisponibles.length;

    for(int i=0; i<maxRows; i++) {
        String carrera = "";
        String docente = "";
        
        if (i < _carrerasDisponibles.length) {
            carrera = _carrerasDisponibles[i]['nombre'] ?? "";
        }
        if (i < _docentesDisponibles.length) {
            docente = "${_docentesDisponibles[i]['cedula']} - ${_docentesDisponibles[i]['apellidos']} ${_docentesDisponibles[i]['nombres']}";
        }
        
        refSheet.appendRow([TextCellValue(carrera), TextCellValue(docente)]);
    }

    var fileBytes = excel.encode();
    
    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error generando archivo Excel")));
      return;
    }

    final blob = html.Blob([Uint8List.fromList(fileBytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "plantilla_materias.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _seleccionarExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      _procesarExcel(result.files.first.bytes!);
    }
  }

  void _procesarExcel(Uint8List bytes) {
    setState(() {
      _procesando = true;
      _registros = [];
      _validos = 0;
      _invalidos = 0;
    });

    try {
      var excel = Excel.decodeBytes(bytes);
      var table = excel.tables[excel.tables.keys.first];
      
      if (table == null || table.maxRows < 2) {
         throw "El archivo parece estar vacío o no tiene el formato correcto.";
      }

      for (var i = 1; i < table.maxRows; i++) {
        var row = table.rows[i];
        if (row.every((c) => c == null || c.value == null)) continue; 

        Map<String, dynamic> registro = {
          'index': i + 1,
          'errors': <String>[],
          'status': 'pending',
          'data': <String, dynamic>{},
          'display': <String, String>{} // Para mostrar en UI
        };

        String getVal(int idx) => idx < row.length ? (row[idx]?.value?.toString().trim() ?? "") : "";

        String nombre = getVal(0);
        String carrerasStr = getVal(1);
        String docentesStr = getVal(2);

        List<String> errs = [];
        if (nombre.isEmpty) errs.add("Nombre de materia requerido");

        // Helper para normalizar texto (minusculas, sin tildes)
        String normalize(String s) {
          return s.toLowerCase()
              .replaceAll(RegExp(r'[áàäâ]'), 'a')
              .replaceAll(RegExp(r'[éèëê]'), 'e')
              .replaceAll(RegExp(r'[íìïî]'), 'i')
              .replaceAll(RegExp(r'[óòöô]'), 'o')
              .replaceAll(RegExp(r'[úùüû]'), 'u')
              .replaceAll('ñ', 'n')
              .replaceAll(RegExp(r'\s+'), ' ') // Normalizar espacios múltiples
              .trim();
        }

        // Validar Carreras
        List<int> carrerasIds = [];
        if (carrerasStr.isNotEmpty) {
           List<String> textCarreras = carrerasStr.split(',').map((e) => e.trim()).toList();
           for (var tc in textCarreras) {
               if (tc.isEmpty) continue;
               
               String busquedaNorm = normalize(tc);

               var match = _carrerasDisponibles.cast<Map<String, dynamic>>().firstWhere(
                   (c) {
                     final nombreNorm = normalize(c['nombre']?.toString() ?? "");
                     // print("DEBUG: Comparing '$busquedaNorm' vs '$nombreNorm'"); // Uncomment for verbose logging
                     return nombreNorm == busquedaNorm;
                   },
                   orElse: () => <String, dynamic>{}
               );
               
               if (match.isNotEmpty) {
                   carrerasIds.add(match['id']);
               } else {
                   print("DEBUG: Failed to match '$tc' (normalized: '$busquedaNorm'). Available: ${_carrerasDisponibles.map((c) => normalize(c['nombre'] ?? "")).toList()}");
                   errs.add("Carrera no encontrada: '$tc'");
               }
           }
        } else {
            errs.add("Debe asignar al menos una carrera");
        }

        // Validar Docentes
        List<int> docentesIds = [];
        if (docentesStr.isNotEmpty) {
           List<String> textDocentes = docentesStr.split(',').map((e) => e.trim()).toList();
           for (var td in textDocentes) {
               if (td.isEmpty) continue;
               // Buscar por cedula
               var match = _docentesDisponibles.firstWhere(
                   (d) => (d['cedula'] ?? "").toString() == td,
                   orElse: () => null
               );
               if (match != null) {
                   docentesIds.add(match['id']);
               } else {
                   errs.add("Docente (Cédula) no encontrado: '$td'");
               }
           }
        }

        registro['data'] = {
           'nombre': nombre,
           'carrera_ids': carrerasIds,
           'docente_ids': docentesIds,
           'sede_ids': [widget.idSede]
        };
        
        registro['display'] = {
            'nombre': nombre,
            'carreras': carrerasStr,
            'docentes': docentesStr
        };

        if (errs.isEmpty) {
           registro['status'] = 'valid';
           _validos++;
        } else {
           registro['status'] = 'error';
           registro['errors'] = errs;
           _invalidos++;
        }
        _registros.add(registro);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error procesamiento: $e")));
    } finally {
      setState(() => _procesando = false);
    }
  }

  Future<void> _importar() async {
    final validos = _registros.where((r) => r['status'] == 'valid').toList();
    if (validos.isEmpty) return;

    setState(() => _procesando = true);
    int okCount = 0;
    int errCount = 0;

    for (var r in validos) {
      final data = r['data'] as Map<String, dynamic>;
      
      bool ok = await _api.crearMateria(data);
      if (ok) {
        r['status'] = 'imported';
        okCount++;
      } else {
        r['status'] = 'error';
        r['errors'].add("Error al guardar en servidor");
        errCount++;
      }
    }

    setState(() {
      _procesando = false;
      _validos = _registros.where((r) => r['status'] == 'valid' || r['status'] == 'imported').length;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text("Importación completada: $okCount exitosos, $errCount fallidos."),
       backgroundColor: errCount == 0 ? Colors.green : Colors.orange,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Importación de Materias",
      subtitle: "Carga masiva desde archivo Excel",
      idSede: widget.idSede,
      scrollable: false,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _descargarPlantilla,
                  icon: const Icon(Icons.download),
                  label: const Text("Descargar Plantilla"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: const Color(0xFFEC4899), // Pink 500 matches Materia theme
                      side: const BorderSide(color: Color(0xFFEC4899))
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _procesando ? null : _seleccionarExcel,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Subir Excel"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white),
                ),
                const Spacer(),
                if (_registros.isNotEmpty)
                  Text("Válidos: $_validos | Errores: $_invalidos", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _procesando
                ? const Center(child: CircularProgressIndicator())
                : _registros.isEmpty
                  ? Center(child: Text("Sube un archivo Excel para comenzar", style: TextStyle(color: Colors.grey[400], fontSize: 18)))
                  : ListView.builder(
                      itemCount: _registros.length,
                      itemBuilder: (context, index) {
                        final r = _registros[index];
                        final bool isError = r['status'] == 'error';
                        final bool isImported = r['status'] == 'imported';
                        final display = r['display'];
                        
                        return Card(
                          color: isError ? Colors.red.shade50 : (isImported ? Colors.green.shade50 : Colors.white),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: Icon(
                              isError ? Icons.error_outline : (isImported ? Icons.check_circle : Icons.check_circle_outline),
                              color: isError ? Colors.red : Colors.green,
                            ),
                            title: Text("${display['nombre']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Carreras: ${display['carreras']} | Docentes: ${display['docentes']}"),
                            children: [
                              if (isError)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: (r['errors'] as List).map<Widget>((e) => Text("• $e", style: const TextStyle(color: Colors.red))).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_registros.where((r) => r['status'] == 'valid').isNotEmpty) ...[
               const SizedBox(height: 16),
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton(
                   onPressed: _procesando ? null : _importar,
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                   child: Text("IMPORTAR ${_registros.where((r) => r['status'] == 'valid').length} MATERIAS"),
                 ),
               )
            ]
          ],
        ),
      ),
    );
  }
}
