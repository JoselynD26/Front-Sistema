
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final sedeId = 1;
  final fecha = "2026-01-02";
  final targetHorarioId = 35;
  
  final urlGet = Uri.parse("http://localhost:8000/horarios/cancelados/?sede_id=$sedeId&fecha=$fecha");
  
  print("--- PROBING JAN 2nd CLEAN ---");
  print("URL: $urlGet");
  bool found = false;
  try {
    final res = await http.get(urlGet);
    print("GET Status: ${res.statusCode}");
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      print("Found ${data.length} items.");
      for (var item in data) {
         print(" - ID: ${item['id']}, HorarioID: ${item['horario_id']}, Motivo: ${item['motivo']}");
         if (item['horario_id'] == targetHorarioId) found = true;
      }
    } else {
      print("Error GET: ${res.body}");
    }
  } catch (e) {
    print("Exception GET: $e");
  }

  if (!found) {
    print("\n--- NOT FOUND. ATTEMPTING MANUAL CREATE ---");
    final urlPost = Uri.parse("http://localhost:8000/horarios/cancelados/");
    final body = jsonEncode({
      "horario_id": targetHorarioId,
      "fecha": fecha,
      "motivo": "Manual Fix Script Jan 2",
      "estado": "cancelado",
      "sede_id": sedeId
    });
    
    try {
      final resPost = await http.post(urlPost, 
        headers: {"Content-Type": "application/json"},
        body: body
      );
      print("POST Status: ${resPost.statusCode}");
      print("POST Body: ${resPost.body}");
      
      // Re-verify
      if (resPost.statusCode == 200 || resPost.statusCode == 201) {
         print("Create success. Re-checking list...");
         final res2 = await http.get(urlGet);
         print("Re-check Status: ${res2.statusCode}");
         if (res2.statusCode == 200) {
            final List data2 = jsonDecode(res2.body);
             print("Found ${data2.length} items after fix.");
         }
      }
    } catch (e) {
      print("Exception POST: $e");
    }
  } else {
    print("✅ Target cancellation ALREADY EXISTS.");
  }
}
