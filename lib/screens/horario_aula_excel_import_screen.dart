import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html; // For web download
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import 'aula_screen.dart';

class HorarioAulaExcelImportScreen extends StatefulWidget {
  final int idSede;
  const HorarioAulaExcelImportScreen({super.key, required this.idSede});

  @override
  State<HorarioAulaExcelImportScreen> createState() => _HorarioAulaExcelImportScreenState();
}

class _HorarioAulaExcelImportScreenState extends State<HorarioAulaExcelImportScreen> {
  final ApiService _api = ApiService();
  
  // Referencias para validación y mapeo
  List<dynamic> _docentes = [];
  List<dynamic> _materias = [];
  List<dynamic> _aulas = [];
  List<dynamic> _cursos = [];
  List<dynamic> _carreras = []; // New list for careers
  
  // Cache de horarios existentes para detectar conflictos: AulaID -> Lista de horarios
  Map<int, List<dynamic>> _horariosExistentesPorAula = {};
  
  bool _cargandoReferencias = true;
  bool _procesando = false;
  
  // Datos importados
  List<Map<String, dynamic>> _registros = [];
  int _validos = 0;
  int _invalidos = 0;

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
        _api.listarCarreras(), // Fetch all careers
      ]);
      
      _docentes = res[0] as List;
      _materias = res[1] as List;
      _aulas = res[2] as List;
      _cursos = res[3] as List;
      _carreras = res[4] as List;

      print("--- DEBUG DATA CARGADA ---");
      // print("Aulas: ${_aulas.length}");
      // print("Docentes: ${_docentes.length}");
      
      // Cargar horarios existentes para validación de conflictos (Pesado pero necesario)
      // Estrategia: Cargar horarios de TODOS los docentes y organizarlos por aula
      final List<dynamic> recurrentesTotal = [];
      
      // Cargar TODO el horario docente de la sede en una sola petición (Optimizado)
      // Esto evita el error "Failed to fetch" por saturación de conexiones
      final allSchedules = await _api.listarHorariosDocentesPorSede(widget.idSede);
      recurrentesTotal.addAll(allSchedules);

      // Agrupar por aula
      for (var h in recurrentesTotal) {
        final aId = h["aula_id"] ?? h["id_aula"];
        if (aId != null) {
          if (!_horariosExistentesPorAula.containsKey(aId)) {
            _horariosExistentesPorAula[aId] = [];
          }
          _horariosExistentesPorAula[aId]!.add(h);
        }
      }

      setState(() => _cargandoReferencias = false);
    } catch (e) {
      debugPrint("Error loading references: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cargando referencias: $e")));
      }
    }
  }

  void _descargarPlantilla() {
    var excel = Excel.createExcel();
    
    // 1. Hoja Principal
    Sheet sheet = excel['Plantilla_Horarios'];
    excel.setDefaultSheet('Plantilla_Horarios');

    // Headers
    List<String> headers = [
      'aula_nombre', 
      'carrera_nombre', // Nuevo
      'docente_cedula', 
      'curso_nombre', 
      'curso_paralelo', 
      'materia_nombre', 
      'dia', 
      'hora_inicio', 
      'hora_fin', 
      'jornada'
    ];
    
    // Estilo para headers (negrita si fuera posible, pero librería básica)
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    
    // Ejemplo
    sheet.appendRow([
      TextCellValue("Laboratorio 1"),
      TextCellValue("Desarrollo de Software"), // Ejemplo carrera
      TextCellValue("1234567890"),
      TextCellValue("1ro"),
      TextCellValue("A"),
      TextCellValue("Programación"),
      TextCellValue("Lunes"),
      TextCellValue("08:00"),
      TextCellValue("10:00"),
      TextCellValue("Matutina"),
    ]);

    // 2. Hoja de Referencias (Ayuda para el usuario)
    Sheet refSheet = excel['REFERENCIAS_VALIDAS'];
    refSheet.appendRow([
      TextCellValue("AULAS DISPONIBLES"),
      TextCellValue("CARRERAS"),
      TextCellValue("CURSOS"),
      TextCellValue("PARALELOS"),
      TextCellValue("DÍAS"),
      TextCellValue("JORNADAS"),
      TextCellValue("MATERIAS EJEMPLO")
    ].map((e) => e).toList());

    // Preparar listas para columnas
    final dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    final jornadas = ["Matutina", "Vespertina", "Nocturna"];
    final paralelos = ["A", "B", "C", "D", "E", "F"]; // Comunes
    
    // Obtener nombres únicos de cursos
    final Set<String> cursosUnicosSet = {};
    for (var c in _cursos) {
      if (c['nombre'] != null) cursosUnicosSet.add(c['nombre'].toString());
    }
    final List<String> cursosUnicos = cursosUnicosSet.toList()..sort();
    
    // Determinar el máximo de filas necesarias
    int maxRows = [_aulas.length, _carreras.length, cursosUnicos.length, _materias.length, dias.length].reduce((curr, next) => curr > next ? curr : next);
    
    for (int i = 0; i < maxRows; i++) {
        List<CellValue?> row = [];
        
        // Aulas
        if (i < _aulas.length) row.add(TextCellValue(_aulas[i]['nombre'] ?? ""));
        else row.add(null);

        // Carreras
        if (i < _carreras.length) row.add(TextCellValue(_carreras[i]['nombre'] ?? ""));
        else row.add(null);

        // Cursos (Nombre único)
        if (i < cursosUnicos.length) {
             row.add(TextCellValue(cursosUnicos[i]));
        } else row.add(null);

        // Paralelos
        if (i < paralelos.length) row.add(TextCellValue(paralelos[i]));
        else row.add(null);
        
        // Días
        if (i < dias.length) row.add(TextCellValue(dias[i]));
        else row.add(null);

        // Jornadas
        if (i < jornadas.length) row.add(TextCellValue(jornadas[i]));
        else row.add(null);

        // Materias
        if (i < _materias.length) row.add(TextCellValue(_materias[i]['nombre'] ?? ""));
        else row.add(null);

        refSheet.appendRow(row.toList());
    }
    
    // Auto-fit columnas no soportado nativamente fácil, pero los datos están ahí.

    // Forzar guardado y codificación usando encode() que es más seguro
    var fileBytes = excel.encode();
    
    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error generando archivo Excel")));
      return;
    }

    // Descarga Web
    final blob = html.Blob([Uint8List.fromList(fileBytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "plantilla_horarios_aulas.xlsx")
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
      // Asumimos primera hoja
      var table = excel.tables[excel.tables.keys.first];
      
      if (table == null || table.maxRows < 2) {
         throw "El archivo parece estar vacío o no tiene el formato correcto.";
      }

      // Omitir cabecera (fila 0)
      for (var i = 1; i < table.maxRows; i++) {
        var row = table.rows[i];
        if (row.every((c) => c == null || c.value == null)) continue; // Fila vacía

        Map<String, dynamic> registro = {
          'index': i + 1,
          'errors': <String>[],
          'status': 'pending',
          'data': <String, dynamic>{}
        };

        // Extraer valores crudos
        String getVal(int idx) => idx < row.length ? (row[idx]?.value?.toString().trim() ?? "") : "";

        String aulaNombre = getVal(0);
        String carreraNombre = getVal(1); // Columna Nueva
        String docenteCedula = getVal(2);
        String cursoNombre = getVal(3);
        String cursoParalelo = getVal(4);
        String materiaNombre = getVal(5);
        String dia = getVal(6);
        String horaInicio = getVal(7);
        String horaFin = getVal(8);
        String jornada = getVal(9);
        
        // --- Normalización de Horas (Excel a veces usa decimales para tiempo) ---
        String normalizarHora(String raw) {
            // Un formato simple HH:MM
            // Si viene de excel como double (ej. 0.333) habría que convertir, pero la librería 'excel' suele dar el valor string si es TextCellValue
            // Si es numérico, intentamos convertir. 
            // Para simplificar, asumimos que el usuario pone Texto en Excel "08:00"
            // Reintentamos formatear HH:mm
            if (!raw.contains(":")) return raw; 
            var parts = raw.split(":");
            if (parts.length < 2) return raw;
            return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
        }
        
        horaInicio = normalizarHora(horaInicio);
        horaFin = normalizarHora(horaFin);

        registro['data'] = {
           'aula_nombre': aulaNombre,
           'carrera_nombre': carreraNombre,
           'docente_cedula': docenteCedula,
           'curso_nombre': cursoNombre,
           'curso_paralelo': cursoParalelo,
           'materia_nombre': materiaNombre,
           'dia': dia,
           'hora_inicio': horaInicio,
           'hora_fin': horaFin,
           'jornada': jornada
        };

        // --- VALIDACIONES ---
        List<String> errs = [];

        // 1. Aula
        var aula = _aulas.cast<Map>().where((a) => (a['nombre']?.toString().toLowerCase() == aulaNombre.toLowerCase())).firstOrNull;
        if (aula == null) errs.add("Aula no encontrada: $aulaNombre");

        // 2. Carrera
        var carrera = _carreras.cast<Map>().where((c) => (c['nombre']?.toString().toLowerCase() == carreraNombre.toLowerCase())).firstOrNull;
        if (carrera == null) {
           errs.add("Carrera no encontrada: $carreraNombre");
        }

        // 3. Docente
        var docente = _docentes.cast<Map>().where((d) => (d['cedula']?.toString() == docenteCedula)).firstOrNull;
        if (docente == null) {
           errs.add("Docente no encontrado (Cédula): $docenteCedula");
        } else {
           print("DEBUG IMPORT: Cédula $docenteCedula corresponde a Docente ID: ${docente['id']} - ${docente['nombres']}");
        }

        // 4. Curso (Match cursoNombre + paralelo + carrera_id)
        var curso = _cursos.cast<Map>().where((c) {
           bool matchNom = c['nombre']?.toString().toLowerCase() == cursoNombre.toLowerCase();
           bool matchPar = c['paralelo']?.toString().toLowerCase() == cursoParalelo.toLowerCase();
           // Si tenemos carrera válida, validamos que el curso pertenezca a ella
           bool matchCarrera = true;
           if (carrera != null) {
              matchCarrera = c['carrera_id'] == carrera['id'];
           }
           return matchNom && matchPar && matchCarrera;
        }).firstOrNull;

        if (curso == null) {
           if (carrera != null) {
             errs.add("Curso '$cursoNombre' ($cursoParalelo) no encontrado en carrera '${carreraNombre}'");
           } else {
             errs.add("Curso no encontrado: $cursoNombre $cursoParalelo");
           }
        }

        // 5. Materia
        var materia = _materias.cast<Map>().where((m) => (m['nombre']?.toString().toLowerCase() == materiaNombre.toLowerCase())).firstOrNull;
        if (materia == null) errs.add("Materia no encontrada: $materiaNombre");

        // 6. Día
        final diasValidos = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
        if (!diasValidos.contains(dia)) errs.add("Día inválido: $dia");

        // 7. Jornada
        final jornadasValidas = ["Matutina", "Vespertina", "Nocturna"];
        if (!jornadasValidas.contains(jornada)) errs.add("Jornada inválida: $jornada");

        // 8. Horas
        final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
        if (!timeRegex.hasMatch(horaInicio)) errs.add("Hora inicio inválida (HH:MM): $horaInicio");
        if (!timeRegex.hasMatch(horaFin)) errs.add("Hora fin inválida (HH:MM): $horaFin");

        if (errs.isEmpty) {
           // Validar rango horario vs jornada
           int hi = int.parse(horaInicio.split(":")[0]);
           bool rangoOk = true;
           if (jornada == "Matutina" && (hi < 7 || hi > 13)) rangoOk = false;
           if (jornada == "Vespertina" && (hi < 12 || hi > 18)) rangoOk = false;
           if (jornada == "Nocturna" && (hi < 17 || hi > 22)) rangoOk = false;

           if (!rangoOk) errs.add("La hora $horaInicio no coincide con jornada $jornada");

           if (horaInicio.compareTo(horaFin) >= 0) errs.add("Hora inicio debe ser menor a fin");
           
           // Validar Conflictos
           if (aula != null) {
              if (_hayConflicto(aula['id'], dia, horaInicio, horaFin, docente?['id'])) {
                 errs.add("CONFLICTO: Ya existe clase en aula $aulaNombre ($dia $horaInicio-$horaFin)");
              }
              // También validar conflicto CONMIGO MISMO (otras filas del mismo excel)
              // Esto es complejo O(N^2), pero necesario
              if (_hayConflictoInterno(registro['data'], _registros)) {
                 errs.add("CONFLICTO INTERNO: Duplicado en este archivo");
              }
           }
        }

        if (errs.isEmpty) {
           registro['status'] = 'valid';
           registro['parsed'] = {
             'docente_id': docente?['id'],
             'aula_id': aula?['id'],
             'curso_id': curso?['id'],
             'materia_id': materia?['id'],
             'carrera_id': carrera?['id'], // Add carrera_id to parsed data
             'dia': dia,
             'hora_inicio': horaInicio,
             'hora_fin': horaFin,
             'jornada': jornada
           };
           _validos++;
        } else {
           registro['status'] = 'error';
           registro['errors'] = errs;
           _invalidos++;
           // Logs para saber por qué falla sin abrir UI
           if (registro['data']['docente_cedula'] == '1721162400') {
              print(">> ERROR IMPORT RUTH: $errs");
           }
        }

        _registros.add(registro);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error procesamiento: $e")));
    } finally {
      setState(() => _procesando = false);
    }
  }

  bool _hayConflicto(int aulaId, String dia, String ini, String fin, int? docenteId) {
    List<dynamic> existentes = _horariosExistentesPorAula[aulaId] ?? [];
    for (var h in existentes) {
      if (h["dia"] != dia) continue;
      
      // Normalizar horas de DB (pueden venir como HH:MM:SS) a HH:MM para comparación estricta de strings
      String hIni = (h["hora_inicio"] ?? "").toString();
      String hFin = (h["hora_fin"] ?? "").toString();
      
      if (hIni.length > 5) hIni = hIni.substring(0, 5);
      if (hFin.length > 5) hFin = hFin.substring(0, 5);
      
      // Overlap check
      if (ini.compareTo(hFin) < 0 && fin.compareTo(hIni) > 0) {
        // Check for exact duplicate (same teacher, same time)
        if (docenteId != null && h["docente_id"] == docenteId && 
            ini == hIni && fin == hFin) {
             print("DEBUG CONFLICTO: DUPLICADO EXACTO detectado para Docente $docenteId");
             return true; 
        }
        
        print("DEBUG CONFLICTO: DocenteImport: $docenteId vs DocenteExistente: ${h['docente_id']} (Dia: $dia, $hIni-$hFin vs $ini-$fin)");
        return true;
      }
    }
    return false;
  }
  
  bool _hayConflictoInterno(Map<String, dynamic> actual, List<Map<String, dynamic>> anteriores) {
     for (var reg in anteriores) {
       if (reg['status'] != 'valid') continue;
       var data = reg['data'];
       if (data['aula_nombre'] != actual['aula_nombre']) continue;
       if (data['dia'] != actual['dia']) continue;
       
       String iniA = actual['hora_inicio'];
       String finA = actual['hora_fin'];
       String iniB = data['hora_inicio'];
       String finB = data['hora_fin'];
       
       if (iniA.compareTo(finB) < 0 && finA.compareTo(iniB) > 0) {
         return true;
       }
     }
     return false;
  }

  Future<void> _importar() async {
    final validos = _registros.where((r) => r['status'] == 'valid').toList();
    if (validos.isEmpty) return;

    setState(() => _procesando = true);
    int okCount = 0;
    int errCount = 0;

    for (var r in validos) {
      var p = r['parsed'];
      bool ok = await _api.crearHorarioAdmin(
        docenteId: p['docente_id'],
        cursoId: p['curso_id'],
        materiaId: p['materia_id'],
        aulaId: p['aula_id'],
        dia: p['dia'],
        horaInicio: p['hora_inicio'],
        horaFin: p['hora_fin'],
      );
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
      _validos = _registros.where((r) => r['status'] == 'valid' || r['status'] == 'imported').length; // imported ya no es valid en UI strict
      // Recalc stats
    });
    
    // Recargar cache local para evitar doble carga si importamos otro archivo seguido
    _cargarReferencias();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text("Importación completada: $okCount exitosos, $errCount fallidos."),
       backgroundColor: errCount == 0 ? Colors.green : Colors.orange,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Importación Masiva de Horarios",
      subtitle: "Carga horarios de aulas desde Excel",
      idSede: widget.idSede,
      scrollable: false, // Usamos Columna con expanded
      onBack: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AulasScreen(idSede: widget.idSede),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARRA SUPERIOR
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _descargarPlantilla,
                  icon: const Icon(Icons.download),
                  label: const Text("Descargar Plantilla"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo, side: const BorderSide(color: Colors.indigo)),
                ),
                const SizedBox(width: 16),
                if (_cargandoReferencias)
                   const Text("Cargando referencias...", style: TextStyle(color: Colors.grey))
                else
                  ElevatedButton.icon(
                    onPressed: _procesando ? null : _seleccionarExcel,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Subir Excel"),
                  ),
                const Spacer(),
                if (_registros.isNotEmpty)
                  Text("Válidos: $_validos | Errores: $_invalidos", 
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            
            // LISTA PREVIEW
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
                           elevation: 1,
                           margin: const EdgeInsets.only(bottom: 8),
                           child: ExpansionTile(
                             leading: Icon(
                               isError ? Icons.error_outline : (isImported ? Icons.check_circle : Icons.check_circle_outline),
                               color: isError ? Colors.red : Colors.green,
                             ),
                             title: Text("${data['aula_nombre']} - ${data['dia']} ${data['hora_inicio']}"),
                             subtitle: Text("${data['materia_nombre']} | ${data['docente_cedula']}"),
                             children: [
                               if (isError)
                                 Padding(
                                   padding: const EdgeInsets.all(16.0),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: (r['errors'] as List).map<Widget>((e) => Text("• $e", style: const TextStyle(color: Colors.red))).toList(),
                                   ),
                                 ),
                               Padding(
                                   padding: const EdgeInsets.all(16.0),
                                   child: Wrap(
                                     spacing: 20,
                                     children: data.entries.map<Widget>((e) => Text("${e.key}: ${e.value}")).toList(),
                                   )
                               )
                             ],
                           ),
                         );
                      },
                    ),
            ),
            
            // BOTON IMPORTAR
            if (_registros.where((r) => r['status'] == 'valid').isNotEmpty) ...[
               const SizedBox(height: 16),
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton(
                   onPressed: _procesando ? null : _importar,
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                   child: Text("IMPORTAR ${_registros.where((r) => r['status'] == 'valid').length} REGISTROS"),
                 ),
               )
            ]
          ],
        ),
      ),
    );
  }
}
