import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final file = File('debug_output.txt');
  final sink = file.openWrite();
  
  void log(String msg) {
    sink.writeln(msg);
    print(msg); // Keep print just in case
  }

  final baseUrl = "http://localhost:8000";
  final sedeId = 1;
  final fecha = "2026-01-02"; // Friday
  
  log("--- STEP 1: FIND THE TARGET SCHEDULE ID ---");
  var targetHorarioId;
  
  try {
    final urlHorarios = Uri.parse("$baseUrl/horario-docente/sede/$sedeId");
    log("Fetching from: $urlHorarios");
    final res = await http.get(urlHorarios);
    
    if (res.statusCode == 200) {
      final List horarios = jsonDecode(res.body);
      log("Total schedules found: ${horarios.length}");
      
      for (var h in horarios) {
         final dia = h['dia'] ?? h['dia_id'];
         final hora = h['hora_inicio'];
         
         String docenteInfo = "Unknown";
         if (h['docente'] != null) {
            docenteInfo = "${h['docente']['nombres']} ${h['docente']['apellidos']}";
         } else {
            docenteInfo = "DocenteID: ${h['docente_id']}";
         }
         
         String materiaInfo = "Unknown";
         if (h['materia'] != null) {
            materiaInfo = h['materia']['nombre'];
         }

         log("ID=${h['id']} | Dia=$dia | Hora=$hora | Doc=${docenteInfo} | Mat=${materiaInfo}");
         
         if (docenteInfo.toUpperCase().contains("QUIGUANGO") || materiaInfo.toUpperCase().contains("PATRONAJE")) {
            log(" *** POSSIBLE MATCH ***");
            if (dia.toString().toLowerCase().contains("viernes") || dia == 5 || (dia.toString().contains("Fri"))) {
               targetHorarioId = h['id'];
               log(">>> MATCH CONFIRMED FOR FRIDAY <<<");
            }
         }
      }
    } else {
      log("Failed fetch: ${res.statusCode}");
    }
  } catch (e) {
    log("Error: $e");
  }
  
  if (targetHorarioId != null) {
      log("\n--- STEP 2: CHECK EXISTING CANCELLATIONS FOR ID $targetHorarioId ---");
      // Check cancellation logic here...
      final urlCancel = Uri.parse("$baseUrl/horarios/cancelados/?sede_id=$sedeId&fecha=$fecha");
      try {
        final res = await http.get(urlCancel);
        bool exists = false;
        if (res.statusCode == 200) {
            final List list = jsonDecode(res.body);
            log("Found ${list.length} cancellations.");
            for(var c in list) {
                if (c['horario_id'] == targetHorarioId) {
                    exists = true;
                    log("✅ EXISTS: ID=${c['id']}");
                }
            }
        }
        
        if (!exists) {
            log("Creating cancellation for ID $targetHorarioId...");
            final urlPost = Uri.parse("$baseUrl/horarios/cancelados/");
            final body = jsonEncode({
              "horario_id": targetHorarioId,
              "fecha": fecha,
              "motivo": "Auto-fix",
              "estado": "cancelado",
              "sede_id": sedeId
            });
            final resPost = await http.post(urlPost, headers: {"Content-Type": "application/json"}, body: body);
            log("POST Status: ${resPost.statusCode} Body: ${resPost.body}");
        }
      } catch(e) { log("Error cancel check: $e"); }
  } else {
    log("❌ Target ID not found.");
  }

  await sink.close();
}
