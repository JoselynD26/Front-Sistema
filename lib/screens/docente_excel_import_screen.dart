import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html; // For web download
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';

class DocenteExcelImportScreen extends StatefulWidget {
  final int idSede;
  const DocenteExcelImportScreen({super.key, required this.idSede});

  @override
  State<DocenteExcelImportScreen> createState() => _DocenteExcelImportScreenState();
}

class _DocenteExcelImportScreenState extends State<DocenteExcelImportScreen> {
  final ApiService _api = ApiService();
  
  bool _procesando = false;
  
  // Datos importados
  List<Map<String, dynamic>> _registros = [];
  int _validos = 0;
  int _invalidos = 0;

  // Cache de docentes existentes para evitar duplicados de cedula
  List<dynamic> _docentesExistentes = [];

  @override
  void initState() {
    super.initState();
    _cargarDocentesExistentes();
  }

  Future<void> _cargarDocentesExistentes() async {
    try {
      // Necesitamos todos los docentes para validar cedula unica, quizas listarDocentesPorSede baste
      // pero idealmente deberiamos chequear contra toda la base si la cedula es unica globalmente?
      // Por ahora chequeamos sede.
      final data = await _api.listarDocentesPorSede(widget.idSede);
      setState(() {
        _docentesExistentes = data;
      });
    } catch (e) {
      debugPrint("Error cargando docentes existentes: $e");
    }
  }

  void _descargarPlantilla() {
    var excel = Excel.createExcel();
    
    // 1. Hoja Principal
    Sheet sheet = excel['Plantilla_Docentes'];
    excel.setDefaultSheet('Plantilla_Docentes');

    // Headers
    List<String> headers = [
      'cedula', 
      'nombres', 
      'apellidos', 
      'correo', 
      'regimen', // LOES / Codigo de trabajo
      'dedicacion' // Medio tiempo / Tiempo completo
    ];
    
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    
    // Ejemplo
    sheet.appendRow([
      TextCellValue("1712345678"),
      TextCellValue("Juan Pablo"),
      TextCellValue("Perez Garcia"),
      TextCellValue("juan.perez@yavirac.edu.ec"),
      TextCellValue("LOES"),
      TextCellValue("Tiempo completo"),
    ]);

    // 2. Hoja de Referencias
    Sheet refSheet = excel['REFERENCIAS'];
    refSheet.appendRow([
      TextCellValue("REGIMEN VALIDOS"),
      TextCellValue("DEDICACION VALIDAS")
    ].map((e) => e).toList());

    refSheet.appendRow([TextCellValue("LOES"), TextCellValue("Tiempo completo")]);
    refSheet.appendRow([TextCellValue("Codigo de trabajo"), TextCellValue("Medio tiempo")]);

    var fileBytes = excel.encode();
    
    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error generando archivo Excel")));
      return;
    }

    final blob = html.Blob([Uint8List.fromList(fileBytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "plantilla_docentes.xlsx")
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
          'data': <String, dynamic>{}
        };

        String getVal(int idx) => idx < row.length ? (row[idx]?.value?.toString().trim() ?? "") : "";

        String cedula = getVal(0);
        String nombres = getVal(1);
        String apellidos = getVal(2);
        String correo = getVal(3);
        // String titulo = getVal(4); // Eliminado
        String regimen = getVal(4);
        String dedicacion = getVal(5);

        // Map values if needed
        // Validar Cedula (length? algoritmos?)
        // Por ahora Check empty
        
        List<String> errs = [];
        if (cedula.isEmpty) errs.add("Cédula requerida");
        if (nombres.isEmpty) errs.add("Nombres requeridos");
        if (apellidos.isEmpty) errs.add("Apellidos requeridos");
        if (correo.isEmpty) errs.add("Correo requerido");

        // Validar duplicado excel
        if (_registros.any((r) => r['data']['cedula'] == cedula)) {
           errs.add("Cédula duplicada en el archivo");
        }

        // Validar duplicado sistema
        if (_docentesExistentes.any((d) => d['cedula'].toString() == cedula)) {
           errs.add("Docente ya existe en el sistema (Cédula)");
        }

        registro['data'] = {
           'cedula': cedula,
           'nombres': nombres,
           'apellidos': apellidos,
           'correo': correo,
           'regimen': regimen.isEmpty ? "LOES" : regimen,
           'observacion': dedicacion.isEmpty ? "Tiempo completo" : dedicacion,
           'sede_id': widget.idSede
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
      
      // Adaptar campos al API si es necesario
      // API createDocente: {cedula, nombres, apellidos, correo, regimen, observacion, sede_id}
      
      bool ok = await _api.crearDocente(data);
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

    _cargarDocentesExistentes(); // Refresh

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text("Importación completada: $okCount exitosos, $errCount fallidos."),
       backgroundColor: errCount == 0 ? Colors.green : Colors.orange,
    ));
    
    if (errCount == 0 && okCount > 0) {
      // Opcional: Cerrar pantalla si todo perfecto
      // Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Importación de Docentes",
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple, side: const BorderSide(color: Colors.deepPurple)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _procesando ? null : _seleccionarExcel,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Subir Excel"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
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
                        final data = r['data'];
                        
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
                            title: Text("${data['nombres']} ${data['apellidos']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${data['cedula']} | ${data['correo']}"),
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
                   child: Text("IMPORTAR ${_registros.where((r) => r['status'] == 'valid').length} DOCENTES"),
                 ),
               )
            ]
          ],
        ),
      ),
    );
  }
}
